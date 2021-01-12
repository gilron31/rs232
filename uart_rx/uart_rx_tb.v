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
	parameter P_BAUD = 9600;
	localparam LP_SYS_CLK_hz = 10**(9)/2;
	localparam LP_CLK_2_BAUD_ratio = LP_SYS_CLK_hz / P_BAUD;
	localparam LP_SLOW_CLOCK_PRESCALER_BITS = 16; //ceil(log2(LP_CLK_2_BAUD_ratio))
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
	
	// Common tasks
	task wait_N_cycles;
	input [31 : 0] N;
	begin
		 #(N*P_TICS_PER_CYCLE);
	end endtask
	
	task transmit_bit;
	input a;
	begin
		 serial_in = a;
		 wait_N_cycles(LP_CLK_2_BAUD_ratio);
	end endtask
	
	task transmit_valid_byte;
	input [7 : 0] a;
	integer i;
	begin
		 transmit_bit(1'b0);
		 for (i = 0; i < 8 ; i = i + 1) begin
			  transmit_bit(a[i]);
		 end
		 transmit_bit(1'b1);
	end endtask
	
	initial begin
		// Initialize Inputs
		CLK = 0;
		serial_in = 0;
		reset = 0;
		display_next = 0;
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
		
		transmit_valid_byte(8'b00000000);
		transmit_valid_byte(8'b00000001);
		transmit_valid_byte(8'b00000010);
		transmit_valid_byte(8'b00000011);
		transmit_valid_byte(8'b00000100);
		transmit_valid_byte(8'b00000101);
		transmit_valid_byte(8'b00000110);
		transmit_valid_byte(8'b00000111);
		transmit_valid_byte(8'b00001000);
		transmit_valid_byte(8'b00001001);
		transmit_valid_byte(8'b00001010);
		transmit_valid_byte(8'b00001011);
		transmit_valid_byte(8'b00001100);
		transmit_valid_byte(8'b00001101);
		transmit_valid_byte(8'b00001110);
		transmit_valid_byte(8'b00001111);

		wait_N_cycles(1000000);
		
		display_next = 1;
		wait_N_cycles(1000000);

		// Add stimulus here
		
		$finish();
	end
      

	
	
endmodule

