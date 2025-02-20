#!/usr/bin/env python3

import asyncio
import os
import sys
from pathlib import Path

# Test suites to be executed with optional environment variables
TESTS = [
    ("pts/workstation", {"FORCE_TIMES_TO_RUN": "3"}),  # No environment variables
    ("pts/stress-ng", {"FORCE_TIMES_TO_RUN": "1"}),  # No environment variables
    #("pts/pgbench", {}),  # No environment variables
    #("pts/kernel", {"FORCE_TIMES_TO_RUN": "1"}),
    # ("pts/server-cpu-tests", {"VAR1": "value1", "VAR2": "value2"}),
]

output_perfdata = Path("output/data")
if not output_perfdata.exists():
    output_perfdata.mkdir(parents=True)

# Parsing arguments
if len(sys.argv) < 4:
    print("Usage: script.py <vmkernel> <cpu_vendor> <perf_way>")
    sys.exit(1)

vmkernel = Path(sys.argv[1])
if not vmkernel.exists():
    print("Invalid kernel path")
    sys.exit(1)

cpu_vendor = sys.argv[2]
if cpu_vendor == "intel":
    perf_event = "BR_INST_RETIRED.NEAR_TAKEN:k"
elif cpu_vendor == "amd":
    perf_event = "RETIRED_TAKEN_BRANCH_INSTRUCTIONS:k"
else:
    print("Invalid CPU vendor")
    sys.exit(1)

perf_way = sys.argv[3]
if perf_way not in ["autofdo", "propeller"]:
    print("Choose either autofdo or propeller")
    sys.exit(1)


def get_perfdata_name(test):
    """Generate a perf data file name based on the test name."""
    test_name = test.replace("/", "_")
    return output_perfdata / f"{test_name}.data"


async def run_command(command, env=None, catch_output=False):
    """Run a shell command asynchronously and handle errors."""
    print(f"Running command: {command}")
    if not catch_output:
        stdout = None
        stderr = None
    else:
        stdout = asyncio.subprocess.PIPE
        stderr = asyncio.subprocess.PIPE

    # Prepare environment variables
    final_env = os.environ.copy()
    if env:
        final_env.update(env)

    process = await asyncio.create_subprocess_shell(
        command, stdout=stdout, stderr=stderr, env=final_env
    )

    stdout, stderr = await process.communicate()
    if process.returncode != 0:
        print(
            f"""Command failed: {command}
Return code: {process.returncode}"""
        )
        if catch_output:
            print(
                f"""stdout:
{stdout.decode()}
stderr:
{stderr.decode()}"""
            )
        sys.exit(1)
    else:
        print(f"Command succeeded: {command}")
    if not catch_output:
        return ""
    return stdout.decode()


async def perf(test, env):
    """Run a perf command for a test asynchronously."""
    output_file = get_perfdata_name(test)
    command = f'perf record --pfm-events "{perf_event}" -a -N -b -c 500009 -o "{output_file}" -- time phoronix-test-suite batch-run "{test}"'
    await run_command(command, env)
    return output_file


async def autofdo(perf_data_file):
    """Generate AutoFDO profile for a test asynchronously."""
    output_file = f"{perf_data_file}.afdo"
    command = f'llvm-profgen --kernel --binary="{vmkernel}" --perfdata="{perf_data_file}" -o "{output_file}"'
    await run_command(command, catch_output=True)
    return output_file


async def propeller(tests):
    """Generate Propeller profile for multiple tests."""
    perf_list_file = Path("/tmp/perf_list.txt")
    if perf_list_file.exists():
        perf_list_file.unlink()

    # Write all perfdata files to the list
    with open(perf_list_file, "w", encoding="UTF-8") as f:
        for test in tests:
            test_path, _ = test
            perfdata_file = get_perfdata_name(test_path)
            f.write(f"{perfdata_file}\n")

    output_propeller = Path("output/propeller")
    if not output_propeller.exists():
        output_propeller.mkdir(parents=True)
    propeller_profile_prefix = f"{output_propeller}/propeller"

    command = (
        f'create_llvm_prof --binary="{vmkernel}" --profile="@{perf_list_file}"'
        f" --format=propeller --propeller_output_module_name"
        f" --out={propeller_profile_prefix}_cc_profile.txt"
        f" --propeller_symorder={propeller_profile_prefix}_ld_profile.txt"
    )
    await run_command(command)


async def main():
    # Get CPU core count for limiting concurrency
    count_lock = asyncio.Lock()
    total = 0
    finished = 0

    tests = TESTS
    total = len(tests)
    for test, env in tests:
        print(f"Running test: {test}")
        await perf(test, env)
        finished += 1
        print(f"Test finished: {test}")
        print(f"Tests finished: {finished}/{total}")

    if perf_way == "autofdo":

        async def sem_autofdo(test):
            test_path, env = test
            result = await autofdo(get_perfdata_name(test_path))
            async with count_lock:
                nonlocal finished
                finished += 1
                print(f"AutoFDO profiles generated: {finished}/{total}")
            return result

        autofdo_tasks = [sem_autofdo(test) for test in tests]
        total = len(autofdo_tasks)
        finished = 0
        perf_files = await asyncio.gather(*autofdo_tasks)

        # Merge AutoFDO profiles
        perf_files_str = " ".join(perf_files)
        command = f"llvm-profdata merge --sample -o output/kernel.afdo {perf_files_str}"
        await run_command(command)

    elif perf_way == "propeller":
        await propeller(tests)


if __name__ == "__main__":
    asyncio.run(main())
