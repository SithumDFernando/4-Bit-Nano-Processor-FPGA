## ============================================================
## BASYS3 (xc7a35tcpg236-1) Constraints for NANOPROCESSOR
## ============================================================

## ── Clock ──────────────────────────────────────────────────
set_property PACKAGE_PIN W5 [get_ports Clk]
set_property IOSTANDARD LVCMOS33 [get_ports Clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports Clk]

## ── Reset (BTNC — centre button, active high) ──────────────
set_property PACKAGE_PIN U18 [get_ports Clr]
set_property IOSTANDARD LVCMOS33 [get_ports Clr]

## ── R[3:0] → LD3..LD0 (result register R7) ────────────────
set_property PACKAGE_PIN V19 [get_ports {R[3]}]
set_property PACKAGE_PIN U19 [get_ports {R[2]}]
set_property PACKAGE_PIN E19 [get_ports {R[1]}]
set_property PACKAGE_PIN U16 [get_ports {R[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {R[*]}]

## ── Overflow → LD4, Zero → LD5 ────────────────────────────
set_property PACKAGE_PIN W18 [get_ports Overflow]
set_property IOSTANDARD LVCMOS33 [get_ports Overflow]

set_property PACKAGE_PIN U15 [get_ports Zero]
set_property IOSTANDARD LVCMOS33 [get_ports Zero]

## ── 7-Segment display segments (active low) ────────────────
## data(6:0) = CG, CF, CE, CD, CC, CB, CA  (MSB to LSB)
set_property PACKAGE_PIN U7  [get_ports {Seven_Seg[6]}]
set_property PACKAGE_PIN V5  [get_ports {Seven_Seg[5]}]
set_property PACKAGE_PIN U5  [get_ports {Seven_Seg[4]}]
set_property PACKAGE_PIN V8  [get_ports {Seven_Seg[3]}]
set_property PACKAGE_PIN U8  [get_ports {Seven_Seg[2]}]
set_property PACKAGE_PIN W6  [get_ports {Seven_Seg[1]}]
set_property PACKAGE_PIN W7  [get_ports {Seven_Seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Seven_Seg[*]}]

## ── 7-Segment digit anodes ────────────────────────────────
## Note: Extended nanoprocessor does not use anode control
## (displays only on rightmost digit via hardware wiring)
