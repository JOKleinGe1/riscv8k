# riscv8k

Minimal system with RISC-V picorv32 : asm startup + c example + verilog system + testbench + Makefile

Includes intel-FPGA (quartus17) project and files for synthesis on DE10lite FPGA Board.

Status : 

simulation : ok 

synthesis : ok

Design for education purpose. 
From JOKlein, Dept GEii-1,IUT Cachan, Univ Paris-Saclay. 

# INSTALL INSTRUCTIONS:
1. Install RISCV dev tools (riscv32-linux-gnu-gcc)
   
   sudo dnf install gcc-c++-riscv32-linux-gnu
   
2. Install intel fpga quartus LITE edition
   
   from https://www.intel.com/content/www/us/en/software-kit/825278/intel-quartus-prime-lite-edition-design-software-version-23-1-1-for-windows.html
   
# GCC + VERILOG COMPILATION AND SIMULATION 
   
1. Compile the project, in a terminal:
 
   \> make clean
   
   \> make

2. See read / write cycles with

   \> more trace.txt

3. View waveforms in gtkwave:

   \> gtkwave tb_sys_picorv32.vcd &
# FPGA PROGRAMMING
   
1. Run intel-fpga quartus:
    
   \> ~/intelFPGA_lite/23.1std/quartus/bin/quartus &
   
2. in quartus:
  
     File > open_project "quartus_mini_sys_riscv.qpf"
     
     Processing > Start_Compilation
   
3. Connect the DE10Lite board to PC USB 
    
4. Launch Programmer and Start programming the device

5. Reset the RISCV CPU (KEY0 on DE10Lite board)
   
   Well done !

