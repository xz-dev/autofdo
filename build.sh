#!/usr/bin/env sh

set -e

vmkernel=$1

# $2 = CPU vendor (intel or amd)
# if intel: perf record --pfm-events BR_INST_RETIRED.NEAR_TAKEN:k -a -N -b -c 500009 -o kernel.data -- time makepkg -sfci --skipinteg
# if AMD: perf record --pfm-events RETIRED_TAKEN_BRANCH_INSTRUCTIONS:k -a -N -b -c 500009 -o kernel.data -- time makepkg -sfc --skipinteg

#test_command="su build -c 'makepkg -sfci --skipinteg' && benchmark-launcher-cli benchmark --blender-version 4.3.0 --device-type CPU monster junkshop classroom && phoronix-test-suite benchmark cpu"
#test_command="benchmark-launcher-cli benchmark --blender-version 4.3.0 --device-type CPU monster junkshop classroom && phoronix-test-suite benchmark cpu"
test_command="phoronix-test-suite batch-run cpu"

if [ "$2" = "intel" ]; then
    perf record --pfm-events BR_INST_RETIRED.NEAR_TAKEN:k -a -N -b -c 500009 -o /output/kernel.data -- time sh -c "$test_command"
elif [ "$2" = "amd" ]; then
    perf record --pfm-events RETIRED_TAKEN_BRANCH_INSTRUCTIONS:k -a -N -b -c 500009 -o /output/kernel.data -- time sh -c "$test_command"
else
    echo "Invalid CPU vendor"
fi

# $3 is autofdo or propeller
if [ "$3" = "autofdo" ]; then
    llvm-profgen --kernel --binary="$vmkernel" --perfdata=/output/kernel.data -o /output/kernel-compilation.afdo
elif [ "$3" = "propeller" ]; then
    create_llvm_prof --binary="$vmkernel" --profile=/output/kernel.data --format=propeller --propeller_output_module_name --out=/output/propeller_cc_profile.txt --propeller_symorder=/output/propeller_ld_profile.txt
fi
