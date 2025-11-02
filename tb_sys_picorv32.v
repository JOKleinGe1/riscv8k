//tb_sys_picorv32.v

`timescale 1 ns / 100 ps
`define FCLOCK 50000000

module tb_sys_picorv32;
	reg clk = 1;
	reg resetn = 0;
	wire  [7:0] LEDR;
    reg   [7:0] SW = 8'h00; 

    wire [6:0]hex0; 
    wire [6:0]hex1; 
    wire [6:0]hex2; 
    wire [6:0]hex3; 
    wire [6:0]hex4; 
    wire [6:0]hex5; 
    
	system_picorv32 dutsys (
		. sys_clk  (clk        ),
		.sys_resetn      (resetn     ), 
		. LEDR (LEDR) ,
		.SW (SW),
		.hex0(hex0),
		.hex1(hex1),
		.hex2(hex2),
		.hex3(hex3),
		.hex4(hex4),
		.hex5(hex5)
	);
	
	always #10 clk = ~clk; // 50MHz system clock

	initial begin
		$dumpfile("tb_sys_picorv32.vcd");
		$dumpvars(0, tb_sys_picorv32 );
		resetn <= 1'b1;
		SW <=8'h0A;
		repeat (2) @(posedge clk);
		resetn <= 1'b0;
		repeat (2) @(posedge clk);
		resetn <= 1'b1;
		repeat (100) @(posedge clk);	
		SW <= 8'h55;
		repeat (150) @(posedge clk);	
	$finish;
	end
	
	always @(posedge clk) begin
		if (dutsys.cpu_rw_cycle && dutsys.sys_rw_is_done) begin
			if (dutsys.cpu_instr_fetch)
				$display("ifetch 0x%08x: 0x%08x", dutsys.cpu_address, dutsys.cpu_read_data);
			else if (dutsys.cpu_write_strobe)
				$display("write  0x%08x: 0x%08x (wstrb=%b)",dutsys.cpu_address,dutsys.cpu_write_data, dutsys.cpu_write_strobe);
			else
				$display("read   0x%08x: 0x%08x", dutsys.cpu_address, dutsys.cpu_read_data);
		end
	end
endmodule
