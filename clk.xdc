#create_clock -name clk -period 10 [get_ports clk]
set_property PACKAGE_PIN AR32 [get_ports clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_p]

set_property PACKAGE_PIN A8 [get_ports rstn]
set_property IOSTANDARD LVCMOS33 [get_ports rstn]

set_property PACKAGE_PIN D8 [get_ports valid]
set_property IOSTANDARD LVCMOS33 [get_ports valid]
set_property DRIVE 12 [get_ports valid]


set_property PACKAGE_PIN B9 [get_ports switch]
set_property IOSTANDARD LVCMOS33 [get_ports switch]
