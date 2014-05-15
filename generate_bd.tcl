# Create block design
create_bd_design "dyplo_example"

# Create interface ports
set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

# Create ports
set OTG_VBUS_OC [ create_bd_port -dir I -from 0 -to 0 OTG_VBUS_OC ]
set otg_reset [ create_bd_port -dir O -from 0 -to 0 -type rst otg_reset ]

# Create instance: dyplo_axi_0, and set properties
set dyplo_ip_name [get_ipdefs -filter "NAME =~ *dyplo_axi*"]
if { $dyplo_ip_name == "" } { 
	puts "DYPLO_ERROR: No Dyplo IP found."
	exit -1
} else {
	set dyplo_axi_0 [ create_bd_cell -type ip -vlnv ${dyplo_ip_name} dyplo_axi_0 ]
	# Source dyplo_conf.tcl for dyplo IP configuration
	source ./dyplo_conf.tcl
}

# Create instance: proc_sys_reset, and set properties
set proc_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset ]

# Create instance: processing_system7_1, and set properties
set ip_defs [get_ipdefs -filter "NAME =~ *processing_system7*"]
foreach ip_def $ip_defs {
	if { [string first "processing_system7:" $ip_def] != -1 } {
		set processing_system7_1 [ create_bd_cell -type ip -vlnv $ip_def processing_system7_1 ]
		set_property -dict [ list CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666667} CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} CONFIG.PCW_EN_CLK1_PORT {0} CONFIG.PCW_EN_CLK2_PORT {0} CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000} CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150.000000} CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200.000000} CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} CONFIG.PCW_IMPORT_BOARD_PRESET {./PS_conf.xml} CONFIG.PCW_IRQ_F2P_INTR {1} CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} CONFIG.PCW_SD0_GRP_CD_ENABLE {1} CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} CONFIG.PCW_SD0_GRP_WP_ENABLE {1} CONFIG.PCW_SD0_GRP_WP_IO {MIO 46} CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {0} CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {0} CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.41} CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.411} CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.341} CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.358} CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {533.333313} CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J128M16 HA-15E} CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {1} CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} CONFIG.PCW_USE_DMA0 {0} CONFIG.PCW_USE_DMA1 {0} CONFIG.PCW_USE_DMA2 {0} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_USE_S_AXI_HP0 {0}  ] $processing_system7_1
		break
	}
}

# Create instance: processing_system7_1_axi_periph, and set properties
set processing_system7_1_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 processing_system7_1_axi_periph ]
set_property -dict [ list CONFIG.NUM_MI {1}  ] $processing_system7_1_axi_periph

# Create instance: util_vector_logic_0, and set properties
set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:1.0 util_vector_logic_0 ]
set_property -dict [ list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}  ] $util_vector_logic_0

# Create instance: xlconcat_0, and set properties
set xlconcat_0 [ create_bd_cell -type ip -vlnv [get_ipdefs -filter "NAME =~ *xlconcat*"] xlconcat_0 ]
set_property -dict [ list CONFIG.NUM_PORTS {16}  ] $xlconcat_0

# Create instance: xlconstant_0, and set properties
set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.0 xlconstant_0 ]
set_property -dict [ list CONFIG.CONST_VAL {0}  ] $xlconstant_0

# Create instance: xlconstant_2, and set properties
set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.0 xlconstant_2 ]

# Create interface connections
connect_bd_intf_net -intf_net processing_system7_1_axi_periph_m00_axi [get_bd_intf_pins dyplo_axi_0/S_AXI] [get_bd_intf_pins processing_system7_1_axi_periph/M00_AXI]
connect_bd_intf_net -intf_net processing_system7_1_ddr [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_1/DDR]
connect_bd_intf_net -intf_net processing_system7_1_fixed_io [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_1/FIXED_IO]
connect_bd_intf_net -intf_net processing_system7_1_m_axi_gp0 [get_bd_intf_pins processing_system7_1/M_AXI_GP0] [get_bd_intf_pins processing_system7_1_axi_periph/S00_AXI]

# Create port connections
connect_bd_net -net dyplo_axi_0_dyplo_irq [get_bd_pins dyplo_axi_0/dyplo_irq] [get_bd_pins xlconcat_0/In13]
connect_bd_net -net otg_vbus_oc_1 [get_bd_ports OTG_VBUS_OC] [get_bd_pins util_vector_logic_0/Op1]
connect_bd_net -net proc_sys_reset_interconnect_aresetn [get_bd_pins proc_sys_reset/interconnect_aresetn] [get_bd_pins processing_system7_1_axi_periph/ARESETN]
connect_bd_net -net proc_sys_reset_peripheral_aresetn [get_bd_pins dyplo_axi_0/S_AXI_ARESETN] [get_bd_pins proc_sys_reset/peripheral_aresetn] [get_bd_pins processing_system7_1_axi_periph/M00_ARESETN] [get_bd_pins processing_system7_1_axi_periph/S00_ARESETN]
connect_bd_net -net processing_system7_1_fclk_clk0 [get_bd_pins dyplo_axi_0/S_AXI_ACLK] [get_bd_pins proc_sys_reset/slowest_sync_clk] [get_bd_pins processing_system7_1/FCLK_CLK0] [get_bd_pins processing_system7_1/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_1_axi_periph/ACLK] [get_bd_pins processing_system7_1_axi_periph/M00_ACLK] [get_bd_pins processing_system7_1_axi_periph/S00_ACLK]
connect_bd_net -net processing_system7_1_fclk_reset0_n [get_bd_pins proc_sys_reset/ext_reset_in] [get_bd_pins processing_system7_1/FCLK_RESET0_N]
connect_bd_net -net util_vector_logic_0_res [get_bd_pins processing_system7_1/USB0_VBUS_PWRFAULT] [get_bd_pins util_vector_logic_0/Res]
connect_bd_net -net xlconcat_0_dout [get_bd_pins processing_system7_1/IRQ_F2P] [get_bd_pins xlconcat_0/dout]
connect_bd_net -net xlconstant_1_const [get_bd_ports otg_reset] [get_bd_pins xlconstant_2/const]
connect_bd_net -net xlconstant_2_const [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconcat_0/In2] [get_bd_pins xlconcat_0/In3] [get_bd_pins xlconcat_0/In4] [get_bd_pins xlconcat_0/In5] [get_bd_pins xlconcat_0/In6] [get_bd_pins xlconcat_0/In7] [get_bd_pins xlconcat_0/In8] [get_bd_pins xlconcat_0/In9] [get_bd_pins xlconcat_0/In10] [get_bd_pins xlconcat_0/In11] [get_bd_pins xlconcat_0/In12] [get_bd_pins xlconcat_0/In14] [get_bd_pins xlconcat_0/In15] [get_bd_pins xlconstant_0/const]

# Create address segments
create_bd_addr_seg -range 0x200000 -offset 0x64400000 [get_bd_addr_spaces processing_system7_1/Data] [get_bd_addr_segs dyplo_axi_0/S_AXI/reg0] SEG_dyplo_axi_0_reg0

save_bd_design

# Generate HDL wrapper
make_wrapper -files [get_files $project_dir/dyplo_example.srcs/sources_1/bd/dyplo_example/dyplo_example.bd] -top
add_files -norecurse $project_dir/dyplo_example.srcs/sources_1/bd/dyplo_example/hdl/dyplo_example_wrapper.vhd

