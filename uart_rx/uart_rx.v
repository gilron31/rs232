`timescale 100ns / 1ns
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
	 localparam LP_SYS_CLK_hz = 10**(7)/2;
	 localparam LP_CLK_2_BAUD_ratio = LP_SYS_CLK_hz / P_BAUD;
	 localparam LP_SLOW_CLOCK_PRESCALER_BITS = 16; //ceil(log2(LP_CLK_2_BAUD_ratio))
	 localparam LP_READER_COUNTER = 4; //ceil(log2(P_UART_WIDTH + 2))

//// Wires and registers
	 wire int_reset;
	 wire init_counter_ready;
	 wire slow_clock_pulse;
	 wire start_bit_read_now;
	 wire stop_bit_read_now;
	 reg write_enable;
	 reg [P_UART_WIDTH - 1 : 0] fifo_data_in;
	 reg reg_error;
	 reg [LP_log_N_STATES - 1 : 0] reg_state;
	 reg [LP_LOG_CYCLES_TO_RESET - 1 : 0] init_counter;
	 reg [LP_SLOW_CLOCK_PRESCALER_BITS - 1 : 0] slow_clock_counter;
	 reg [LP_READER_COUNTER - 1 : 0] reader_counter;
//// Assignments
	 assign init_counter_ready = slow_clock_pulse & (init_counter == P_CYCLES_TO_RESET - 1);
	 assign error = reg_error;
	 assign int_reset = reset;
	 assign slow_clock_pulse = slow_clock_counter == (LP_CLK_2_BAUD_ratio - 1);
	 assign start_bit_read_now = reader_counter == 0;
	 assign stop_bit_read_now = reader_counter == P_UART_WIDTH + 1;
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
		// Outputs
		reg_error <= 1'b1;
	end
	endtask
	
	task T_INIT;
	begin
		// Flow ctrl & Actions
		 case ({init_counter_ready, serial_in})
			  2'b01 : begin
					init_counter <= init_counter + slow_clock_pulse;
					reg_state <= S_INIT;
			  end
			  2'b00 ,
			  2'b10 : begin
					init_counter <= 0;
					slow_clock_counter <= 0;
					reg_state <= S_INIT;
			  end
			  2'b11 : begin
					reg_state <= S_IDLE;
			  end
		 endcase
		// Outputs
		reg_error <= 1'b0;
	end
	endtask
	
	task T_IDLE;
	begin
		// Flow ctrl & actions
		 if (serial_in) begin
			  reg_state <= S_IDLE;
		 end
		 else begin
			  slow_clock_counter <= LP_CLK_2_BAUD_ratio / 2;
			  reg_state <= S_READ;
		 end
		 write_enable <= 0;
		// Outputs
		reg_error <= 1'b0;
	end
	endtask

	task T_READ;
	begin
		// Flow ctrl & Actions
		if (slow_clock_pulse) begin
			 case (reader_counter) 
				  0: begin
					   reg_state <= S_READ;
						reader_counter <= reader_counter + 1;
				  end
				  P_UART_WIDTH + 1: begin
					   reg_state <= serial_in ? S_IDLE : S_ERROR;
						write_enable <= serial_in ? 1 : 0;
						reader_counter <= 0;
				  end
				  default : begin
						reg_state <= S_READ;
						reader_counter <= reader_counter + 1;
						fifo_data_in[reader_counter - 1] <= serial_in;
				  end
			 endcase
		end
		else begin
			 reg_state <= S_READ;
		end
		// Outputs
		reg_error <= 1'b0;
	end
	endtask
	
	task T_RESET;
	begin
		 init_counter <= 0;
		 write_enable <= 0;
		 slow_clock_counter <= 0;
		 reader_counter <= 0;
		 fifo_data_in <= 0;
		 reg_error <= 0;
		 reg_state <= S_INIT;
	end
	endtask
	
//// FSM always block
	 always @(posedge CLK) begin
		  if (reset) begin
				T_RESET();
		  end
		  else begin
			  case (reg_state)
					S_ERROR: T_ERROR();
					S_INIT: T_INIT();
					S_IDLE: T_IDLE();
					S_READ: T_READ();
			  endcase
		  end
	 end
	 
//// slow clock handling 
	 always @(posedge CLK) begin
		  slow_clock_counter = slow_clock_pulse ? 0 : slow_clock_counter + 1;
	 end

endmodule
