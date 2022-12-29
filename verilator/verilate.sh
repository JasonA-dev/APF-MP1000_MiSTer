verilator \
-cc -exe --public --trace --savable \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
--converge-limit 6000 \
-Wno-fatal \
--top-module top sim.v \
../rtl/MP1000.v \
../rtl/dpram.sv \
../rtl/rom.v \
../rtl/mc6847/mc6847.v \
../rtl/mc6847/rom_char.v \
../rtl/mc6800/mc6801_core.v \
../rtl/mc6821/pia6821.v
