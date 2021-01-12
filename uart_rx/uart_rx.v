`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:16:21 01/12/2021 
// Design Name: 
// Module Name:    uart_rx 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_rx #(
	 parameter P_UART_WIDTH = 8,
	 parameter P_BAUD = 9600,
	 parameter P_CYCLES_TO_RESET = 10
	 )(
	 input CLK,
    input serial_in,
    input reset,
    input display_next,
    output error,
    output fifo_full,
    output fifo_empty,
    output [P_UART_WIDTH / 2 - 1:0] data_out_msd,
    output [P_UART_WIDTH / 2 - 1:0] data_out_lsd
    );
	 localparam S_ERROR = 2'b00;
	 localparam S_INIT = 2'b01;
	 localparam S_IDLE = 2'b10;
	 localparam S_READ = 2'b11;
	 localparam LP_log_N_STATES = 2;
	 localparam LP_LOG_CYCLES_TO_RESET = 4;
	 localparam LP_SYS_CLK_hz = 10**(9)/2;
	 localparam LP_CLK_2_BAUD_ratio = LP_SYS_CLK_hz / P_BAUD;
	 localparam LP_SLOW_CLOCK_PRESCALER_BITS = 16; //ceil(log2(LP_CLK_2_BAUD_ratio))

//// Wires and registers
	 wire write_enable;
	 wire int_reset;
	 wire init_counter_ready;
	 wire slow_clock_pulse;
	 reg [P_UART_WIDTH - 1 : 0] fifo_data_in;
	 reg reg_error;
	 reg [LP_log_N_STATES - 1 : 0] reg_state;
	 reg [LP_LOG_CYCLES_TO_RESET - 1 : 0] init_counter;
	 reg [LP_SLOW_CLOCK_PRESCALER_BITS - 1 : 0] slow_clock_counter;
//// Assignments
	 assign init_counter_ready = init_counter == P_CYCLES_TO_RESET;
	 assign error = reg_error;
	 assign slow_clock_pulse = slow_clock_counter == LP_CLK_2_BAUD_ratio;
//// FIFO instanciation	 
	 fifo_8x16 your_instance_name (
	  .clk(CLK), // input clk
	  .rst(int_reset), // input rst
	  .din(fifo_data_in), // input [7 : 0] din
	  .wr_en(write_enable), // input wr_en
	  .rd_en(display_next), // input rd_en
	  .dout({data_out_msd, data_out_lsd}), // output [7 : 0] dout
	  .full(fifo_full), // output full
	  .empty(fifo_empty) // output empty
	);
	 
//// FSM tasks
	task T_ERROR;
	begin
		// Flow ctrl
		reg_state <= reset ? S_INIT : S_ERROR;
		// Outputs
		reg_error <= 1'b1;
		// Actions
		init_counter <= 0;
		slow_clock_counter <= 0;

	end
	endtask
	
	task T_INIT;
	begin
		// Flow ctrl
		if (reset) begin
			 reg_state <= reset;
		end
		else begin
			 case ({init_counter_ready, serial_in})
				  2'b01 ,
				  2'b00 ,
				  2'b10 : reg_state <= S_INIT;
				  2'b11 : reg_state <= S_IDLE;
			 endcase
		end
		// Outputs
		reg_error <= 1'b0;
		// Actions
		if (reset) begin
			 init_counter <= 0;
			 slow_clock_counter <= 0;
		end
		else begin
			 if ({init_counter_ready, serial_in} == 2'b01) begin
				  init_counter <= init_counter + slow_clock_pulse;
			 end
			 else begin
				  init_counter <= 0;
				  slow_clock_counter <= 0;
			 end
			 
		end
	end
	endtask
	
	task T_IDLE;
	begin
		// Flow ctrl
		// Outputs
		// Actions
	end
	endtask

	task T_READ;
	begin
		// Flow ctrl
		// Outputs
		// Actions
	end
	endtask
	
//// FSM always block
	 always @(posedge CLK) begin
		  case (reg_state)
				S_ERROR: T_ERROR();
				S_INIT: T_INIT();
				S_IDLE: T_IDLE();
				S_READ: T_READ();
		  endcase
	 end
	 
//// slow clock handling 
	 always @(posedge CLK) begin
		  slow_clock_counter = slow_clock_pulse ? 0 : slow_clock_counter + 1;
	 end

//// Initalize sequence 
	 always @(posedge CLK) begin
		  if (reset) begin
				reg_state <= S_INIT;
		  end
	 end
endmodule
