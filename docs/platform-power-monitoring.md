# Platform power monitoring

This adds CPU and GPU power-consumption metrics to the platform, plus a way to attribute GPU power draw to the specific Nomad allocation that is using the GPU. Three optional Nomad **system jobs** are deployed by the `nomad` role:

| Job                | Signal                              | Runs on                                                                     | Exporter port |
| ------------------ | ----------------------------------- | -------------------------------------------------------------------------- | ------------- |
| `scaphandre`       | CPU/host power (watts)              | Nomad clients with `meta.scaphandre = "true"`                              | `9401`        |
| `dcgm-exporter`    | GPU power/energy counters           | Nomad GPU clients with `meta.dcgm_exporter = "true"` (and `meta.tags = "gpu"`)   | `9400`        |
| `gpu-alloc-mapper` | GPU UUID → Nomad `alloc_id` mapping | Nomad GPU clients with `meta.gpu_alloc_mapper = "true"` (and `meta.tags = "gpu"`) | `9402`        |

All three jobs also set `datacenters = ["{{ consul_dc_name }}"]`, so the scheduler keeps them inside this site's datacenter and never places allocations on other federated sites. The `meta.*` gates above are emitted by `nomad_client.j2` only when the matching feature flag is `true`, so disabling a flag and re-running the playbook drains the job (no eligible nodes left) instead of leaving it running.

