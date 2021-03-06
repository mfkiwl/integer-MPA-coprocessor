`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SRS
// Engineer: Tomasz Stefanski & Kamil Rudnicki
//
// Create Date: 25.03.2017 11:33:42
// Design Name:
// Module Name: multiplier_dpi_TB
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////



module multiplier_dpi_TB();

	parameter MIN_PREC = 1;				// 1
	parameter MAX_PREC = 10;			// 511

	parameter NUM_ITERATIONS = 100000000;

	parameter c_data_width = 64;						//: natural := 16;
	parameter c_ctrl_width = 8;						//: natural := 16;
	parameter c_addr_width = 9;
	parameter c_select_width = 5;
	parameter c_id = 3;

	int seed_sv = 1;
	int seed;

	reg										r_clk;					//: in std_logic;
	reg										r_rst;					//: out std_logic;

	int a[0:((4*(MAX_PREC*MAX_PREC))-1)];
	int b[0:((4*(MAX_PREC*MAX_PREC))-1)];
	int c[0:((4*(MAX_PREC+MAX_PREC))-1)];

	int a_prec;
	int b_prec;
	int c_prec;

	int a_last[0:((MAX_PREC*MAX_PREC)-1)];
	int b_last[0:((MAX_PREC*MAX_PREC)-1)];
	int c_last[0:((MAX_PREC+MAX_PREC)-1)];
	int cycle[0:((MAX_PREC*MAX_PREC)-1)];

	import "DPI-C" function void tbGenTestDataMultiplicationIntegerSeedSrup (
											output int a[0:((4*(MAX_PREC*MAX_PREC))-1)], input int a_prec, output int a_last[0:((MAX_PREC*MAX_PREC)-1)],
											output int b[0:((4*(MAX_PREC*MAX_PREC))-1)], input int b_prec, output int b_last[0:((MAX_PREC*MAX_PREC)-1)],
											output int c[0:((4*(MAX_PREC+MAX_PREC))-1)], output int c_prec, output int c_last[0:((MAX_PREC+MAX_PREC)-1)],
											output int cycle[0:((MAX_PREC*MAX_PREC)-1)], input int seed);

	reg [63:0]      r_data_A					;
	reg [63:0]      r_data_B					;
	reg             r_data_last				;
	reg             r_data_wr_en				;
	reg             r_data_cycle				;


	wire [63:0] s_data							;		//: std_logic_vector(g_data_width-1 downto 0);
	wire        s_data_last						;		//: std_logic;
	wire        s_data_wr_en					;		//: std_logic;
	wire        s_data_zero						;		//: std_logic;



//-----------------------------------------------------------------------------
//-------------------------   TESTBENCH DEFINITION   --------------------------
//-----------------------------------------------------------------------------

	// CLOCK
	initial begin
		r_clk <= 1'd0;
	end

	always
		#1  r_clk =  ! r_clk;

	// RESET
	initial begin
		r_rst <= 1'd1;
		#250		r_rst <= 1'd0;
	end


	parameter FSM_CHECK_STATE = 0,
					FSM_OBTAIN_NEW_VALUES = 1,
					FSM_FEED_CTRL_DATA_1 = 2,
					FSM_FEED_CTRL_DATA_2 = 3,
					FSM_FEED_CTRL_DATA_3 = 4,
					FSM_FEED_DATA = 5,
					FSM_WAIT_FOR_END_OF_MULTIPLICATION = 6,
					FSM_DONE = 8,
					FSM_ERROR = 9;


	int fsm_state;
	int r_cnt_total;
	int r_processing_cnt;
	int r_read_index;
	reg        r_ok;
	reg        r_ok_all;
	reg [7:0]  r_ctrl_A;
	reg [7:0]  r_ctrl_B;
	reg [10:0] r_shift;
	reg        r_ctrl_valid_n;
	reg        r_add_start;
	reg        r_end_of_multiplication;
	reg        r_processing_A;
	reg        r_processing_B;


	wire [63:0] s_gmp_result = {c[4*r_read_index+3][15:0],c[4*r_read_index+2][15:0],c[4*r_read_index+1][15:0],c[4*r_read_index+0][15:0]};
	wire s_gmp_last = c_last[r_read_index];

	wire s_gmp_test = (s_data_last == s_gmp_last & s_data == s_gmp_result) ? 1'b1 : 1'b0;


	always @(posedge r_clk)
	begin
		if(r_rst)
		begin

			fsm_state <= FSM_CHECK_STATE;
			$srandom(seed_sv);

		end
		else
		begin

			r_ctrl_A = 0;
			r_ctrl_B = 0;
			r_ctrl_valid_n <= 1'b1;
			r_add_start <= 1'b0;

			r_data_A <= 64'h0;
			r_data_B <= 64'h0;

			r_data_last <= 1'h0;
			r_data_wr_en <= 1'b0;
			r_data_cycle <= 1'b0;

			case (fsm_state)

				FSM_CHECK_STATE:
				begin
					if(r_cnt_total < NUM_ITERATIONS)
					begin
						fsm_state <= FSM_OBTAIN_NEW_VALUES;
					end
					else
					begin

						if(r_ok)
							fsm_state <= FSM_DONE;
						else
							fsm_state <= FSM_ERROR;

					end
				end


				FSM_OBTAIN_NEW_VALUES:
				begin
					fsm_state <= FSM_FEED_CTRL_DATA_1;

					a_prec = $urandom_range(MAX_PREC, MIN_PREC);
					b_prec = $urandom_range(MAX_PREC, MIN_PREC);
					seed = $urandom();

					$display("pre-cmd");
					tbGenTestDataMultiplicationIntegerSeedSrup (a,
																				a_prec,
																				a_last,
																				b,
																				b_prec,
																				b_last,
																				c,
																				c_prec,
																				c_last,
																				cycle,
																				seed);
					$display("post-cmd");
				end


				FSM_FEED_CTRL_DATA_1:
				begin
					fsm_state <= FSM_FEED_CTRL_DATA_2;
					r_ctrl_A <= c_id;
					r_ctrl_B <= c_id;
					r_ctrl_valid_n <= 1'b0;
				end


				FSM_FEED_CTRL_DATA_2:
				begin
					fsm_state <= FSM_FEED_CTRL_DATA_3;
					r_ctrl_A <= 8'h2;
					r_ctrl_B <= 8'h3;
				end


				FSM_FEED_CTRL_DATA_3:
				begin
					fsm_state <= FSM_FEED_DATA;
					r_processing_A <= 1'b1;
					r_processing_B <= 1'b1;
					r_processing_cnt <= 0;
					r_data_cycle <= 1;	// quick tmp solution
				end


				FSM_FEED_DATA:
				begin
					if(!r_processing_A & !r_processing_B)
						fsm_state <= FSM_WAIT_FOR_END_OF_MULTIPLICATION;


					if(r_processing_A)
						r_data_A <= {a[4*r_processing_cnt+3][15:0],a[4*r_processing_cnt+2][15:0],a[4*r_processing_cnt+1][15:0],a[4*r_processing_cnt+0][15:0]};
					else
						r_data_A <= 64'h0;

					if(r_processing_B)
						r_data_B <= {b[4*r_processing_cnt+3][15:0],b[4*r_processing_cnt+2][15:0],b[4*r_processing_cnt+1][15:0],b[4*r_processing_cnt+0][15:0]};
					else
						r_data_B <= 64'h0;

					if((r_processing_A & r_processing_B & a_last[r_processing_cnt] & b_last[r_processing_cnt]) |
						(r_processing_A & !r_processing_B & a_last[r_processing_cnt]) |
						(!r_processing_A & r_processing_B & b_last[r_processing_cnt]))
						r_data_last <= 1'b1;

					if(!r_data_last)
						r_data_wr_en <= 1'b1;

					r_data_last <= a_last[r_processing_cnt] & b_last[r_processing_cnt];
					//r_data_cycle <= cycle[r_processing_cnt];
					r_data_cycle <= cycle[r_processing_cnt+1] | (a_last[r_processing_cnt] & b_last[r_processing_cnt]);		// quick tmp solution


					if(a_last[r_processing_cnt] == 1'b1)
						r_processing_A <= 1'b0;

					if(b_last[r_processing_cnt] == 1'b1)
						r_processing_B <= 1'b0;

					r_processing_cnt <= r_processing_cnt + 1;
				end

				FSM_WAIT_FOR_END_OF_MULTIPLICATION:
				begin
					if(r_end_of_multiplication)
					begin
						fsm_state <= FSM_CHECK_STATE;
						r_cnt_total <= r_cnt_total + 1;
					end
				end


				FSM_DONE:
				begin
					$finish;
				end


				FSM_ERROR:
				begin
					$finish;
				end

			endcase
		end
	end


	always @(posedge r_clk)
	begin

		if(r_rst)
		begin
			r_ok_all <= 1'b1;
		end
		else if(!r_ctrl_valid_n)
		begin
			r_ok <= 1'b1;
			r_read_index <= 0;
		end
		else if(s_data_wr_en)
		begin

			if(s_gmp_test == 1'b0)			// regular
			begin
				r_ok <= 1'b0;
				r_ok_all <= 1'b0;
			end

			r_read_index <= r_read_index + 1;

		end

		r_end_of_multiplication <= r_shift[10];

		if(s_data_wr_en & s_data_last)
			r_shift <= 10'b1;
		else
			r_shift <= {r_shift[9:0], 1'b0};

	end





	multiplier_TB_wrapper #(
		.g_data_width				(c_data_width						),		//: natural := 64;
		.g_addr_width				(c_addr_width						),		//: natural := 9;
		.g_ctrl_width				(c_ctrl_width						),		//: natural := 8;
		.g_select_width			(c_select_width					),		//: natural := 4;
		.g_id							(c_id									)		//: natural := 2;
	)
	multiplier_TB_wrapper_inst (
		.pi_clk						(r_clk								),		//: in std_logic;
		.pi_rst						(r_rst								),		//: in std_logic;

		.pi_ctrl_ch_A				(r_ctrl_A							),		//: in std_logic_vector(C_STD_CTRL_WIDTH-1 downto 0);
		.pi_ctrl_ch_B				(r_ctrl_B							),		//: in std_logic_vector(C_STD_CTRL_WIDTH-1 downto 0);
		.pi_ctrl_valid_n			(r_ctrl_valid_n					),		//: in std_logic;

		.pi_data_0					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_1					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_2					(r_data_A							),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_3					(r_data_B							),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_4					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_5					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_6					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_7					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_8					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_9					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_10					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_11					(										),		//: std_logic_vector(g_data_width-1 downto 0);
		.pi_data_12					(										),		//: std_logic_vector(g_data_width-1 downto 0);

		.pi_data_last				(r_data_last						),		//: std_logic;
		.pi_data_wr_en				(r_data_wr_en						),		//: std_logic;
		.pi_data_cycle				(r_data_cycle						),		//: std_logic;

		.po_data						(s_data								),		//: std_logic_vector(g_data_width-1 downto 0);
		.po_data_last				(s_data_last						),		//: std_logic;
		.po_data_wr_en				(s_data_wr_en						),		//: std_logic;
		.po_data_zero				(s_data_zero						)		//: std_logic;
	);

endmodule
