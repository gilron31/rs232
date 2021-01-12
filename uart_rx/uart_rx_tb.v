`timescale 1ns / 100ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:12:48 01/12/2021
// Design Name:   uart_rx
// Module Name:   /home/gilro/Documents/bis/rs232/uart_rx/uart_rx_tb.v
// Project Name:  uart_rx
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: uart_rx
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module uart_rx_tb;
	parameter P_TICS_PER_CYCLE = 2;

	// Inputs
	reg CLK;
	reg serial_in;
	reg reset;
	reg display_next;

	// Outputs
	wire error;
	wire fifo_full;
	wire fifo_empty;
	wire [3:0] data_out_msd;
	wire [3:0] data_out_lsd;

	// Instantiate the Unit Under Test (UUT)
	uart_rx uut (
		.CLK(CLK), 
		.serial_in(serial_in), 
		.reset(reset), 
		.display_next(display_next), 
		.error(error), 
		.fifo_full(fifo_full), 
		.fifo_empty(fifo_empty), 
		.data_out_msd(data_out_msd), 
		.data_out_lsd(data_out_lsd)
	);

	always begin
		#(P_TICS_PER_CYCLE/2);
		CLK = ~CLK;
	end

	initial begin
		// Initialize Inputs
		CLK = 0;
		serial_in = 0;
		reset = 0;
		display_next = 0;

		// Wait 100 ns for global reset to finish
      wait_N_cycles(10);
		reset = 1;
      wait_N_cycles(1);
		reset = 0;
		serial_in = 1;
      wait_N_cycles(100000);
		serial_in = 0;
		wait_N_cycles(1);
		serial_in = 1;
		wait_N_cycles(1000000);
		// Add stimulus here
		$finish();
	end
      
	task wait_N_cycles;
	input [31 : 0] N;
	begin
		 #(N*P_TICS_PER_CYCLE);
	end endtask
endmodule