Each job can optionally run a per-job [Alloy](https://grafana.com/docs/alloy/latest/) sidecar task that scrapes its own exporter and `remote_write` straight to Mimir, independent of the host-wide Alloy **log** shipping already deployed by this repo (`alloy_enabled`, see [`roles/alloy`](../roles/alloy)).

> ⚠ **Scaphandre needs hypervisor-side setup that this repo does not automate.** See [CPU power: Scaphandre](#1-cpu-power-scaphandre) below before enabling `scaphandre_enabled`.

## Feature flags

All disabled by default in [`group_vars/all.yml`](../group_vars/all.yml):

```yaml
# -- DCGM Exporter (GPU power monitoring)
dcgm_exporter_version: "4.5.3-4.8.2-distroless"
dcgm_exporter_enabled: false

# -- Scaphandre Agent (CPU power monitoring)
scaphandre_enabled: false

# -- GPU allocation mapper
gpu_alloc_mapper_enabled: false
gpu_alloc_mapper_script_path: /opt/nomad-scripts/nomad_gpu_alloc_mapper.py

# -- Alloy metrics sidecar (push mode: scrape local exporter, remote_write to Mimir)
alloy_metrics_enabled: false
alloy_mimir_url: "https://mimir.k8s.cloud.ai4eosc.eu/api/v1/push"
alloy_mimir_user: "{{ consul_dc_name }}"
alloy_mimir_password: ""
alloy_scrape_interval: "30s"
```

Each of `dcgm_exporter_enabled`, `scaphandre_enabled` and `gpu_alloc_mapper_enabled` independently controls (a) whether the guest-side host requirements are prepared during a normal `playbook-nomad.yaml` run, and (b) whether the corresponding Nomad job gets rendered and `nomad job run` on the `nomad_master` host (or `consul_new_master` on a site-join run). `alloy_metrics_enabled` independently controls whether _all three_ job templates additionally render an Alloy sidecar task: it has nothing to do with `alloy_enabled` (log shipping), see [Alloy metrics sidecar](#4-alloy-metrics-sidecar-optional) for a caveat on that.

## 1. CPU power: Scaphandre

[Scaphandre](https://hubblo-org.github.io/scaphandre-documentation/) reads Intel RAPL energy counters. A VM has no direct access to the host's RAPL registers, so Scaphandre supports a `--vm` mode where a **hypervisor-side** Scaphandre process computes a per-VM power breakdown and exposes it to the guest as a fake `powercap`-style directory tree (`energy_uj` files) shared in read-only over **virtiofs**. The guest-side Scaphandre (`--vm` mode) then reads that directory exactly as if it were bare-metal RAPL.

### Hypervisor / OpenStack side (manual, not covered by this repo)

This is host infrastructure that must be set up by whoever administers the KVM hypervisors (OpenStack compute nodes) **before** `scaphandre_enabled: true` will produce any real data in a VM:

1. Run `scaphandre qemu` on the hypervisor (as a long-running exporter). For each VM domain it writes that VM's power breakdown into a tmpfs directory:
    ```
    mount -t tmpfs tmpfs_<DOMAIN_NAME> /var/lib/libvirt/scaphandre/<DOMAIN_NAME> -o size=5m
    ```
2. The VM's libvirt domain XML must share that directory into the guest via a read-only virtiofs filesystem device tagged `scaphandre` (the tag Nomad VMs expect; see `scaphandre_virtiofs_tag` below):
    ```xml
    <filesystem type='mount' accessmode='passthrough'>
        <driver type='virtiofs'/>
        <source dir='/var/lib/libvirt/scaphandre/<DOMAIN_NAME>'/>
        <target dir='scaphandre'/>
        <readonly/>
    </filesystem>
    ```
    (If virtiofs fails to come up, the VM also needs `<memoryBacking><source type='memfd'/><access mode='shared'/></memoryBacking>`.)
3. In an OpenStack/Nova deployment this virtiofs device has to be injected into the instance's libvirt XML by whatever mechanism the site uses to customize Nova-generated domains (Nova does not do this out of the box): this is a per-site OpenStack integration step, out of scope for this Ansible repo.

Source: [Scaphandre: Propagate power consumption metrics from hypervisor to VMs (Qemu/KVM)](https://hubblo-org.github.io/scaphandre-documentation/how-to_guides/propagate-metrics-hypervisor-to-vm_qemu-kvm.html).

### Guest / VM side (this repo: [`roles/scaphandre`](../roles/scaphandre))

When `scaphandre_enabled: true`, `roles/nomad/tasks/main.yml` runs the `scaphandre` role on every Nomad host in the play, which:

1. Mounts the virtiofs share read-only, persistently, at `scaphandre_mount_point` (default `/var/scaphandre`, matches Scaphandre's own default `--vm` lookup path) with tag `scaphandre_virtiofs_tag` (default `scaphandre`, must match the hypervisor-side `<target dir='...'>` above).
2. Warns (but does not fail) if the mount ends up empty: that means the hypervisor-side export isn't wired up for that VM.
3. Downloads and installs the Scaphandre `.deb` (`scaphandre_version`, default `1.0.2`, suffix `scaphandre_deb_suffix`, default `deb12`).

`nomad_client.j2` then tags the client with `meta.scaphandre = "true"` when `scaphandre_enabled` is set, and the `scaphandre` Nomad job (`nomad-scaphandre-job.j2`) is a `type = "system"` job scoped to `datacenters = ["{{ consul_dc_name }}"]` and constrained to `${meta.scaphandre} == "true"`, running Scaphandre via `raw_exec`:

```
scaphandre --vm prometheus --containers --port 9401
```

> ⓘ Empirically, Scaphandre needs **~512 MiB** memory in this raw_exec task (real RSS ~180 MiB, but its many threads' kernel stacks push the cgroup charge higher); `memory = 64` gets OOM-killed. The Nomad cluster does not have memory oversubscription enabled, so `memory_max` is ignored: always size the hard `memory` reservation directly.

> ⚠ The host-prep step (mount + package install) is **not** currently restricted to `nomad_clients`: it runs on every host in the play when `scaphandre_enabled: true`, including `nomad_servers`. Servers have no `client` stanza (`nomad_server.j2` never sets `meta.scaphandre`), so the Nomad job constraint will never schedule there. The extra mount/install on servers is harmless but wasted work.

## 2. GPU power: dcgm-exporter

`roles/nomad/tasks/dcgm_exporter.yml` runs on GPU clients (`nomad_gpu_clients`/`nomad_new_gpu_clients`) when `dcgm_exporter_enabled: true`: pulls `nvcr.io/nvidia/k8s/dcgm-exporter:{{ dcgm_exporter_version }}` and copies [`dcgm-power-counters.csv`](../roles/nomad/files/dcgm-power-counters.csv) to `/etc/dcgm-exporter/power-counters.csv`. That CSV **replaces** the exporter's default counter set with just the two power-related fields:

```
DCGM_FI_DEV_POWER_USAGE,              gauge,   Power draw in watts
DCGM_FI_DEV_TOTAL_ENERGY_CONSUMPTION, counter, Total energy consumption in mJ since last driver reload
```

`nomad_client.j2` tags GPU clients with `meta.dcgm_exporter = "true"` when `dcgm_exporter_enabled` is set. The `dcgm-exporter` Nomad job (`nomad-dcgm-exporter-job.j2`) is a `type = "system"` job scoped to `datacenters = ["{{ consul_dc_name }}"]` and constrained to `${meta.tags} == "gpu"` **and** `${meta.dcgm_exporter} == "true"`, running the image via Docker with `runtime = "nvidia"` and `network_mode = "host"`, bind-mounting the counters CSV in.

> ⓘ Neither of these two counters needs the `SYS_ADMIN` capability (only DCP profiling fields like `DCGM_FI_PROF_*` do), and the Nomad `docker` plugin here has `allow_privileged = true` but no `allow_caps`, so `cap_add = ["SYS_ADMIN"]` would be rejected anyway. Needs **~1024 MiB** memory (steady ~416 MiB; `memory = 256` gets OOM-killed). The counters file must exist as a file on the host _before_ the container starts, or Docker auto-creates the bind-mount target as a directory and the mount fails.

## 3. GPU power attribution: gpu-alloc-mapper

DCGM's metrics are per-GPU (labelled by `UUID`), not per-workload: there's no built-in way to know which Nomad job/allocation is drawing that power. [`nomad_gpu_alloc_mapper.py`](../roles/nomad/files/nomad_gpu_alloc_mapper.py) closes that gap: for every running Docker container it reads the `com.hashicorp.nomad.alloc_id` label (set by Nomad on every container it creates) and the `NVIDIA_VISIBLE_DEVICES` env var (set by the Nvidia device plugin when a task requests a GPU), then serves a Prometheus `/metrics` endpoint on port `9402`:

```
nomad_gpu_allocation_info{alloc_id="<id>", UUID="<gpu-uuid>", container_id="<id>"} 1
```

dcgm-exporter's own container is excluded (it runs with `runtime = nvidia` directly, not a Nomad GPU device request, so the nvidia runtime defaults its `NVIDIA_VISIBLE_DEVICES` to `all`: that's not a real workload to attribute power to).

Join it with DCGM's power metric in PromQL:

```promql
DCGM_FI_DEV_POWER_USAGE * on(UUID) group_left(alloc_id) nomad_gpu_allocation_info
```

`roles/nomad/tasks/gpu_alloc_mapper.yml` stages the script (mode `0755`) at `gpu_alloc_mapper_script_path` (default `/opt/nomad-scripts/nomad_gpu_alloc_mapper.py`) on GPU clients when `gpu_alloc_mapper_enabled: true`. `nomad_client.j2` tags GPU clients with `meta.gpu_alloc_mapper = "true"` when `gpu_alloc_mapper_enabled` is set. The Nomad job (`nomad-gpu-alloc-mapper-job.j2`) runs it via `raw_exec` (`python3 <script>`), `system` type, scoped to `datacenters = ["{{ consul_dc_name }}"]` and constrained to `${meta.tags} == "gpu"` **and** `${meta.gpu_alloc_mapper} == "true"`.

## 4. Alloy metrics sidecar (optional)

When `alloy_metrics_enabled: true`, all three job templates additionally `include` [`_alloy_metrics_sidecar.j2`](../roles/nomad/templates/_alloy_metrics_sidecar.j2), which adds an `alloy-metrics` Docker task to the same task group. That task scrapes the sibling task's exporter on `localhost` and `remote_write`s to Mimir (`alloy_mimir_url`, basic-auth `alloy_mimir_user`/`alloy_mimir_password`). `alloy_mimir_user` defaults to `consul_dc_name` because Mimir derives the tenant (`X-Scope-OrgID`) server-side from the authenticated basic-auth user: it must match this site's tenant name in Mimir.

Each job uses a distinct static port for the sidecar's health check to avoid collisions when several of these jobs land on the same node (a GPU node can run both `dcgm-exporter` and `gpu-alloc-mapper`, and any node can also run `scaphandre`):

| Job                | Exporter port | Alloy health port |
| ------------------ | ------------- | ----------------- |
| `dcgm-exporter`    | 9400          | 12345             |
| `scaphandre`       | 9401          | 12346             |
| `gpu-alloc-mapper` | 9402          | 12347             |

`scaphandre`'s sidecar additionally relabels/keeps only `scaph_host_power_microwatts` and `scaph_process_power_consumption_microwatts` before forwarding (Scaphandre's default metric set is large; the other two jobs forward everything unfiltered).

> ⓘ The sidecar task sets `kill_timeout = "30s"` (with `kill_signal = "SIGTERM"`). The sidecar shares the task group with its exporter, so a `nomad job stop` SIGTERMs both at once; with Nomad's default 5s `kill_timeout` Alloy is SIGKILLed before it can emit end-of-run staleness markers for the scraped series and flush its WAL to Mimir, and the series then keep returning their last scraped value for the full PromQL lookback window (5 min, so roughly 9-10 extra flat points at a 30s scrape interval) instead of ending cleanly. 30s is the cluster's `max_kill_timeout`. This only covers ordered stops: an alloc crash, OOM kill or node drain still skips the staleness markers, and scraping these exporters from a node-level Alloy via Consul service discovery (so the collector outlives the job) is the only way to close that gap.

> ⓘ The sidecar template references `{{ alloy_image }}`. `roles/alloy/defaults/main.yml` also defines it, but only becomes available on a host when `alloy_enabled: true` triggers that role's `include_role` (a _different_ flag, for host-wide log shipping), so `alloy_image` is set explicitly and unconditionally in `group_vars/all.yml` as well, keeping the metrics sidecar independent of whether log shipping is enabled on that host.

## Known limitations

- Scaphandre host-prep (virtiofs mount + package install) isn't scoped to `nomad_clients`, so it also runs (harmlessly) on `nomad_servers` (see [§1](#1-cpu-power-scaphandre)).
