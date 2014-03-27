set_property IOSTANDARD LVCMOS25 [get_ports -regexp -nocase {otg_vbus_oc\[0\]}]
set_property PACKAGE_PIN L16 [get_ports -regexp -nocase {otg_vbus_oc\[0\]}]

set_property PACKAGE_PIN G17 [get_ports -regexp -nocase {otg_reset}]
set_property IOSTANDARD LVCMOS25 [get_ports -regexp -nocase {otg_reset}]
