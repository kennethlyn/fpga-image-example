#!/bin/sh

if [ "$1" == "" ]; then
	echo "Define run level, 0 = all, 3 = only partials"
	exit
fi

if [ "$DYPLO_DIR" == "" ]; then
	echo "Environment variable 'DYPLO_DIR' not set";
	exit
fi

if [ "$FPGA_FAMILY" == "" ]; then
	echo "Environment variable 'FPGA_FAMILY' not set"
	echo "Valid values: xc7z015, xc7z030"
	exit
else
	case "$FPGA_FAMILY" in
		xc7z015)
			export PART=${FPGA_FAMILY}clg485-1
			;;
		xc7z030)
			export PART=${FPGA_FAMILY}sbg485-1
			;;
		*)
			echo "Environment variable 'FPGA_FAMILY': $FPGA_FAMILY is not valid"
			echo "Valid values: xc7z015, xc7z030"
			exit
			;;
	esac
fi

if [ $1 -le 0 ]; then
	# First call dyplo_example.tcl to generate Vivado project and the block design for the ZedBoard
	vivado -mode tcl -notrace -source ./dyplo_example.tcl -tclargs ./ ${PART} ${DYPLO_DIR}/IP/${DYPLO_LICENSE_TYPE}
fi

if [ $1 -le 1 ]; then
	# Call synthesize_hdl_node.tcl for all HDL_node implementations
	vivado -mode tcl -notrace -source ${DYPLO_DIR}/dyplo_tcl/synthesize_hdl_node.tcl -tclargs "./hdl_nodes/adder/adder.xpr" "adder" ${PART} &
	vivado -mode tcl -notrace -source ${DYPLO_DIR}/dyplo_tcl/synthesize_hdl_node.tcl -tclargs "./hdl_nodes/adder_2_to_1/adder_2_to_1.xpr" "adder_2_to_1" ${PART} &
wait
	vivado -mode tcl -notrace -source ${DYPLO_DIR}/dyplo_tcl/synthesize_hdl_node.tcl -tclargs "./hdl_nodes/subtractor/subtractor.xpr" "subtractor" ${PART}
fi

if [ $1 -le 2 ]; then
	# Call impl_static_design.tcl to implement design and write a checkpoint of the static logic
	vivado -mode tcl -notrace -source ${DYPLO_DIR}/dyplo_tcl/impl_static_design.tcl -tclargs "./dyplo_example.xpr" "?" "./hdl_nodes/adder/hdl_node_adder_synth.dcp?./hdl_nodes/adder_2_to_1/hdl_node_adder_2_to_1_synth.dcp" "?" "./${FPGA_FAMILY}/pblock_definition.tcl"
fi

if [ $1 -le 3 ]; then
	# Call impl_dynamic_logic.tcl for all HDL_node implementations
	vivado -mode tcl -notrace -source ${DYPLO_DIR}/dyplo_tcl/impl_dynamic_logic.tcl -tclargs "./checkpoints/top_impl_static.dcp" "adder" "./hdl_nodes/adder/hdl_node_adder_synth.dcp" "1" "." &
	vivado -mode tcl -notrace -source ${DYPLO_DIR}/dyplo_tcl/impl_dynamic_logic.tcl -tclargs "./checkpoints/top_impl_static.dcp" "adder_2_to_1" "./hdl_nodes/adder_2_to_1/hdl_node_adder_2_to_1_synth.dcp" "2" "." &
wait
	vivado -mode tcl -notrace -source ${DYPLO_DIR}/dyplo_tcl/impl_dynamic_logic.tcl -tclargs "./checkpoints/top_impl_static.dcp" "subtractor" "./hdl_nodes/subtractor/hdl_node_subtractor_synth.dcp" "1" "."
fi
