//file : system_picorv32.v
`define C_WR (2'b01)
`define C_RD (2'b10)

module system_picorv32 (input sys_clk,input sys_resetn,output reg [7:0] LEDR,input [7:0] SW,output [6:0] hex0,output [6:0] hex1,output [6:0] hex2,output [6:0] hex3, output [6:0] hex4,output [6:0] hex5);
	wire 		cpu_trap;
	wire 		cpu_rw_cycle;
	wire 		cpu_instr_fetch;
	reg 		sys_rw_is_done;
	wire [31:0] cpu_address;
	wire [31:0] cpu_write_data;
	wire [3:0] 	cpu_write_strobe;
	wire [31:0] cpu_read_data;
	reg   [31:0] io_read_data;

	wire 		sys_write_enable = (| cpu_write_strobe); // if one or more byte written
	wire 		sys_read_enable = cpu_rw_cycle & (! sys_write_enable);

	wire [31:0] ram_read_data; 

	//	individual read_enable and write_enable
	wire sys_RAM_read, sys_RAM_write; //RAM-8KB:0-0x1FFF(byte) = 0-7FF(32-bit-word)
	wire sys_LED_read, sys_LED_write;
	wire sys_7SEG_read, sys_7SEG_write;
	wire sys_SWITCH_read;
	// ************** TODO**************** 
	// Add here the declaration of your r/w enable signal for IO peripheral registers, like
	// wire sys_XXX_reg_read;	
	
	reg   [23:0] HexData;
	// ************** TODO**************** 
	// Add here your IO control registers declaration. like :
	// reg  [7:0] XXX_control_register; ("REG" if write access) or 
	// wire [7:0] XXX_status_register; ("WIRE" if read only);
	
	// ************** TODO**************** 
	// Replace '0' in 6+0 by the number of r/w enable signals you need to add
	reg [6+0:0] sys_rw_bus ; // grouping 7+0 individual read_enable and write_enable in a bus
	wire global_rw =  |(sys_rw_bus) ;  // if any individual r/w is enable 

	// select if data bus is read from RAM or IO		
	assign cpu_read_data =   (sys_RAM_read) ? ram_read_data :  io_read_data ;
	
	// Acknowkledge read/write request cpu one cycle after cpu_rw_cycle using 
	// sys_rw_is_done if cpu address is in ram or for any I/O registers
	always @(posedge sys_clk) sys_rw_is_done <= (global_rw && !sys_rw_is_done) ;

	// instance of RISC-V
	picorv32 picorvr32_inst (
		.clk         (sys_clk        ),
		.resetn      (sys_resetn     ),
		.trap        (cpu_trap       ),
		.mem_valid   (cpu_rw_cycle  ),
		.mem_instr   (cpu_instr_fetch  ),
		.mem_ready   (sys_rw_is_done  ),
		.mem_addr    (cpu_address   ),
		.mem_wdata   (cpu_write_data  ),
		.mem_wstrb   (cpu_write_strobe  ),
		.mem_rdata   (cpu_read_data )
	);

	// instance RAM (8KB)  
	ram1port8k	ram1port8k_inst (
		.address 	( cpu_address[12:2] ),   
		.byteena 	( cpu_write_strobe ),
		.data 		( cpu_write_data ),
		.clock 		( sys_clk ),
		.rden 		( sys_RAM_read ),
		.wren 		( sys_RAM_write ),
		.q 			( ram_read_data )
	);

	// degrouping individual read_enable and write_enable
	// ************** TODO**************** 
	// Insert your r/w enable signals in the following instruction, like 
	// assign {sys_XXX_read, sys_XXX_write, ..., sys_SWITCH_read, ...
	   assign {sys_SWITCH_read, sys_LED_write,sys_LED_read, 
		sys_7SEG_write,sys_7SEG_read,sys_RAM_write, sys_RAM_read} = sys_rw_bus;
	
	// r/w individual signal generation from address decoding 
	always @({sys_read_enable,sys_write_enable,cpu_address}) 
	 casex ({sys_read_enable,sys_write_enable,cpu_address}) 	
	  //ram read 0-1FFF (sys_RAM_read):
		 {`C_RD,32'b00000000_00000000_000xxxxx_xxxxxxxx}:sys_rw_bus <= 7'b0000001; 
	  //ram write 0-1FFF (sys_RAM_write) :
		 {`C_WR,32'b00000000_00000000_000xxxxx_xxxxxxxx}:sys_rw_bus <= 7'b0000010; 
		 {`C_RD,32'h0000_8010}  : sys_rw_bus <= 7'b0000100; //7Seg read @ 8010
		 {`C_WR,32'h0000_8010}  : sys_rw_bus <= 7'b0001000; //7seg write @ 8010
		 {`C_RD,32'h0000_8000}  : sys_rw_bus <= 7'b0010000; //led read @ 8000
		 {`C_WR,32'h0000_8000}  : sys_rw_bus <= 7'b0100000; //led write @ 8000
		 {`C_RD,32'h0000_8004}  : sys_rw_bus <= 7'b1000000; //switch read @ 8004
	// ************** TODO**************** 
	// Add here the write and read enable signal generation for your IO peripheral registers
	// and update all "7'b000..." consistency 
	  	default                 : sys_rw_bus <= 7'b0000000; 
	endcase
		
	always @(posedge sys_clk)	begin
		if (sys_LED_read)  io_read_data  <= { 24'd0 , LEDR }; 
		else if (sys_LED_write & cpu_write_strobe[0]) LEDR <= cpu_write_data[ 7: 0]; 
		else if (sys_SWITCH_read) io_read_data  <= { 24'd0 , SW }; 
		else if (sys_7SEG_read) io_read_data  <= { 8'd0 , HexData }; 
		else if (sys_7SEG_write)begin
			if (cpu_write_strobe[0]) HexData[ 7: 0] <= cpu_write_data[ 7: 0]; 
			if (cpu_write_strobe[1]) HexData[15: 8] <= cpu_write_data[15:8]; 
			if (cpu_write_strobe[2]) HexData[23:16] <= cpu_write_data[23:16]; 
		end
	// ************** TODO**************** 
	// Add here READ and WRITE instructions to your IO peripheral registers, like this:
	// else if (sys_XXX_read) io_read_data  <= { XXX }; (for READING register) or
	// else if (sys_XXX_write)begin if (cpu_write_strobe[0]) XXX_reg [ 7: 0] <= cpu_write_data[ 7: 0]; ...(for WRITING)
	
	end
	
	BCDto7seg BCDto7seg_0 (.din(HexData[3:0]),.abcdef(hex0[6:0]));
	BCDto7seg BCDto7seg_1 (.din(HexData[7:4]),.abcdef(hex1[6:0]));
	BCDto7seg BCDto7seg_2 (.din(HexData[11:8]),.abcdef(hex2[6:0]));
	BCDto7seg BCDto7seg_3 (.din(HexData[15:12]),.abcdef(hex3[6:0]));
	BCDto7seg BCDto7seg_4 (.din(HexData[19:16]),.abcdef(hex4[6:0]));
	BCDto7seg BCDto7seg_5 (.din(HexData[23:20]),.abcdef(hex5[6:0]));
		
	// ************** TODO**************** 
	// Add here your IO peripheral instances

endmodule
