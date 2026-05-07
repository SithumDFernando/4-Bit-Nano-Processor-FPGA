## ============================================================================
## Xilinx Design Constraints (XDC) for the 4-Bit NanoProcessor
## Target Board : Digilent Basys 3  (Artix-7 XC7A35TCPG236-1)
## Top Module   : NANOPROCESSOR
## ============================================================================

## ----------------------------------------------------------------------------
## Clock  –  100 MHz on-board oscillator
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports Clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports Clk]

## ----------------------------------------------------------------------------
## Reset  –  Centre push-button (active-high reset)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports Clr]

## ----------------------------------------------------------------------------
## Register R7 Output  –  LEDs [3:0]
##   LED0 (LD0) = R[0],  LED1 (LD1) = R[1],
##   LED2 (LD2) = R[2],  LED3 (LD3) = R[3]
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {R[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {R[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {R[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {R[3]}]

## ----------------------------------------------------------------------------
## Status Flags  –  LEDs
##   LED14 (LD14) = Overflow
##   LED15 (LD15) = Zero
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports Overflow]
set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports Zero]

## ----------------------------------------------------------------------------
## 7-Segment Display  –  Active-low cathode segments
##   Accent: LUT_7_SEG outputs data(6 downto 0) = { g, f, e, d, c, b, a }
##   Basys 3 cathode pins (active-low):
##     CA = a,  CB = b,  CC = c,  CD = d,  CE = e,  CF = f,  CG = g
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W7  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[0]}]
set_property -dict { PACKAGE_PIN W6  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[1]}]
set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[2]}]
set_property -dict { PACKAGE_PIN V8  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[3]}]
set_property -dict { PACKAGE_PIN U5  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[4]}]
set_property -dict { PACKAGE_PIN V5  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[5]}]
set_property -dict { PACKAGE_PIN U7  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[6]}]

## ----------------------------------------------------------------------------
## 7-Segment Display  –  Anode control (active-low)
##   Enable only the rightmost digit (AN0), disable the rest.
##   AN0 = '0' (on),  AN1..AN3 = '1' (off)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U2  IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4  IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4  IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4  IOSTANDARD LVCMOS33 } [get_ports {an[3]}]

## ============================================================================
## Configuration
## ============================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
