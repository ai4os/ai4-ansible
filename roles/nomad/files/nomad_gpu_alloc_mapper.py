#!/usr/bin/env python3
"""Maps GPU UUIDs to the Nomad allocation currently using them.

For each running Docker container, reads:
  - the "com.hashicorp.nomad.alloc_id" label (set automatically by Nomad on
    every container it creates) to identify which allocation owns it;
  - the NVIDIA_VISIBLE_DEVICES environment variable (set by the nvidia
    device plugin when the task requests a GPU) to identify which GPU(s)
    it was assigned.

Containers missing either piece are skipped. Exposes the result as a
Prometheus "info" metric (join key: UUID, matching DCGM's own label name)
so it can be cross-referenced with DCGM_FI_DEV_* metrics in PromQL:

  DCGM_FI_DEV_POWER_USAGE * on(UUID) group_left(alloc_id) nomad_gpu_allocation_info
"""
import json
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = 9402
DOCKER_TIMEOUT = 5
ALLOC_ID_LABEL = "com.hashicorp.nomad.alloc_id"
IGNORED_DEVICE_VALUES = {"", "void", "none"}
# dcgm-exporter itself runs with runtime=nvidia (not a Nomad GPU device
# request), which makes the nvidia runtime default NVIDIA_VISIBLE_DEVICES to
# "all" so it can see every GPU on the host to monitor them. That's not a
# real workload to attribute GPU usage to, so it's excluded by image.
IGNORED_IMAGE_PREFIXES = ("nvcr.io/nvidia/k8s/dcgm-exporter",)


def get_container_ids():
    try:
        out = subprocess.run(
            ["docker", "ps", "-q"],
            capture_output=True, text=True, timeout=DOCKER_TIMEOUT, check=True,
        ).stdout
    except Exception:
        return []
    return [line.strip() for line in out.splitlines() if line.strip()]


def inspect_containers(container_ids):
    if not container_ids:
        return []
    try:
        out = subprocess.run(
            ["docker", "inspect", *container_ids],
            capture_output=True, text=True, timeout=DOCKER_TIMEOUT, check=True,
        ).stdout
    except Exception:
        return []
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return []


def get_gpu_allocations():
    results = []
    for container in inspect_containers(get_container_ids()):
        config = container.get("Config", {})
        labels = config.get("Labels") or {}
        alloc_id = labels.get(ALLOC_ID_LABEL)
        if not alloc_id:
            continue

        image = config.get("Image") or ""
        if any(image.startswith(prefix) for prefix in IGNORED_IMAGE_PREFIXES):
            continue

        env_list = config.get("Env") or []
        visible_devices = None
        for entry in env_list:
            if entry.startswith("NVIDIA_VISIBLE_DEVICES="):
                visible_devices = entry.split("=", 1)[1]
                break
        if not visible_devices or visible_devices.lower() in IGNORED_DEVICE_VALUES:
            continue

        container_id = container.get("Id", "")
        for uuid in visible_devices.split(","):
            uuid = uuid.strip()
            if uuid:
                results.append((alloc_id, uuid, container_id))
    return results


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return

        lines = [
            "# HELP nomad_gpu_allocation_info Maps a GPU UUID to the Nomad allocation currently using it.",
            "# TYPE nomad_gpu_allocation_info gauge",
        ]
        for alloc_id, uuid, container_id in get_gpu_allocations():
            lines.append(
                f'nomad_gpu_allocation_info{{alloc_id="{alloc_id}",UUID="{uuid}",container_id="{container_id}"}} 1'
            )

        body = ("\n".join(lines) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
