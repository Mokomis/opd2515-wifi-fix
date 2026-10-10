#!/usr/bin/env python3
"""Send UDP to a host at a fixed rate for a fixed time.

usage: udpload.py <tablet-ip> <mbps> <seconds> [processes]

Run it on a wired computer on the same network while tests/sample.sh runs on the tablet.
The packets go to the discard port; nothing has to listen there.
"""
import multiprocessing as mp
import socket
import sys
import time


def run(ip, mbps, secs):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 4 << 20)
    payload = b"\0" * 1400
    per_s = mbps * 1e6 / 8 / 1400
    burst = max(1, int(per_s / 1000))  # 1 ms slices
    t0 = time.perf_counter()
    sent = 0
    end = t0 + secs
    while True:
        now = time.perf_counter()
        if now >= end:
            break
        due = int((now - t0) * per_s)
        n = max(min(due - sent, burst * 20), 0)
        for _ in range(n):
            try:
                s.sendto(payload, (ip, 9))
            except OSError:
                pass
        sent += n
        if n == 0:
            time.sleep(0.0005)
    print(f"sent {sent * 1400 * 8 / 1e6 / secs:.0f} Mb/s")


if __name__ == "__main__":
    ip, mbps, secs = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
    n = int(sys.argv[4]) if len(sys.argv) > 4 else 4
    ps = [mp.Process(target=run, args=(ip, mbps / n, secs)) for _ in range(n)]
    [p.start() for p in ps]
    [p.join() for p in ps]
