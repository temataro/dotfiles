# =============================================================================
# exporter.py — Passively collect model and two-node DGX serving metrics.
# The local HTTP endpoint is loopback-only; remote access uses existing SSH.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
import json
import os
import re
import shlex
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import URLError
from urllib.request import urlopen

HEAD_SSH = os.environ["HEAD_SSH"]
WORKER_SSH = os.environ["WORKER_SSH"]
API_URL = f"http://{os.environ['API_HOST']}:{os.environ.get('API_PORT', '8000')}/metrics"
FABRIC_IF = os.environ["FABRIC_IF"]
RDMA_HCA = os.environ["RDMA_HCA"]
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "15"))

for host in (HEAD_SSH, WORKER_SSH):
    assert re.fullmatch(r"[A-Za-z0-9_.-]+@[A-Za-z0-9_.:-]+", host), f"invalid SSH target: {host}"
assert 5 <= POLL_SECONDS <= 120

PROBE = r"""python3 - <<'PY'
import json
import os
import pathlib
import subprocess

def output(args):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=4, check=True)
        return result.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""

mem = {}
for line in pathlib.Path('/proc/meminfo').read_text().splitlines():
    key, value = line.split(':', 1)
    mem[key] = int(value.split()[0]) * 1024
gpu = []
for line in output(['nvidia-smi', '--query-gpu=index,utilization.gpu,temperature.gpu,power.draw', '--format=csv,noheader,nounits']).splitlines():
    fields = [part.strip() for part in line.split(',')]
    if len(fields) == 4:
        gpu.append(fields)
container = output(['docker', 'inspect', '--format', '{{.State.Running}} {{.RestartCount}}', 'glm53-server']).split()
net = pathlib.Path('/sys/class/net') / os.environ['FABRIC_IF']
def read(path):
    try:
        return pathlib.Path(path).read_text().strip()
    except OSError:
        return ''
rdma = pathlib.Path('/sys/class/infiniband') / os.environ['RDMA_HCA'] / 'ports/1/counters'
def counter(name):
    try:
        return int((rdma / name).read_text().strip()) * 4
    except (OSError, ValueError):
        return -1
data = {
    'memory_total': mem.get('MemTotal', 0),
    'memory_available': mem.get('MemAvailable', 0),
    'swap_total': mem.get('SwapTotal', 0),
    'swap_free': mem.get('SwapFree', 0),
    'gpu': gpu,
    'container_running': container[0] == 'true' if len(container) == 2 else False,
    'container_restarts': int(container[1]) if len(container) == 2 else -1,
    'fabric_state': read(net / 'operstate'),
    'fabric_speed_mbps': int(read(net / 'speed') or 0),
    'fabric_tx_bytes': int(read(net / 'statistics/tx_bytes') or 0),
    'fabric_rx_bytes': int(read(net / 'statistics/rx_bytes') or 0),
    'rdma_tx_bytes': counter('port_xmit_data'),
    'rdma_rx_bytes': counter('port_rcv_data'),
}
print(json.dumps(data))
PY"""

cache = {"text": ""}
lock = threading.Lock()


def ssh_probe(node):
    options = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=4", "-o", "ServerAliveInterval=5"]
    if node == "head":
        command = ["ssh", *options, "-i", "/run/ssh/id_ed25519", "-o", "IdentitiesOnly=yes",
                   "-o", "UserKnownHostsFile=/run/ssh/known_hosts", HEAD_SSH, "bash", "-s"]
    else:
        command = ["ssh", *options, "-i", "/run/ssh/id_ed25519", "-o", "IdentitiesOnly=yes",
                   "-o", "UserKnownHostsFile=/run/ssh/known_hosts", HEAD_SSH, "ssh", *options,
                   WORKER_SSH, "bash", "-s"]
    probe = f"export FABRIC_IF={shlex.quote(FABRIC_IF)} RDMA_HCA={shlex.quote(RDMA_HCA)}\n" + PROBE
    result = subprocess.run(command, input=probe, text=True, capture_output=True, timeout=15)
    result.check_returncode()
    return json.loads(result.stdout)


def metric(name, value, labels):
    if not labels:
        return f"{name} {value}"
    label_text = ",".join(
        f'{key}="{str(item).replace(chr(92), chr(92) * 2).replace(chr(34), chr(92) + chr(34))}"'
        for key, item in labels.items()
    )
    return f"{name}{{{label_text}}} {value}"


def collect():
    lines = ["# DGX cluster passive metrics"]
    for node in ("head", "worker"):
        try:
            data = ssh_probe(node)
            labels = {"node": node}
            lines.extend([
                metric("dgx_collector_up", 1, labels),
                metric("dgx_memory_bytes", data["memory_total"], labels | {"kind": "total"}),
                metric("dgx_memory_bytes", data["memory_available"], labels | {"kind": "available"}),
                metric("dgx_memory_bytes", data["memory_total"] - data["memory_available"], labels | {"kind": "used"}),
                metric("dgx_memory_bytes", data["swap_total"], labels | {"kind": "swap_total"}),
                metric("dgx_memory_bytes", data["swap_total"] - data["swap_free"], labels | {"kind": "swap_used"}),
                metric("dgx_container_running", int(data["container_running"]), labels | {"container": "glm53-server"}),
                metric("dgx_container_restarts", data["container_restarts"], labels | {"container": "glm53-server"}),
                metric("dgx_fabric_link_up", int(data["fabric_state"] == "up"), labels),
                metric("dgx_fabric_link_speed_bits_per_second", data["fabric_speed_mbps"] * 1000000, labels),
                metric("dgx_fabric_interface_bytes_total", data["fabric_tx_bytes"], labels | {"direction": "tx"}),
                metric("dgx_fabric_interface_bytes_total", data["fabric_rx_bytes"], labels | {"direction": "rx"}),
            ])
            for direction in ("tx", "rx"):
                value = data[f"rdma_{direction}_bytes"]
                if value >= 0:
                    lines.append(metric("dgx_roce_port_bytes_total", value, labels | {"direction": direction}))
            for gpu in data["gpu"]:
                gpu_labels = labels | {"gpu": gpu[0]}
                for field, name in ((1, "utilization_percent"), (2, "temperature_celsius"), (3, "power_watts")):
                    if gpu[field].lower() != "n/a":
                        lines.append(metric(f"dgx_gpu_{name}", float(gpu[field]), gpu_labels))
        except (OSError, subprocess.SubprocessError, ValueError, KeyError, json.JSONDecodeError) as error:
            lines.extend([metric("dgx_collector_up", 0, {"node": node}), f"# {node} collection failed: {type(error).__name__}"])
    try:
        with urlopen(API_URL, timeout=5) as response:
            lines.append(response.read().decode().rstrip())
        lines.append(metric("dgx_model_metrics_up", 1, {}))
    except (OSError, URLError, TimeoutError):
        lines.append(metric("dgx_model_metrics_up", 0, {}))
    lines.append(metric("dgx_collector_last_update_seconds", time.time(), {}))
    return "\n".join(lines) + "\n"


def refresh():
    while True:
        try:
            current = collect()
            with lock:
                cache["text"] = current
        except Exception as error:
            with lock:
                cache["text"] = metric("dgx_collector_fatal", 1, {"error": type(error).__name__}) + "\n"
        time.sleep(POLL_SECONDS)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok\n")
            return
        if self.path != "/metrics":
            self.send_error(404)
            return
        with lock:
            body = cache["text"].encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        return


if __name__ == "__main__":
    threading.Thread(target=refresh, daemon=True).start()
    ThreadingHTTPServer(("127.0.0.1", 9108), Handler).serve_forever()
