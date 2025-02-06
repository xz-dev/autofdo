# Kernel Profile Optimization Tool

A containerized tool for automatically generating AutoFDO and Propeller optimization profiles for Linux kernels. Utilizes Phoronix test suites and `perf` to collect performance data for kernel tuning.

## Features

- Auto-generate AutoFDO optimization profiles
- Auto-generate Propeller optimization profiles
- Containerized execution ensures environment consistency
- Persistent output storage
- MIT Licensed

## Prerequisites

- Podman
- Linux kernel debug symbols (vmlinux)
- Recommended 16GB+ RAM

## Workload

Base on phoronix-test-suite (Maybe you have better idea, please tell we)

CPU suite:
- pts/rodinia
- pts/namd
- pts/stockfish
- pts/x264
- pts/x265
- pts/kvazaar
- pts/compress-7zip
- pts/blender
- pts/asmfish
- pts/build-linux-kernel
- pts/build-gcc
- pts/radiance
- pts/openssl
- pts/ctx-clock
- pts/sysbench
- pts/povray

## Quick Start

### Build Container Image
```bash
podman build -t autofdo .
```

### Generate AutoFDO Profile
```bash
podman run --rm \
  -v $PWD/output:/output \
  -v /usr/lib/modules/$(uname -r)/build/vmlinux:/vmlinux \
  -it --privileged \
  autofdo /vmlinux amd autofdo
```

### Generate Propeller Profile
```bash
podman run --rm \
  -v $PWD/output:/output \
  -v /usr/lib/modules/$(uname -r)/build/vmlinux:/vmlinux \
  -it --privileged \
  autofdo /vmlinux amd propeller
```

## Quick Steps

1. Build an init kernel
2. Reboot to the kernel
3. Generate AutoFDO Profile
4. Build an kernel with AutoFDO Profile
5. Reboot to the new kernel
6. Generate Propeller Profile
7. Build an kernel with AutoFDO Profile and Propeller Profile
8. Reboot and enjoy!

## Output Files

Profiles will be saved to `./output` directory:
- AutoFDO: `kernel.afdo`
- Propeller: `propeller/propeller_cc_profile.txt`, `propeller/propeller_ld_profile.txt`

## Parameters

| Parameter         | Description                                      |
|-------------------|--------------------------------------------------|
| `/vmlinux`        | Mount path for kernel debug symbols             |
| `amd`             | Target architecture (supports amd/intel) |
| `autofdo/propeller` | Optimization type selector                      |

## Notes

1. `--privileged` flag required for performance profiling
2. Ensure mounted vmlinux matches current kernel version
3. High CPU/memory load expected - recommend dedicated hardware
4. Output directory requires write permissions

## Contribution

We welcome community improvements! Please:
- Open issues to discuss test suite enhancements
- Submit PRs for better benchmark coverage validation
- Suggest additional profiling optimizations
