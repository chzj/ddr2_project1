if {[file exists work]} {
    file delete -force work 
}
vlib work
vmap work work
vlog -novopt \
../code/zero_compare.v \
../zero_sim/tb_top.v 

vsim -novopt -t 1ns   work.tb_top -l tb_top.log
#-L XilinxCoreLib_ver -L unisims_ver
add wave -noupdate -divider -height 25 {tb_top}
add wave *

run 1ms
quit