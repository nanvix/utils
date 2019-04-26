# MIT License
#
# Copyright(c) 2011-2019 The Maintainers of Nanvix
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Memory Size
MEMSIZE=128M

# Number of Cores
NCORES=5

#
# Runs a binary in the QEMU RISC-V 32-bit target.
#
function run
{
	local image=$1
	local binary=$2
	local target=$3
	local variant=$4
	local mode=$5
		
	if [ $mode == "--debug" ];
	then
		qemu-system-riscv32 -s -S \
			-machine virt         \
			-kernel $binary       \
			-serial stdio         \
			-display none         \
			-m $MEMSIZE           \
			-mem-prealloc         \
			-smp $NCORES
	else
		qemu-system-riscv32 -s \
			-machine virt      \
			-kernel $binary    \
			-serial stdio      \
			-display none      \
			-m $MEMSIZE        \
			-mem-prealloc      \
			-smp $NCORES
	fi
}
