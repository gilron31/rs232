`timescale 100ns / 1ns

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
	parameter P_DATA_WIDTH = 8;
	parameter P_FIFO_DEPTH = 16;
	parameter P_log_DW = 3;
	localparam LP_SYS_CLK_hz = 10**(7)/2; //indicative name, 0.5 * 1/100ns
	localparam LP_CLK_2_BAUD_ratio = LP_SYS_CLK_hz / P_BAUD;
	localparam LP_SLOW_CLOCK_PRESCALER_BITS = 16; //ceil(log2(LP_CLK_2_BAUD_ratio))
	localparam LP_N_SINGLE_BYTE_TEST = 50;       
	localparam LP_N_FIFO_TEST = 50;
	// Inputs
	reg CLK;
	reg serial_in;
	reg reset;
	reg display_next;
	reg [P_DATA_WIDTH * P_FIFO_DEPTH - 1 : 0] demo_FIFO;
	reg [P_DATA_WIDTH - 1 : 0] byte_to_send = 0;
	reg [P_DATA_WIDTH - 1 : 0] expected_output = 0;
	reg [P_log_DW - 1: 0] demo_FIFO_counter = 0; 
	
	// Outputs
	wire error;
	wire fifo_full;
	wire fifo_empty;
	wire [3:0] data_out_msd;
	wire [3:0] data_out_lsd;

	// Instantiate the Unit Under Test (UUT)
	uart_rx #(
		.P_UART_WIDTH(P_DATA_WIDTH)
		) uut(
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
	
/////////////////////////////	
////Simulated Components ////
/////////////////////////////

	always begin
		#(P_TICS_PER_CYCLE/2);
		CLK = ~CLK;
	end
	
	
//////////////////////	
//// Common tasks ////
//////////////////////	

	task wait_N_cycles; //Holds the simulation for N clock cycles.
	input [31 : 0] N;
	begin
		 #(N*P_TICS_PER_CYCLE);
	end endtask
	
	task wait_human_like_button_press; // This task holds the simulation for about 0.1s which 
												  // simulates the time that a human button press takes.
	begin
		 wait_N_cycles(LP_SYS_CLK_hz / 10 + $random() % (LP_SYS_CLK_hz / 50));  
	end endtask
	
	task transmit_bit; //Transmits a single bit serially.
	input a;
	begin
		 serial_in = a;
		 wait_N_cycles(LP_CLK_2_BAUD_ratio);
	end endtask
	
	task transmit_valid_byte; //Transmits valid byte serially including the proper start/stop bits.
	input [7 : 0] a;
	integer i;
	begin
		 transmit_bit(1'b0);
		 for (i = 0; i < 8 ; i = i + 1) begin
			  transmit_bit(a[i]);
		 end
		 transmit_bit(1'b1);
	end endtask
	
	task transmit_byte_with_invalid_stop_bit; //Transmits a byte with a low stop bit. should move the system to error.
	input [7 : 0] a;
	integer i;
	begin
		 transmit_bit(1'b0);
		 for (i = 0; i < 8 ; i = i + 1) begin
			  transmit_bit(a[i]);
		 end
		 transmit_bit(1'b0);
	end endtask
	
	task reset_and_idle; //Resets the component and holds the serial_in pin high for as 
								//long as it takes for the system to get into IDLE mode where it is 
								//ready to read inputs.
	begin
		 reset = 1;
		 wait_N_cycles(1);
		 serial_in = 1;
		 reset = 0;
		 wait_N_cycles(10 * LP_CLK_2_BAUD_ratio);
	end endtask
	
//////////////////////		
//// Tests Tasks /////
//////////////////////
	
	task test_one_transmission; //This task simulates the writing of 1 byte of the serial input 
										 //to the FIFO followed by the reading of this byte.
	begin
		 byte_to_send <= $random();
		 display_next = 0;
		 reset_and_idle();
		 transmit_valid_byte(byte_to_send);
		 display_next = 1;
		 wait_N_cycles(1);
		 if ({data_out_msd, data_out_lsd} != byte_to_send) begin
			  $display("Test failed on one byte transmission!");
			  $display("expected %h", byte_to_send);
			  $display("got      %h", {data_out_msd, data_out_lsd});
			  $finish();
		 end
		 display_next = 0;
	end endtask
	
	task test_invalid_stop_bit_and_recover; //This task simulates a sending of a bit with a low stop bit
														 //and asserts that the system indeed gets into error state
														 //and also that it is able to go back to normal operation after 
														 //pressing the reset input.
	begin
		 byte_to_send <= $random();
		 reset_and_idle();
		 transmit_byte_with_invalid_stop_bit(byte_to_send);
		 if (error != 1) begin
			  $display("Test failed on invalid stop bit transmission!");
			  $display("expected error = 1");
			  $finish();
		 end
		 wait_human_like_button_press();
		 reset = 1;
		 wait_human_like_button_press();
		 serial_in = 1;
		 reset = 0;
		 wait_human_like_button_press();
		 if (error == 1) begin
			  $display("Test failed on error recovery!");
			  $display("expected error = 0");
			  $finish();
		 end
	end endtask

	task test_fill_FIFO; //This task simulates a writing of test_depth bytes into the FIFO and 
								//it's following reading from the FIFO.
	input [3 : 0] test_depth;
	integer i;
	begin
		 reset_and_idle();
		 for (i = 0; i < test_depth; i = i + 1) begin
				byte_to_send = $random();
				transmit_valid_byte(byte_to_send);
				demo_FIFO[i*P_DATA_WIDTH +: P_DATA_WIDTH] = byte_to_send;
		 end
		 
		 
		 
		 for (i = 0; i < test_depth; i = i + 1) begin
				 expected_output = demo_FIFO[i*P_DATA_WIDTH +: P_DATA_WIDTH];
				 display_next = 1;
				 wait_N_cycles(1);
				 if ({data_out_msd, data_out_lsd} != expected_output) begin
					  $display("Test failed on %d byte transmission!", test_depth);
					  $display("on byte number %d", i);
					  $display("expected %h", expected_output);
					  $display("got      %h", {data_out_msd, data_out_lsd});
					  $finish();
				 end
				 display_next = 0;
		  end	
	 end endtask

	
////////////////////////////////////
//// Starting Testing sequence /////
////////////////////////////////////
	
	integer i, j;
	initial begin
		// Initialize Inputs
		CLK = 0;
		serial_in = 0;
		reset = 0;
		display_next = 0;
      wait_N_cycles(10);
		
		// TEST #1
		for (i = 0; i < LP_N_SINGLE_BYTE_TEST; i = i + 1) begin 
			test_one_transmission();
		end

		// TEST #2
		test_invalid_stop_bit_and_recover();
		
		// TEST #3
		for (j = 0; j < LP_N_FIFO_TEST; j = j + 1) begin
			for (i = 1; i < P_FIFO_DEPTH; i = i + 1) begin
				 test_fill_FIFO(i);
			end
		end
		
		
		$display("Tests passed sucessfully!");
		$finish();
	end
      

	
	
endmodule

