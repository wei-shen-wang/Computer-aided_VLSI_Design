
module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);

// ---------------------------------------------------------------------------
// parameters and integers
// ---------------------------------------------------------------------------

integer i;

// states
localparam S_IDLE = 4'd0;
localparam S_FETCH = 4'd1;
localparam S_DECODE = 4'd2;
localparam S_LOAD_IMAGE = 4'd3;
localparam S_SHIFT_RESIZE = 4'd4;
localparam S_DISPLAY = 4'd5;
localparam S_MED = 4'd6;
localparam S_CONV = 4'd7;
localparam S_SOB = 4'd8;
localparam S_BUF = 4'd9;

// op_mode
localparam OP_INPUT = 4'b0000;
localparam OP_RIGHT_SHIFT = 4'b0001;
localparam OP_LEFT_SHIFT = 4'b0010;
localparam OP_UP_SHIFT = 4'b0011;
localparam OP_DOWN_SHIFT = 4'b0100;
localparam OP_REDUCE_CHANNEl = 4'b0101;
localparam OP_INCREASE_CHANNEL = 4'b0110;
localparam OP_DISPLAY = 4'b0111;
localparam OP_CONV = 4'b1000;
localparam OP_MED = 4'b1001;
localparam OP_SOB = 4'b1010;

// gradient direction
localparam TAN0 = 2'd0;
localparam TAN45 = 2'd1;
localparam TAN90 = 2'd2;
localparam TAN135 = 2'd3;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

wire [7:0] sram_data_out [0:3];
wire [10:0] channel_depth_r_shift2_plus2;
wire [19:0] G00_y_mag_ext, G01_y_mag_ext, G10_y_mag_ext, G11_y_mag_ext;
wire [19:0] G00_x_2357, G00_x_2_2357;
wire [19:0] G01_x_2357, G01_x_2_2357;
wire [19:0] G10_x_2357, G10_x_2_2357;
wire [19:0] G11_x_2357, G11_x_2_2357;

reg [7:0] sram_data_out_r [0:3];
reg [10:0] display_address_and_sram;
reg [3:0] curr_state, next_state;
reg [10:0] counter_r, counter_w;
reg o_in_ready_r;
reg [13:0] o_out_data_r, o_out_data_w;
reg o_out_valid_r;
reg o_op_ready_r, o_op_ready_w;
// , o_out_valid_w;
reg [7:0] sram_data_in_r, sram_data_in_w;
reg [8:0] sram_addr_r [0:3];
reg [8:0] sram_addr_w [0:3];
wire sram_wen [0:3];
reg sram_wen_r [0:3];
reg [2:0] origin_row_r, origin_row_w;
reg [2:0] origin_col_r, origin_col_w;
reg [5:0] channel_depth_r, channel_depth_w;
reg [3:0] op_mode_r, op_mode_w;
reg [2:0] sram_sel_with_delay;
reg [2:0] sram_sel_with_delay_2;

// cms: convolution, median, sobel
reg [10:0] cms_address_and_sram [0:3];
reg [2:0] cms_sram_sel_with_delay [0:3];
reg [2:0] cms_sram_sel_with_delay_2 [0:3];
reg [7:0] cms_sram_out_reg [0:3];
wire [8:0] cms_sram_out_reg_shift_1 [0:3];
wire [9:0] cms_sram_out_reg_shift_2 [0:3];
wire signed [10:0] cms_sram_out_reg_ext [0:3];

// convolution
reg [17:0] conv_sum_r [0:3]; // add 4 bit because the last 4 bit is floating point
reg [17:0] conv_sum_w [0:3];
reg [17:0] selected_conv_sum;

// median registers, the array index here is the relative row index to the box
reg [7:0] first_box_out_group_min_w [0:2];
reg [7:0] first_box_out_group_min_r [0:2];
reg [7:0] first_box_out_group_med_w [0:2];
reg [7:0] first_box_out_group_med_r [0:2];
reg [7:0] first_box_out_group_max_w [0:2];
reg [7:0] first_box_out_group_max_r [0:2];
reg [7:0] first_box_out_group_min_max, first_box_out_group_med_med, first_box_out_group_max_min;
reg [7:0] first_box_out_group_total_med_r, first_box_out_group_total_med_w;
reg [7:0] second_box_out_group_min_w [0:2];
reg [7:0] second_box_out_group_min_r [0:2];
reg [7:0] second_box_out_group_med_w [0:2];
reg [7:0] second_box_out_group_med_r [0:2];
reg [7:0] second_box_out_group_max_w [0:2];
reg [7:0] second_box_out_group_max_r [0:2];
reg [7:0] second_box_out_group_min_max, second_box_out_group_med_med, second_box_out_group_max_min;
reg [7:0] second_box_out_group_total_med_r, second_box_out_group_total_med_w;
reg [7:0] third_box_out_group_min_w [0:2];
reg [7:0] third_box_out_group_min_r [0:2];
reg [7:0] third_box_out_group_med_w [0:2];
reg [7:0] third_box_out_group_med_r [0:2];
reg [7:0] third_box_out_group_max_w [0:2];
reg [7:0] third_box_out_group_max_r [0:2];
reg [7:0] third_box_out_group_min_max, third_box_out_group_med_med, third_box_out_group_max_min;
reg [7:0] third_box_out_group_total_med_r, third_box_out_group_total_med_w;
reg [7:0] fourth_box_out_group_min_w [0:2];
reg [7:0] fourth_box_out_group_min_r [0:2];
reg [7:0] fourth_box_out_group_med_w [0:2];
reg [7:0] fourth_box_out_group_med_r [0:2];
reg [7:0] fourth_box_out_group_max_w [0:2];
reg [7:0] fourth_box_out_group_max_r [0:2];
reg [7:0] fourth_box_out_group_min_max, fourth_box_out_group_med_med, fourth_box_out_group_max_min;
reg [7:0] fourth_box_out_group_total_med_r, fourth_box_out_group_total_med_w;

// sobel registers
reg signed [10:0] G00_x_r, G00_y_r, G01_x_r, G01_y_r, G10_x_r, G10_y_r, G11_x_r, G11_y_r;
reg signed [10:0] G00_x_w, G00_y_w, G01_x_w, G01_y_w, G10_x_w, G10_y_w, G11_x_w, G11_y_w;
reg [10:0] G00_x_mag, G00_y_mag, G01_x_mag, G01_y_mag, G10_x_mag, G10_y_mag, G11_x_mag, G11_y_mag;
reg [1:0] G00_dir_w, G01_dir_w, G10_dir_w, G11_dir_w;
reg [1:0] G00_dir_r, G01_dir_r, G10_dir_r, G11_dir_r;
reg signed [10:0] G00_sobel_nms, G01_sobel_nms, G10_sobel_nms, G11_sobel_nms;

reg [10:0] G00_mag_curr, G01_mag_curr, G10_mag_curr, G11_mag_curr;
reg [10:0] G00_mag_next, G01_mag_next, G10_mag_next, G11_mag_next;

reg signed [10:0] sobel_register_files_r [0:15];
reg signed [10:0] sobel_register_files_w [0:15];
reg signed [10:0] sobel_register_files_for_4_cycle_r [0:15];
reg signed [10:0] sobel_register_files_for_4_cycle_w [0:15];

// i_op_mode: used in FSM case, channel size update, shift update, op_mode_w update
// op_mode_r: used for display, for correct cycle time
// op_mode_w: will change when i_op_valid is high

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

// SRAM
sram_512x8 a_sram (
	.Q(sram_data_out[0]),
	.CLK(i_clk),
	.CEN(1'b0),
	.WEN(sram_wen_r[0]),
	.A(sram_addr_r[0]),
	.D(sram_data_in_r)
);
	
sram_512x8 b_sram (
	.Q(sram_data_out[1]),
	.CLK(i_clk),
	.CEN(1'b0),
	.WEN(sram_wen_r[1]),
	.A(sram_addr_r[1]),
	.D(sram_data_in_r)
);

sram_512x8 c_sram (
	.Q(sram_data_out[2]),
	.CLK(i_clk),
	.CEN(1'b0),
	.WEN(sram_wen_r[2]),
	.A(sram_addr_r[2]),
	.D(sram_data_in_r)
);
	
sram_512x8 d_sram (
	.Q(sram_data_out[3]),
	.CLK(i_clk),
	.CEN(1'b0),
	.WEN(sram_wen_r[3]),
	.A(sram_addr_r[3]),
	.D(sram_data_in_r)
);

// output wires
assign o_in_ready = o_in_ready_r;
assign o_op_ready = o_op_ready_r;
assign o_out_valid = o_out_valid_r;
assign o_out_data = o_out_data_r;
assign sram_wen[0] = !(curr_state == S_LOAD_IMAGE && counter_r[1:0] == 2'd0);
assign sram_wen[1] = !(curr_state == S_LOAD_IMAGE && counter_r[1:0] == 2'd1);
assign sram_wen[2] = !(curr_state == S_LOAD_IMAGE && counter_r[1:0] == 2'd2);
assign sram_wen[3] = !(curr_state == S_LOAD_IMAGE && counter_r[1:0] == 2'd3);

// common used wires
assign channel_depth_r_shift2_plus2 = (channel_depth_r << 2) + 2;
assign cms_sram_out_reg_shift_1[0] = {cms_sram_out_reg[0], 1'b0};
assign cms_sram_out_reg_shift_1[1] = {cms_sram_out_reg[1], 1'b0};
assign cms_sram_out_reg_shift_1[2] = {cms_sram_out_reg[2], 1'b0};
assign cms_sram_out_reg_shift_1[3] = {cms_sram_out_reg[3], 1'b0};
assign cms_sram_out_reg_shift_2[0] = {cms_sram_out_reg[0], 2'b0};
assign cms_sram_out_reg_shift_2[1] = {cms_sram_out_reg[1], 2'b0};
assign cms_sram_out_reg_shift_2[2] = {cms_sram_out_reg[2], 2'b0};
assign cms_sram_out_reg_shift_2[3] = {cms_sram_out_reg[3], 2'b0};

// sobel used wires
assign G00_y_mag_ext = {G00_y_mag, 7'b0};
assign G01_y_mag_ext = {G01_y_mag, 7'b0};
assign G10_y_mag_ext = {G10_y_mag, 7'b0};
assign G11_y_mag_ext = {G11_y_mag, 7'b0};
// assign G00_x_2357 = (({3'b0, G00_x_mag, 5'b0}) + ({4'b0, G00_x_mag, 4'b0})) + (({6'b0, G00_x_mag, 2'b0}) + ({8'b0, G00_x_mag}));
// assign G00_x_2_2357 = G00_x_2357 + ({G00_x_mag, 8'b0});
assign G00_x_2357 = 9'b000110101 * G00_x_mag;
assign G00_x_2_2357 = 9'b100110101 * G00_x_mag;
// assign G01_x_2357 = (({3'b0, G01_x_mag, 5'b0}) + ({4'b0, G01_x_mag, 4'b0}))
// + (({6'b0, G01_x_mag, 2'b0}) + ({8'b0, G01_x_mag}));
// assign G01_x_2_2357 = G01_x_2357 + ({G01_x_mag, 8'b0});
assign G01_x_2357 = 9'b000110101 * G01_x_mag;
assign G01_x_2_2357 = 9'b100110101 * G01_x_mag;
// assign G10_x_2357 = (({3'b0, G10_x_mag, 5'b0}) + ({4'b0, G10_x_mag, 4'b0}))
// + (({6'b0, G10_x_mag, 2'b0}) + ({8'b0, G10_x_mag}));
// assign G10_x_2_2357 = G10_x_2357 + ({G10_x_mag, 8'b0});
assign G10_x_2357 = 9'b000110101 * G10_x_mag;
assign G10_x_2_2357 = 9'b100110101 * G10_x_mag;
// assign G11_x_2357 = (({3'b0, G11_x_mag, 5'b0}) + ({4'b0, G11_x_mag, 4'b0}))
// + (({6'b0, G11_x_mag, 2'b0}) + ({8'b0, G11_x_mag}));
// assign G11_x_2_2357 = G11_x_2357 + ({G11_x_mag, 8'b0});
assign G11_x_2357 = 9'b000110101 * G11_x_mag;
assign G11_x_2_2357 = 9'b100110101 * G11_x_mag;

// cms extension
assign cms_sram_out_reg_ext[0] = {3'd0, cms_sram_out_reg[0]};
assign cms_sram_out_reg_ext[1] = {3'd0, cms_sram_out_reg[1]};
assign cms_sram_out_reg_ext[2] = {3'd0, cms_sram_out_reg[2]};
assign cms_sram_out_reg_ext[3] = {3'd0, cms_sram_out_reg[3]};

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

// FSM
always @(*) begin
	next_state = curr_state;
	o_op_ready_w = 0;
	case (curr_state)
		S_IDLE: begin
			next_state = S_BUF;
		end
		S_BUF: begin
			next_state = S_FETCH;
			o_op_ready_w = 1;
		end
		S_FETCH: begin
			next_state = S_DECODE;
		end
		S_DECODE: begin
			case(i_op_mode)
				OP_DISPLAY: begin
					next_state = S_DISPLAY;
				end
				OP_MED: begin
					next_state = S_MED;
				end
				OP_CONV: begin
					next_state = S_CONV;
				end
				OP_SOB: begin
					next_state = S_SOB;
				end
				OP_INPUT: begin
					next_state = S_LOAD_IMAGE;
				end
				OP_DOWN_SHIFT, OP_LEFT_SHIFT, OP_RIGHT_SHIFT, OP_UP_SHIFT, OP_REDUCE_CHANNEl, OP_INCREASE_CHANNEL: 
				begin
					next_state = S_SHIFT_RESIZE;
				end
			endcase
		end
		S_LOAD_IMAGE: begin
			if (counter_r == 11'd2047) begin
				next_state = S_IDLE;
			end
		end
		S_SHIFT_RESIZE: begin
			next_state = S_BUF;
		end
		S_DISPLAY: begin
			if (counter_r == (channel_depth_r_shift2_plus2 + 1)) begin
				next_state = S_IDLE;
			end
		end
		S_CONV: begin
			if (counter_r == ( channel_depth_r_shift2_plus2 + 4 )) begin
				next_state = S_IDLE;
			end
		end
		S_MED: begin
			if (counter_r == 11'd22) begin
				next_state = S_IDLE;
			end
		end
		S_SOB: begin
			if (counter_r == 11'd25) begin
				next_state = S_IDLE;
			end
		end
	endcase
end

// op_mode register
always @(*) begin
	op_mode_w = op_mode_r;
	if (i_op_valid) begin
		op_mode_w = i_op_mode;
	end
end

// display address (DISPLAY)
always @(*) begin
	display_address_and_sram = 0;
	if (curr_state == S_DISPLAY) begin
		case (counter_r[1:0])
		2'd0:display_address_and_sram = {counter_r[6:2], origin_row_r, origin_col_r};
		2'd1:display_address_and_sram = {counter_r[6:2], origin_row_r, origin_col_r} + 1;
		2'd2:display_address_and_sram = {counter_r[6:2], origin_row_r, origin_col_r} + 8;
		2'd3:display_address_and_sram = {counter_r[6:2], origin_row_r, origin_col_r} + 9;
		endcase
	end
end

// convolution, median, sobel address
always @(*) begin
	for (i=0;i<4;i=i+1) begin
		cms_address_and_sram[i] = 0;
	end
	if (curr_state == S_CONV || curr_state == S_MED || curr_state == S_SOB) begin
		case (counter_r[1:0])
			2'd0: begin
				cms_address_and_sram[0] = {counter_r[6:2], origin_row_r, origin_col_r} - 9;
				cms_address_and_sram[1] = {counter_r[6:2], origin_row_r, origin_col_r} - 8;
				cms_address_and_sram[2] = {counter_r[6:2], origin_row_r, origin_col_r} - 7;
				cms_address_and_sram[3] = {counter_r[6:2], origin_row_r, origin_col_r} - 6;
			end
			2'd1: begin
				cms_address_and_sram[0] = {counter_r[6:2], origin_row_r, origin_col_r} - 1;
				cms_address_and_sram[1] = {counter_r[6:2], origin_row_r, origin_col_r};
				cms_address_and_sram[2] = {counter_r[6:2], origin_row_r, origin_col_r} + 1;
				cms_address_and_sram[3] = {counter_r[6:2], origin_row_r, origin_col_r} + 2;
			end
			2'd2: begin
				cms_address_and_sram[0] = {counter_r[6:2], origin_row_r, origin_col_r} + 7;
				cms_address_and_sram[1] = {counter_r[6:2], origin_row_r, origin_col_r} + 8;
				cms_address_and_sram[2] = {counter_r[6:2], origin_row_r, origin_col_r} + 9;
				cms_address_and_sram[3] = {counter_r[6:2], origin_row_r, origin_col_r} + 10;
			end
			2'd3: begin
				cms_address_and_sram[0] = {counter_r[6:2], origin_row_r, origin_col_r} + 15;
				cms_address_and_sram[1] = {counter_r[6:2], origin_row_r, origin_col_r} + 16;
				cms_address_and_sram[2] = {counter_r[6:2], origin_row_r, origin_col_r} + 17;
				cms_address_and_sram[3] = {counter_r[6:2], origin_row_r, origin_col_r} + 18;
			end
		endcase
	end
end

// SRAM address
always @(*) begin
	// default reading pixels from SRAM
	// display
	for (i = 0;i < 4 ; i = i+1) begin
		sram_addr_w[i] = sram_addr_r[i];
	end
	case (curr_state)
		S_LOAD_IMAGE: begin
			case(counter_r[1:0])
				2'd0: sram_addr_w[0] = counter_r[10:2];
				2'd1: sram_addr_w[1] = counter_r[10:2];
				2'd2: sram_addr_w[2] = counter_r[10:2];
				2'd3: sram_addr_w[3] = counter_r[10:2];
			endcase
		end
		S_DISPLAY: begin
			sram_addr_w[display_address_and_sram[1:0]] = display_address_and_sram[10:2];
		end
		S_CONV, S_MED, S_SOB: begin
			sram_addr_w[cms_address_and_sram[0][1:0]] = cms_address_and_sram[0][10:2];
			sram_addr_w[cms_address_and_sram[1][1:0]] = cms_address_and_sram[1][10:2];
			sram_addr_w[cms_address_and_sram[2][1:0]] = cms_address_and_sram[2][10:2];
			sram_addr_w[cms_address_and_sram[3][1:0]] = cms_address_and_sram[3][10:2];
		end
	endcase
end

// SRAM data in
always @(*) begin
	sram_data_in_w = sram_data_in_r;
	if (curr_state == S_LOAD_IMAGE && i_in_valid) begin
		sram_data_in_w = i_in_data;
	end
end

// output data registers (display, convolution, median, sobel)
always @(*) begin
	o_out_data_w = 0;
	case (op_mode_r)
		OP_DISPLAY: begin
			o_out_data_w = {6'd0, sram_data_out_r[sram_sel_with_delay_2]};
		end
		OP_CONV: begin
			o_out_data_w = selected_conv_sum[17:4] + selected_conv_sum[3];
		end
		OP_MED: begin
			case (counter_r[1:0])
			2'd3: o_out_data_w = {6'd0, first_box_out_group_total_med_r};
			2'd0: o_out_data_w = {6'd0, second_box_out_group_total_med_r};
			2'd1: o_out_data_w = {6'd0, third_box_out_group_total_med_r};
			2'd2: o_out_data_w = {6'd0, fourth_box_out_group_total_med_r};
			endcase
		end
		OP_SOB: begin
			case (counter_r[1:0])
			2'd2: o_out_data_w = {3'd0, G00_sobel_nms};
			2'd3: o_out_data_w = {3'd0, G10_sobel_nms};
			2'd0: o_out_data_w = {3'd0, G01_sobel_nms};
			2'd1: o_out_data_w = {3'd0, G11_sobel_nms};
			endcase
		end
	endcase
end

// channel depth reg
always @(*) begin
	channel_depth_w = channel_depth_r;
	case (channel_depth_r)
		6'd32:begin
			if(i_op_mode == OP_REDUCE_CHANNEl) begin
				channel_depth_w = 6'd16;
			end
		end 
		6'd16:begin
			if(i_op_mode == OP_REDUCE_CHANNEl) begin
				channel_depth_w = 6'd8;
			end
			else if(i_op_mode == OP_INCREASE_CHANNEL) begin
				channel_depth_w = 6'd32;
			end
		end
		6'd8:begin
			if(i_op_mode == OP_INCREASE_CHANNEL) begin
				channel_depth_w = 6'd16;
			end
		end
	endcase
end

// Counter
always @(*) begin
	counter_w = 0;
	case (curr_state)
		S_LOAD_IMAGE: counter_w = counter_r + 1;
		S_DISPLAY, S_MED, S_CONV, S_SOB: counter_w = counter_r + 1;
	endcase
end

// origin update
always @(*) begin
	origin_row_w = origin_row_r;
	origin_col_w = origin_col_r;
	if(!(curr_state == S_SHIFT_RESIZE)
	&& !(((origin_col_r[2:0] == 3'b000) && (i_op_mode == OP_LEFT_SHIFT))
		||((origin_col_r[2:0] == 3'b110) && (i_op_mode == OP_RIGHT_SHIFT))
		||((origin_row_r[2:0] == 3'b000) && (i_op_mode == OP_UP_SHIFT))
		||((origin_row_r[2:0] == 3'b110) && (i_op_mode == OP_DOWN_SHIFT))))
	begin
		case (i_op_mode)
			OP_RIGHT_SHIFT: origin_col_w = origin_col_r + 1;
			OP_LEFT_SHIFT: origin_col_w = origin_col_r - 1;
			OP_UP_SHIFT: origin_row_w = origin_row_r - 1;
			OP_DOWN_SHIFT: origin_row_w = origin_row_r + 1;
		endcase
	end
end

// convolution, median, sobel data reg
always @(*) begin
	for (i=0;i<4;i=i+1) begin
		cms_sram_out_reg[i] = 0;
	end
	if (op_mode_r == OP_CONV || op_mode_r == OP_MED || op_mode_r == OP_SOB) begin
		case (counter_r[1:0])
			2'd3: begin
				cms_sram_out_reg[0] = (origin_col_r[2:0] == 3'd0 || origin_row_r == 3'd0) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[0]];
				cms_sram_out_reg[1] = (origin_row_r[2:0] == 3'd0) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[1]];
				cms_sram_out_reg[2] = (origin_row_r[2:0] == 3'd0) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[2]];
				cms_sram_out_reg[3] = (origin_col_r[2:0] == 3'd6 || origin_row_r == 3'd0) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[3]];
			end
			2'd0: begin
				cms_sram_out_reg[0] = (origin_col_r[2:0] == 3'd0) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[0]];
				cms_sram_out_reg[1] = sram_data_out_r[cms_sram_sel_with_delay_2[1]];
				cms_sram_out_reg[2] = sram_data_out_r[cms_sram_sel_with_delay_2[2]];
				cms_sram_out_reg[3] = (origin_col_r[2:0] == 3'd6) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[3]];
			end
			2'd1: begin
				cms_sram_out_reg[0] = (origin_col_r[2:0] == 3'd0) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[0]];
				cms_sram_out_reg[1] = sram_data_out_r[cms_sram_sel_with_delay_2[1]];
				cms_sram_out_reg[2] = sram_data_out_r[cms_sram_sel_with_delay_2[2]];
				cms_sram_out_reg[3] = (origin_col_r[2:0] == 3'd6) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[3]];
			end
			2'd2: begin
				cms_sram_out_reg[0] = (origin_col_r[2:0] == 3'd0 || origin_row_r == 3'd6) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[0]];
				cms_sram_out_reg[1] = (origin_row_r[2:0] == 3'd6) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[1]];
				cms_sram_out_reg[2] = (origin_row_r[2:0] == 3'd6) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[2]];
				cms_sram_out_reg[3] = (origin_col_r[2:0] == 3'd6 || origin_row_r == 3'd6) ? 0 : sram_data_out_r[cms_sram_sel_with_delay_2[3]];
			end
		endcase
	end
end

// sobel registers
always @(*) begin
	for (i=0;i<16;i=i+1)begin
		sobel_register_files_w[i] = sobel_register_files_r[i];
		sobel_register_files_for_4_cycle_w[i] = sobel_register_files_for_4_cycle_r[i];
	end
	if (curr_state == S_FETCH) begin
		for (i=0;i<16;i=i+1) begin
			sobel_register_files_w[i] = 0;
			sobel_register_files_for_4_cycle_w[i] = 0;
		end
	end
	else begin		
		case (counter_r[1:0])
			2'd3: begin
				sobel_register_files_w[0] = cms_sram_out_reg_ext[0];
				sobel_register_files_w[1] = cms_sram_out_reg_ext[1];
				sobel_register_files_w[2] = cms_sram_out_reg_ext[2];
				sobel_register_files_w[3] = cms_sram_out_reg_ext[3];
				for (i=0;i<16;i=i+1) begin
					sobel_register_files_for_4_cycle_w[i] = sobel_register_files_r[i];
				end
			end
			2'd0: begin
				sobel_register_files_w[4] = cms_sram_out_reg_ext[0];
				sobel_register_files_w[5] = cms_sram_out_reg_ext[1];
				sobel_register_files_w[6] = cms_sram_out_reg_ext[2];
				sobel_register_files_w[7] = cms_sram_out_reg_ext[3];
			end
			2'd1: begin
				sobel_register_files_w[8] = cms_sram_out_reg_ext[0];
				sobel_register_files_w[9] = cms_sram_out_reg_ext[1];
				sobel_register_files_w[10] = cms_sram_out_reg_ext[2];
				sobel_register_files_w[11] = cms_sram_out_reg_ext[3];
			end
			2'd2: begin
				sobel_register_files_w[12] = cms_sram_out_reg_ext[0];
				sobel_register_files_w[13] = cms_sram_out_reg_ext[1];
				sobel_register_files_w[14] = cms_sram_out_reg_ext[2];
				sobel_register_files_w[15] = cms_sram_out_reg_ext[3];
			end
		endcase
	end
end

// sobel gradient x, y
always @(*) begin
	G00_x_w = G00_x_r;
	G00_y_w = G00_y_r;
	G01_x_w = G01_x_r;
	G01_y_w = G01_y_r;
	G10_x_w = G10_x_r;
	G10_y_w = G10_y_r;
	G11_x_w = G11_x_r;
	G11_y_w = G11_y_r;
	if (curr_state == S_FETCH) begin
		G00_x_w = 0;
		G00_y_w = 0;
		G01_x_w = 0;
		G01_y_w = 0;
		G10_x_w = 0;
		G10_y_w = 0;
		G11_x_w = 0;
		G11_y_w = 0;
	end
	else begin
		G00_x_w = -sobel_register_files_for_4_cycle_r[0] + sobel_register_files_for_4_cycle_r[2]
		- 2 * sobel_register_files_for_4_cycle_r[4] + 2 * sobel_register_files_for_4_cycle_r[6]
		- sobel_register_files_for_4_cycle_r[8] + sobel_register_files_for_4_cycle_r[10];
		G00_y_w = -sobel_register_files_for_4_cycle_r[0] - 2 * sobel_register_files_for_4_cycle_r[1]
		- sobel_register_files_for_4_cycle_r[2] + sobel_register_files_for_4_cycle_r[8]
		+ 2 * sobel_register_files_for_4_cycle_r[9] + sobel_register_files_for_4_cycle_r[10];
		G01_x_w = -sobel_register_files_for_4_cycle_r[1] + sobel_register_files_for_4_cycle_r[3]
		- 2 * sobel_register_files_for_4_cycle_r[5] + 2 * sobel_register_files_for_4_cycle_r[7]
		- sobel_register_files_for_4_cycle_r[9] + sobel_register_files_for_4_cycle_r[11];
		G01_y_w = -sobel_register_files_for_4_cycle_r[1] - 2 * sobel_register_files_for_4_cycle_r[2]
		- sobel_register_files_for_4_cycle_r[3] + sobel_register_files_for_4_cycle_r[9]
		+ 2 * sobel_register_files_for_4_cycle_r[10] + sobel_register_files_for_4_cycle_r[11];
		G10_x_w = -sobel_register_files_for_4_cycle_r[4] + sobel_register_files_for_4_cycle_r[6]
		- 2 * sobel_register_files_for_4_cycle_r[8] + 2 * sobel_register_files_for_4_cycle_r[10]
		- sobel_register_files_for_4_cycle_r[12] + sobel_register_files_for_4_cycle_r[14];
		G10_y_w = -sobel_register_files_for_4_cycle_r[4] - 2 * sobel_register_files_for_4_cycle_r[5]
		- sobel_register_files_for_4_cycle_r[6] + sobel_register_files_for_4_cycle_r[12]
		+ 2 * sobel_register_files_for_4_cycle_r[13] + sobel_register_files_for_4_cycle_r[14];
		G11_x_w = -sobel_register_files_for_4_cycle_r[5] + sobel_register_files_for_4_cycle_r[7]
		- 2 * sobel_register_files_for_4_cycle_r[9] + 2 * sobel_register_files_for_4_cycle_r[11]
		- sobel_register_files_for_4_cycle_r[13] + sobel_register_files_for_4_cycle_r[15];
		G11_y_w = -sobel_register_files_for_4_cycle_r[5] - 2 * sobel_register_files_for_4_cycle_r[6]
		- sobel_register_files_for_4_cycle_r[7] + sobel_register_files_for_4_cycle_r[13]
		+ 2 * sobel_register_files_for_4_cycle_r[14] + sobel_register_files_for_4_cycle_r[15];
	end
end

// sobel gradient magnitude
always @(*) begin
	G00_mag_next = G00_mag_curr;
	G01_mag_next = G01_mag_curr;
	G10_mag_next = G10_mag_curr;
	G11_mag_next = G11_mag_curr;
	if(curr_state == S_FETCH) begin
		G00_mag_next = 0;
		G01_mag_next = 0;
		G10_mag_next = 0;
		G11_mag_next = 0;
		G00_x_mag = 0;
		G00_y_mag = 0;
		G01_x_mag = 0;
		G01_y_mag = 0;
		G10_x_mag = 0;
		G10_y_mag = 0;
		G11_x_mag = 0;
		G11_y_mag = 0;
	end
	else begin
		G00_x_mag = (G00_x_r[10]) ? ((~G00_x_r) + 1) : G00_x_r;
		G00_y_mag = (G00_y_r[10]) ? ((~G00_y_r) + 1) : G00_y_r;
		G01_x_mag = (G01_x_r[10]) ? ((~G01_x_r) + 1) : G01_x_r;
		G01_y_mag = (G01_y_r[10]) ? ((~G01_y_r) + 1) : G01_y_r;
		G10_x_mag = (G10_x_r[10]) ? ((~G10_x_r) + 1) : G10_x_r;
		G10_y_mag = (G10_y_r[10]) ? ((~G10_y_r) + 1) : G10_y_r;
		G11_x_mag = (G11_x_r[10]) ? ((~G11_x_r) + 1) : G11_x_r;
		G11_y_mag = (G11_y_r[10]) ? ((~G11_y_r) + 1) : G11_y_r;
		G00_mag_next = G00_x_mag + G00_y_mag;
		G01_mag_next = G01_x_mag + G01_y_mag;
		G10_mag_next = G10_x_mag + G10_y_mag;
		G11_mag_next = G11_x_mag + G11_y_mag;
	end
end

// sobel gradient inverse tangent
always @(*) begin
	// G00
	if(G00_x_mag == 0) begin
		G00_dir_w = TAN90;
	end
	else if (G00_y_mag_ext < G00_x_2357) begin
		G00_dir_w = TAN0;
	end
	else if (G00_x_2_2357 < G00_y_mag_ext) begin
		G00_dir_w = TAN90;
	end
	else begin
		G00_dir_w = (G00_x_r[10] == G00_y_r[10]) ? TAN45 : TAN135;
	end
	// G01
	if(G01_x_mag == 0) begin
		G01_dir_w = TAN90;
	end
	else if (G01_y_mag_ext < G01_x_2357) begin
		G01_dir_w = TAN0;
	end
	else if (G01_x_2_2357 < G01_y_mag_ext) begin
		G01_dir_w = TAN90;
	end
	else begin
		G01_dir_w = (G01_x_r[10] == G01_y_r[10]) ? TAN45 : TAN135;
	end
	// G10
	if(G10_x_mag == 0) begin
		G10_dir_w = TAN90;
	end
	else if (G10_y_mag_ext < G10_x_2357) begin
		G10_dir_w = TAN0;
	end
	else if (G10_x_2_2357 < G10_y_mag_ext) begin
		G10_dir_w = TAN90;
	end
	else begin
		G10_dir_w = (G10_x_r[10] == G10_y_r[10]) ? TAN45 : TAN135;
	end
	// G11
	if(G11_x_mag == 0) begin
		G11_dir_w = TAN90;
	end
	else if (G11_y_mag_ext < G11_x_2357) begin
		G11_dir_w = TAN0;
	end
	else if (G11_x_2_2357 < G11_y_mag_ext) begin
		G11_dir_w = TAN90;
	end
	else begin
		G11_dir_w = (G11_x_r[10] == G11_y_r[10]) ? TAN45 : TAN135;
	end
end

// NMS
always @(*) begin
	G00_sobel_nms = 0;
	G01_sobel_nms = 0;
	G10_sobel_nms = 0;
	G11_sobel_nms = 0;
	// G00
	case (G00_dir_r)
		TAN0: begin
			G00_sobel_nms = (G00_mag_curr < G01_mag_curr) ? 0 : G00_mag_curr;
		end
		TAN45: begin
			G00_sobel_nms = (G00_mag_curr < G11_mag_curr) ? 0 : G00_mag_curr;
		end
		TAN90: begin
			G00_sobel_nms = (G00_mag_curr < G10_mag_curr) ? 0 : G00_mag_curr;
		end
		TAN135: begin
			G00_sobel_nms = G00_mag_curr;
		end
	endcase
	// G10
	case (G10_dir_r)
		TAN0: begin
			G01_sobel_nms = (G10_mag_curr < G11_mag_curr) ? 0 : G10_mag_curr;
		end
		TAN45: begin
			G01_sobel_nms = G10_mag_curr;
		end
		TAN90: begin
			G01_sobel_nms = (G10_mag_curr < G00_mag_curr) ? 0 : G10_mag_curr;
		end
		TAN135: begin
			G01_sobel_nms = (G10_mag_curr < G01_mag_curr) ? 0 : G10_mag_curr;
		end
	endcase
	// G01
	case (G01_dir_r)
		TAN0: begin
			G10_sobel_nms = (G01_mag_curr < G00_mag_curr) ? 0 : G01_mag_curr;
		end
		TAN45: begin
			G10_sobel_nms = G01_mag_curr;
		end
		TAN90: begin
			G10_sobel_nms = (G01_mag_curr < G11_mag_curr) ? 0 : G01_mag_curr;
		end
		TAN135: begin
			G10_sobel_nms = (G01_mag_curr < G10_mag_curr) ? 0 : G01_mag_curr;
		end
	endcase
	// G11
	case (G11_dir_r)
		TAN0: begin
			G11_sobel_nms = (G11_mag_curr < G10_mag_curr) ? 0 : G11_mag_curr;
		end
		TAN45: begin
			G11_sobel_nms = (G11_mag_curr < G00_mag_curr) ? 0 : G11_mag_curr;
		end
		TAN90: begin
			G11_sobel_nms = (G11_mag_curr < G01_mag_curr) ? 0 : G11_mag_curr;
		end
		TAN135: begin
			G11_sobel_nms = G11_mag_curr;
		end
	endcase
end


// convolution sum reg
always @(*) begin
	// counter need to minus 1, because the counter already add 1
	// 1/16 -> not shifting, 1/8 -> shift 1, 1/4 -> shift 2
	for (i = 0;i<4 ;i = i + 1 ) begin
		conv_sum_w[i] = conv_sum_r[i];
	end
	if (curr_state == S_FETCH) begin
		for (i = 0;i<4 ;i = i + 1 ) begin
			conv_sum_w[i] = 0;
		end
	end
	else if (counter_r > 2 && counter_r < (channel_depth_r_shift2_plus2 + 1)) begin
		case (counter_r[1:0])
			2'd3: begin
				conv_sum_w[0] = (cms_sram_out_reg[0] + cms_sram_out_reg_shift_1[1]) + (cms_sram_out_reg[2] + conv_sum_r[0]);
				conv_sum_w[1] = (cms_sram_out_reg[1] +cms_sram_out_reg_shift_1[2]) + (cms_sram_out_reg[3] + conv_sum_r[1]);
				conv_sum_w[2] = conv_sum_r[2];
				conv_sum_w[3] = conv_sum_r[3];
			end
			2'd0: begin
				conv_sum_w[0] = (cms_sram_out_reg_shift_1[0] + cms_sram_out_reg_shift_2[1]) + (cms_sram_out_reg_shift_1[2] + conv_sum_r[0]);
				conv_sum_w[1] = (cms_sram_out_reg_shift_1[1] + cms_sram_out_reg_shift_2[2]) + (cms_sram_out_reg_shift_1[3] + conv_sum_r[1]);
				conv_sum_w[2] = (cms_sram_out_reg[0] + cms_sram_out_reg_shift_1[1])  + (cms_sram_out_reg[2] + conv_sum_r[2]);
				conv_sum_w[3] = (cms_sram_out_reg[1] +cms_sram_out_reg_shift_1[2]) + (cms_sram_out_reg[3] + conv_sum_r[3]);
			end
			2'd1: begin
				conv_sum_w[0] = (cms_sram_out_reg[0] + cms_sram_out_reg_shift_1[1]) + (cms_sram_out_reg[2] + conv_sum_r[0]);
				conv_sum_w[1] = (cms_sram_out_reg[1] +cms_sram_out_reg_shift_1[2]) + (cms_sram_out_reg[3] + conv_sum_r[1]);
				conv_sum_w[2] = (cms_sram_out_reg_shift_1[0] + cms_sram_out_reg_shift_2[1]) + (cms_sram_out_reg_shift_1[2] + conv_sum_r[2]);
				conv_sum_w[3] = (cms_sram_out_reg_shift_1[1] + cms_sram_out_reg_shift_2[2]) + (cms_sram_out_reg_shift_1[3] + conv_sum_r[3]);
			end
			2'd2: begin
				conv_sum_w[0] = conv_sum_r[0];
				conv_sum_w[1] = conv_sum_r[1];
				conv_sum_w[2] = (cms_sram_out_reg[0] + cms_sram_out_reg_shift_1[1]) + (cms_sram_out_reg[2] + conv_sum_r[2]);
				conv_sum_w[3] = (cms_sram_out_reg[1] +cms_sram_out_reg_shift_1[2]) + (cms_sram_out_reg[3] + conv_sum_r[3]);
			end
		endcase
	end
end

// select convolution sum
always @(*) begin
	case (counter_r)
		channel_depth_r_shift2_plus2 + 1: begin
			selected_conv_sum = conv_sum_r[0];
		end
		channel_depth_r_shift2_plus2 + 2: begin
			selected_conv_sum = conv_sum_r[1];
		end
		channel_depth_r_shift2_plus2 + 3: begin
			selected_conv_sum = conv_sum_r[2];
		end
		channel_depth_r_shift2_plus2 + 4: begin
			selected_conv_sum = conv_sum_r[3];
		end
		default: begin
			selected_conv_sum = 0;
		end 
	endcase
end

// median calculation in-between regs
// min, med, max
always @(*) begin
	for (i = 0;i<3 ;i = i + 1 ) begin
		first_box_out_group_min_w[i] = first_box_out_group_min_r[i];
		first_box_out_group_med_w[i] = first_box_out_group_med_r[i];
		first_box_out_group_max_w[i] = first_box_out_group_max_r[i];
		second_box_out_group_min_w[i] = second_box_out_group_min_r[i];
		second_box_out_group_med_w[i] = second_box_out_group_med_r[i];
		second_box_out_group_max_w[i] = second_box_out_group_max_r[i];
		third_box_out_group_min_w[i] = third_box_out_group_min_r[i];
		third_box_out_group_med_w[i] = third_box_out_group_med_r[i];
		third_box_out_group_max_w[i] = third_box_out_group_max_r[i];
		fourth_box_out_group_min_w[i] = fourth_box_out_group_min_r[i];
		fourth_box_out_group_med_w[i] = fourth_box_out_group_med_r[i];
		fourth_box_out_group_max_w[i] = fourth_box_out_group_max_r[i];
	end
	if (curr_state == S_FETCH) begin
		for (i = 0;i<3 ;i = i + 1 ) begin
			first_box_out_group_min_w[i] = 0;
			first_box_out_group_med_w[i] = 0;
			first_box_out_group_max_w[i] = 0;
			second_box_out_group_min_w[i] = 0;
			second_box_out_group_med_w[i] = 0;
			second_box_out_group_max_w[i] = 0;
			third_box_out_group_min_w[i] = 0;
			third_box_out_group_med_w[i] = 0;
			third_box_out_group_max_w[i] = 0;
			fourth_box_out_group_min_w[i] = 0;
			fourth_box_out_group_med_w[i] = 0;
			fourth_box_out_group_max_w[i] = 0;
		end
	end
	else begin
		case (counter_r[1:0])
			2'd3: begin
				// first box
				if ((cms_sram_out_reg[0] <= cms_sram_out_reg[1]) 
				&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					first_box_out_group_min_w[0] = cms_sram_out_reg[0];
					first_box_out_group_med_w[0] = cms_sram_out_reg[1];
					first_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
				&& (cms_sram_out_reg[1] <= cms_sram_out_reg[0])) begin
					first_box_out_group_min_w[0] = cms_sram_out_reg[2];
					first_box_out_group_med_w[0] = cms_sram_out_reg[1];
					first_box_out_group_max_w[0] = cms_sram_out_reg[0];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[0]) 
				&& (cms_sram_out_reg[0] <= cms_sram_out_reg[2])) begin
					first_box_out_group_min_w[0] = cms_sram_out_reg[1];
					first_box_out_group_med_w[0] = cms_sram_out_reg[0];
					first_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[0]) 
				&& (cms_sram_out_reg[0] <= cms_sram_out_reg[1])) begin
					first_box_out_group_min_w[0] = cms_sram_out_reg[2];
					first_box_out_group_med_w[0] = cms_sram_out_reg[0];
					first_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[0] <= cms_sram_out_reg[2]) 
				&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					first_box_out_group_min_w[0] = cms_sram_out_reg[0];
					first_box_out_group_med_w[0] = cms_sram_out_reg[2];
					first_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
					// && (cms_sram_out_reg[2] <= cms_sram_out_reg[0])) begin
					first_box_out_group_min_w[0] = cms_sram_out_reg[1];
					first_box_out_group_med_w[0] = cms_sram_out_reg[2];
					first_box_out_group_max_w[0] = cms_sram_out_reg[0];
				end
				// second box
				if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
				&& (cms_sram_out_reg[2] <= cms_sram_out_reg[3])) begin
					second_box_out_group_min_w[0] = cms_sram_out_reg[1];
					second_box_out_group_med_w[0] = cms_sram_out_reg[2];
					second_box_out_group_max_w[0] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					second_box_out_group_min_w[0] = cms_sram_out_reg[3];
					second_box_out_group_med_w[0] = cms_sram_out_reg[2];
					second_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[3])) begin
					second_box_out_group_min_w[0] = cms_sram_out_reg[2];
					second_box_out_group_med_w[0] = cms_sram_out_reg[1];
					second_box_out_group_max_w[0] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					second_box_out_group_min_w[0] = cms_sram_out_reg[3];
					second_box_out_group_med_w[0] = cms_sram_out_reg[1];
					second_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[3]) 
					&& (cms_sram_out_reg[3] <= cms_sram_out_reg[2])) begin
					second_box_out_group_min_w[0] = cms_sram_out_reg[1];
					second_box_out_group_med_w[0] = cms_sram_out_reg[3];
					second_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[3]) 
					// && (cms_sram_out_reg[3] <= cms_sram_out_reg[1])) begin
					second_box_out_group_min_w[0] = cms_sram_out_reg[2];
					second_box_out_group_med_w[0] = cms_sram_out_reg[3];
					second_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
			end
			2'd0: begin
				// first box
				if ((cms_sram_out_reg[0] <= cms_sram_out_reg[1]) 
				&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					first_box_out_group_min_w[1] = cms_sram_out_reg[0];
					first_box_out_group_med_w[1] = cms_sram_out_reg[1];
					first_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[0])) begin
					first_box_out_group_min_w[1] = cms_sram_out_reg[2];
					first_box_out_group_med_w[1] = cms_sram_out_reg[1];
					first_box_out_group_max_w[1] = cms_sram_out_reg[0];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[2])) begin
					first_box_out_group_min_w[1] = cms_sram_out_reg[1];
					first_box_out_group_med_w[1] = cms_sram_out_reg[0];
					first_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[1])) begin
					first_box_out_group_min_w[1] = cms_sram_out_reg[2];
					first_box_out_group_med_w[1] = cms_sram_out_reg[0];
					first_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[0] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					first_box_out_group_min_w[1] = cms_sram_out_reg[0];
					first_box_out_group_med_w[1] = cms_sram_out_reg[2];
					first_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
					// && (cms_sram_out_reg[2] <= cms_sram_out_reg[0])) begin
					first_box_out_group_min_w[1] = cms_sram_out_reg[1];
					first_box_out_group_med_w[1] = cms_sram_out_reg[2];
					first_box_out_group_max_w[1] = cms_sram_out_reg[0];
				end
				// second box
				if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
				&& (cms_sram_out_reg[2] <= cms_sram_out_reg[3])) begin
					second_box_out_group_min_w[1] = cms_sram_out_reg[1];
					second_box_out_group_med_w[1] = cms_sram_out_reg[2];
					second_box_out_group_max_w[1] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					second_box_out_group_min_w[1] = cms_sram_out_reg[3];
					second_box_out_group_med_w[1] = cms_sram_out_reg[2];
					second_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[3])) begin
					second_box_out_group_min_w[1] = cms_sram_out_reg[2];
					second_box_out_group_med_w[1] = cms_sram_out_reg[1];
					second_box_out_group_max_w[1] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					second_box_out_group_min_w[1] = cms_sram_out_reg[3];
					second_box_out_group_med_w[1] = cms_sram_out_reg[1];
					second_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[3]) 
					&& (cms_sram_out_reg[3] <= cms_sram_out_reg[2])) begin
					second_box_out_group_min_w[1] = cms_sram_out_reg[1];
					second_box_out_group_med_w[1] = cms_sram_out_reg[3];
					second_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[3]) 
					// && (cms_sram_out_reg[3] <= cms_sram_out_reg[1])) begin
					second_box_out_group_min_w[1] = cms_sram_out_reg[2];
					second_box_out_group_med_w[1] = cms_sram_out_reg[3];
					second_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
				// third box
				if ((cms_sram_out_reg[0] <= cms_sram_out_reg[1]) 
				&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					third_box_out_group_min_w[0] = cms_sram_out_reg[0];
					third_box_out_group_med_w[0] = cms_sram_out_reg[1];
					third_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[0])) begin
					third_box_out_group_min_w[0] = cms_sram_out_reg[2];
					third_box_out_group_med_w[0] = cms_sram_out_reg[1];
					third_box_out_group_max_w[0] = cms_sram_out_reg[0];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[2])) begin
					third_box_out_group_min_w[0] = cms_sram_out_reg[1];
					third_box_out_group_med_w[0] = cms_sram_out_reg[0];
					third_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[1])) begin
					third_box_out_group_min_w[0] = cms_sram_out_reg[2];
					third_box_out_group_med_w[0] = cms_sram_out_reg[0];
					third_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[0] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					third_box_out_group_min_w[0] = cms_sram_out_reg[0];
					third_box_out_group_med_w[0] = cms_sram_out_reg[2];
					third_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
					// && (cms_sram_out_reg[2] <= cms_sram_out_reg[0])) begin
					third_box_out_group_min_w[0] = cms_sram_out_reg[1];
					third_box_out_group_med_w[0] = cms_sram_out_reg[2];
					third_box_out_group_max_w[0] = cms_sram_out_reg[0];
				end
				// fourth box
				if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
				&& (cms_sram_out_reg[2] <= cms_sram_out_reg[3])) begin
					fourth_box_out_group_min_w[0] = cms_sram_out_reg[1];
					fourth_box_out_group_med_w[0] = cms_sram_out_reg[2];
					fourth_box_out_group_max_w[0] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					fourth_box_out_group_min_w[0] = cms_sram_out_reg[3];
					fourth_box_out_group_med_w[0] = cms_sram_out_reg[2];
					fourth_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[3])) begin
					fourth_box_out_group_min_w[0] = cms_sram_out_reg[2];
					fourth_box_out_group_med_w[0] = cms_sram_out_reg[1];
					fourth_box_out_group_max_w[0] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					fourth_box_out_group_min_w[0] = cms_sram_out_reg[3];
					fourth_box_out_group_med_w[0] = cms_sram_out_reg[1];
					fourth_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[3]) 
					&& (cms_sram_out_reg[3] <= cms_sram_out_reg[2])) begin
					fourth_box_out_group_min_w[0] = cms_sram_out_reg[1];
					fourth_box_out_group_med_w[0] = cms_sram_out_reg[3];
					fourth_box_out_group_max_w[0] = cms_sram_out_reg[2];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[3]) 
					// && (cms_sram_out_reg[3] <= cms_sram_out_reg[1])) begin
					fourth_box_out_group_min_w[0] = cms_sram_out_reg[2];
					fourth_box_out_group_med_w[0] = cms_sram_out_reg[3];
					fourth_box_out_group_max_w[0] = cms_sram_out_reg[1];
				end
			end
			2'd1: begin
				// first box
				if ((cms_sram_out_reg[0] <= cms_sram_out_reg[1]) 
				&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					first_box_out_group_min_w[2] = cms_sram_out_reg[0];
					first_box_out_group_med_w[2] = cms_sram_out_reg[1];
					first_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[0])) begin
					first_box_out_group_min_w[2] = cms_sram_out_reg[2];
					first_box_out_group_med_w[2] = cms_sram_out_reg[1];
					first_box_out_group_max_w[2] = cms_sram_out_reg[0];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[2])) begin
					first_box_out_group_min_w[2] = cms_sram_out_reg[1];
					first_box_out_group_med_w[2] = cms_sram_out_reg[0];
					first_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[1])) begin
					first_box_out_group_min_w[2] = cms_sram_out_reg[2];
					first_box_out_group_med_w[2] = cms_sram_out_reg[0];
					first_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[0] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					first_box_out_group_min_w[2] = cms_sram_out_reg[0];
					first_box_out_group_med_w[2] = cms_sram_out_reg[2];
					first_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
					// && (cms_sram_out_reg[2] <= cms_sram_out_reg[0])) begin
					first_box_out_group_min_w[2] = cms_sram_out_reg[1];
					first_box_out_group_med_w[2] = cms_sram_out_reg[2];
					first_box_out_group_max_w[2] = cms_sram_out_reg[0];
				end
				// second box
				if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
				&& (cms_sram_out_reg[2] <= cms_sram_out_reg[3])) begin
					second_box_out_group_min_w[2] = cms_sram_out_reg[1];
					second_box_out_group_med_w[2] = cms_sram_out_reg[2];
					second_box_out_group_max_w[2] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					second_box_out_group_min_w[2] = cms_sram_out_reg[3];
					second_box_out_group_med_w[2] = cms_sram_out_reg[2];
					second_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[3])) begin
					second_box_out_group_min_w[2] = cms_sram_out_reg[2];
					second_box_out_group_med_w[2] = cms_sram_out_reg[1];
					second_box_out_group_max_w[2] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					second_box_out_group_min_w[2] = cms_sram_out_reg[3];
					second_box_out_group_med_w[2] = cms_sram_out_reg[1];
					second_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[3]) 
					&& (cms_sram_out_reg[3] <= cms_sram_out_reg[2])) begin
					second_box_out_group_min_w[2] = cms_sram_out_reg[1];
					second_box_out_group_med_w[2] = cms_sram_out_reg[3];
					second_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[3]) 
					// && (cms_sram_out_reg[3] <= cms_sram_out_reg[1])) begin
					second_box_out_group_min_w[2] = cms_sram_out_reg[2];
					second_box_out_group_med_w[2] = cms_sram_out_reg[3];
					second_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
				// third box
				if ((cms_sram_out_reg[0] <= cms_sram_out_reg[1]) 
				&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					third_box_out_group_min_w[1] = cms_sram_out_reg[0];
					third_box_out_group_med_w[1] = cms_sram_out_reg[1];
					third_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[0])) begin
					third_box_out_group_min_w[1] = cms_sram_out_reg[2];
					third_box_out_group_med_w[1] = cms_sram_out_reg[1];
					third_box_out_group_max_w[1] = cms_sram_out_reg[0];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[2])) begin
					third_box_out_group_min_w[1] = cms_sram_out_reg[1];
					third_box_out_group_med_w[1] = cms_sram_out_reg[0];
					third_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[1])) begin
					third_box_out_group_min_w[1] = cms_sram_out_reg[2];
					third_box_out_group_med_w[1] = cms_sram_out_reg[0];
					third_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[0] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					third_box_out_group_min_w[1] = cms_sram_out_reg[0];
					third_box_out_group_med_w[1] = cms_sram_out_reg[2];
					third_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
					// && (cms_sram_out_reg[2] <= cms_sram_out_reg[0])) begin
					third_box_out_group_min_w[1] = cms_sram_out_reg[1];
					third_box_out_group_med_w[1] = cms_sram_out_reg[2];
					third_box_out_group_max_w[1] = cms_sram_out_reg[0];
				end
				// fourth box
				if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
				&& (cms_sram_out_reg[2] <= cms_sram_out_reg[3])) begin
					fourth_box_out_group_min_w[1] = cms_sram_out_reg[1];
					fourth_box_out_group_med_w[1] = cms_sram_out_reg[2];
					fourth_box_out_group_max_w[1] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					fourth_box_out_group_min_w[1] = cms_sram_out_reg[3];
					fourth_box_out_group_med_w[1] = cms_sram_out_reg[2];
					fourth_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[3])) begin
					fourth_box_out_group_min_w[1] = cms_sram_out_reg[2];
					fourth_box_out_group_med_w[1] = cms_sram_out_reg[1];
					fourth_box_out_group_max_w[1] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					fourth_box_out_group_min_w[1] = cms_sram_out_reg[3];
					fourth_box_out_group_med_w[1] = cms_sram_out_reg[1];
					fourth_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[3]) 
					&& (cms_sram_out_reg[3] <= cms_sram_out_reg[2])) begin
					fourth_box_out_group_min_w[1] = cms_sram_out_reg[1];
					fourth_box_out_group_med_w[1] = cms_sram_out_reg[3];
					fourth_box_out_group_max_w[1] = cms_sram_out_reg[2];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[3]) 
					// && (cms_sram_out_reg[3] <= cms_sram_out_reg[1])) begin
					fourth_box_out_group_min_w[1] = cms_sram_out_reg[2];
					fourth_box_out_group_med_w[1] = cms_sram_out_reg[3];
					fourth_box_out_group_max_w[1] = cms_sram_out_reg[1];
				end
			end
			2'd2: begin
				// third box
				if ((cms_sram_out_reg[0] <= cms_sram_out_reg[1]) 
				&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					third_box_out_group_min_w[2] = cms_sram_out_reg[0];
					third_box_out_group_med_w[2] = cms_sram_out_reg[1];
					third_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[0])) begin
					third_box_out_group_min_w[2] = cms_sram_out_reg[2];
					third_box_out_group_med_w[2] = cms_sram_out_reg[1];
					third_box_out_group_max_w[2] = cms_sram_out_reg[0];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[2])) begin
					third_box_out_group_min_w[2] = cms_sram_out_reg[1];
					third_box_out_group_med_w[2] = cms_sram_out_reg[0];
					third_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[0]) 
					&& (cms_sram_out_reg[0] <= cms_sram_out_reg[1])) begin
					third_box_out_group_min_w[2] = cms_sram_out_reg[2];
					third_box_out_group_med_w[2] = cms_sram_out_reg[0];
					third_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[0] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					third_box_out_group_min_w[2] = cms_sram_out_reg[0];
					third_box_out_group_med_w[2] = cms_sram_out_reg[2];
					third_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
					// && (cms_sram_out_reg[2] <= cms_sram_out_reg[0])) begin
					third_box_out_group_min_w[2] = cms_sram_out_reg[1];
					third_box_out_group_med_w[2] = cms_sram_out_reg[2];
					third_box_out_group_max_w[2] = cms_sram_out_reg[0];
				end
				// fourth box
				if ((cms_sram_out_reg[1] <= cms_sram_out_reg[2]) 
				&& (cms_sram_out_reg[2] <= cms_sram_out_reg[3])) begin
					fourth_box_out_group_min_w[2] = cms_sram_out_reg[1];
					fourth_box_out_group_med_w[2] = cms_sram_out_reg[2];
					fourth_box_out_group_max_w[2] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[2]) 
					&& (cms_sram_out_reg[2] <= cms_sram_out_reg[1])) begin
					fourth_box_out_group_min_w[2] = cms_sram_out_reg[3];
					fourth_box_out_group_med_w[2] = cms_sram_out_reg[2];
					fourth_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
				else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[3])) begin
					fourth_box_out_group_min_w[2] = cms_sram_out_reg[2];
					fourth_box_out_group_med_w[2] = cms_sram_out_reg[1];
					fourth_box_out_group_max_w[2] = cms_sram_out_reg[3];
				end
				else if ((cms_sram_out_reg[3] <= cms_sram_out_reg[1]) 
					&& (cms_sram_out_reg[1] <= cms_sram_out_reg[2])) begin
					fourth_box_out_group_min_w[2] = cms_sram_out_reg[3];
					fourth_box_out_group_med_w[2] = cms_sram_out_reg[1];
					fourth_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else if ((cms_sram_out_reg[1] <= cms_sram_out_reg[3]) 
					&& (cms_sram_out_reg[3] <= cms_sram_out_reg[2])) begin
					fourth_box_out_group_min_w[2] = cms_sram_out_reg[1];
					fourth_box_out_group_med_w[2] = cms_sram_out_reg[3];
					fourth_box_out_group_max_w[2] = cms_sram_out_reg[2];
				end
				else begin
					// should be equivalent
					// else if ((cms_sram_out_reg[2] <= cms_sram_out_reg[3]) 
					// && (cms_sram_out_reg[3] <= cms_sram_out_reg[1])) begin
					fourth_box_out_group_min_w[2] = cms_sram_out_reg[2];
					fourth_box_out_group_med_w[2] = cms_sram_out_reg[3];
					fourth_box_out_group_max_w[2] = cms_sram_out_reg[1];
				end
			end
		endcase
	end
end

// min_max, med_med, max_min
always @(*) begin
	if (curr_state == S_FETCH) begin
		first_box_out_group_min_max = 0;
		first_box_out_group_med_med = 0;
		first_box_out_group_max_min = 0;
		second_box_out_group_min_max = 0;
		second_box_out_group_med_med = 0;
		second_box_out_group_max_min = 0;
		third_box_out_group_min_max = 0;
		third_box_out_group_med_med = 0;
		third_box_out_group_max_min = 0;
		fourth_box_out_group_min_max = 0;
		fourth_box_out_group_med_med = 0;
		fourth_box_out_group_max_min = 0;
	end
	else begin
		// min_max
		// first box
		if ((first_box_out_group_min_r[0] >= first_box_out_group_min_r[1]) 
		&& (first_box_out_group_min_r[0] >= first_box_out_group_min_r[2])) begin
			first_box_out_group_min_max = first_box_out_group_min_r[0];
		end
		else if ((first_box_out_group_min_r[1] >= first_box_out_group_min_r[0])
		&& (first_box_out_group_min_r[1] >= first_box_out_group_min_r[2])) begin
			first_box_out_group_min_max = first_box_out_group_min_r[1];
		end
		else begin
			first_box_out_group_min_max = first_box_out_group_min_r[2];
		end
		// second box
		if ((second_box_out_group_min_r[0] >= second_box_out_group_min_r[1])
		&& (second_box_out_group_min_r[0] >= second_box_out_group_min_r[2])) begin
			second_box_out_group_min_max = second_box_out_group_min_r[0];
		end
		else if ((second_box_out_group_min_r[1] >= second_box_out_group_min_r[0])
		&& (second_box_out_group_min_r[1] >= second_box_out_group_min_r[2])) begin
			second_box_out_group_min_max = second_box_out_group_min_r[1];
		end
		else begin
			second_box_out_group_min_max = second_box_out_group_min_r[2];
		end
		// third box
		if ((third_box_out_group_min_r[0] >= third_box_out_group_min_r[1])
		&& (third_box_out_group_min_r[0] >= third_box_out_group_min_r[2])) begin
			third_box_out_group_min_max = third_box_out_group_min_r[0];
		end
		else if ((third_box_out_group_min_r[1] >= third_box_out_group_min_r[0])
		&& (third_box_out_group_min_r[1] >= third_box_out_group_min_r[2])) begin
			third_box_out_group_min_max = third_box_out_group_min_r[1];
		end
		else begin
			third_box_out_group_min_max = third_box_out_group_min_r[2];
		end
		// fourth box
		if ((fourth_box_out_group_min_r[0] >= fourth_box_out_group_min_r[1])
		&& (fourth_box_out_group_min_r[0] >= fourth_box_out_group_min_r[2])) begin
			fourth_box_out_group_min_max = fourth_box_out_group_min_r[0];
		end
		else if ((fourth_box_out_group_min_r[1] >= fourth_box_out_group_min_r[0])
		&& (fourth_box_out_group_min_r[1] >= fourth_box_out_group_min_r[2])) begin
			fourth_box_out_group_min_max = fourth_box_out_group_min_r[1];
		end
		else begin
			fourth_box_out_group_min_max = fourth_box_out_group_min_r[2];
		end
		// max_min
		// first box
		if ((first_box_out_group_max_r[0] <= first_box_out_group_max_r[1])
		&& (first_box_out_group_max_r[0] <= first_box_out_group_max_r[2])) begin
			first_box_out_group_max_min = first_box_out_group_max_r[0];
		end
		else if ((first_box_out_group_max_r[1] <= first_box_out_group_max_r[0])
		&& (first_box_out_group_max_r[1] <= first_box_out_group_max_r[2])) begin
			first_box_out_group_max_min = first_box_out_group_max_r[1];
		end
		else begin
			first_box_out_group_max_min = first_box_out_group_max_r[2];
		end
		// second box
		if ((second_box_out_group_max_r[0] <= second_box_out_group_max_r[1])
		&& (second_box_out_group_max_r[0] <= second_box_out_group_max_r[2])) begin
			second_box_out_group_max_min = second_box_out_group_max_r[0];
		end
		else if ((second_box_out_group_max_r[1] <= second_box_out_group_max_r[0])
		&& (second_box_out_group_max_r[1] <= second_box_out_group_max_r[2])) begin
			second_box_out_group_max_min = second_box_out_group_max_r[1];
		end
		else begin
			second_box_out_group_max_min = second_box_out_group_max_r[2];
		end
		// third box
		if ((third_box_out_group_max_r[0] <= third_box_out_group_max_r[1])
		&& (third_box_out_group_max_r[0] <= third_box_out_group_max_r[2])) begin
			third_box_out_group_max_min = third_box_out_group_max_r[0];
		end
		else if ((third_box_out_group_max_r[1] <= third_box_out_group_max_r[0])
		&& (third_box_out_group_max_r[1] <= third_box_out_group_max_r[2])) begin
			third_box_out_group_max_min = third_box_out_group_max_r[1];
		end
		else begin
			third_box_out_group_max_min = third_box_out_group_max_r[2];
		end
		// fourth box
		if ((fourth_box_out_group_max_r[0] <= fourth_box_out_group_max_r[1])
		&& (fourth_box_out_group_max_r[0] <= fourth_box_out_group_max_r[2])) begin
			fourth_box_out_group_max_min = fourth_box_out_group_max_r[0];
		end
		else if ((fourth_box_out_group_max_r[1] <= fourth_box_out_group_max_r[0])
		&& (fourth_box_out_group_max_r[1] <= fourth_box_out_group_max_r[2])) begin
			fourth_box_out_group_max_min = fourth_box_out_group_max_r[1];
		end
		else begin
			fourth_box_out_group_max_min = fourth_box_out_group_max_r[2];
		end
		// med_med
		// first box
		if (((first_box_out_group_med_r[0] >= first_box_out_group_med_r[1]) && (first_box_out_group_med_r[0] <= first_box_out_group_med_r[2]))
		|| ((first_box_out_group_med_r[0] >= first_box_out_group_med_r[2]) && (first_box_out_group_med_r[0] <= first_box_out_group_med_r[1]))) begin
			first_box_out_group_med_med = first_box_out_group_med_r[0];
		end
		else if (((first_box_out_group_med_r[1] >= first_box_out_group_med_r[2]) && (first_box_out_group_med_r[1] <= first_box_out_group_med_r[0]))
		|| ((first_box_out_group_med_r[1] >= first_box_out_group_med_r[0]) && (first_box_out_group_med_r[1] <= first_box_out_group_med_r[2]))) begin
			first_box_out_group_med_med = first_box_out_group_med_r[1];
		end
		else begin
			first_box_out_group_med_med = first_box_out_group_med_r[2];
		end
		// second box
		if (((second_box_out_group_med_r[0] >= second_box_out_group_med_r[1]) && (second_box_out_group_med_r[0] <= second_box_out_group_med_r[2]))
		|| ((second_box_out_group_med_r[0] >= second_box_out_group_med_r[2]) && (second_box_out_group_med_r[0] <= second_box_out_group_med_r[1]))) begin
			second_box_out_group_med_med = second_box_out_group_med_r[0];
		end
		else if (((second_box_out_group_med_r[1] >= second_box_out_group_med_r[2]) && (second_box_out_group_med_r[1] <= second_box_out_group_med_r[0]))
		|| ((second_box_out_group_med_r[1] >= second_box_out_group_med_r[0]) && (second_box_out_group_med_r[1] <= second_box_out_group_med_r[2]))) begin
			second_box_out_group_med_med = second_box_out_group_med_r[1];
		end
		else begin
			second_box_out_group_med_med = second_box_out_group_med_r[2];
		end
		// third box
		if (((third_box_out_group_med_r[0] >= third_box_out_group_med_r[1]) && (third_box_out_group_med_r[0] <= third_box_out_group_med_r[2]))
		|| ((third_box_out_group_med_r[0] >= third_box_out_group_med_r[2]) && (third_box_out_group_med_r[0] <= third_box_out_group_med_r[1]))) begin
			third_box_out_group_med_med = third_box_out_group_med_r[0];
		end
		else if (((third_box_out_group_med_r[1] >= third_box_out_group_med_r[2]) && (third_box_out_group_med_r[1] <= third_box_out_group_med_r[0]))
		|| ((third_box_out_group_med_r[1] >= third_box_out_group_med_r[0]) && (third_box_out_group_med_r[1] <= third_box_out_group_med_r[2]))) begin
			third_box_out_group_med_med = third_box_out_group_med_r[1];
		end
		else begin
			third_box_out_group_med_med = third_box_out_group_med_r[2];
		end
		// fourth box
		if (((fourth_box_out_group_med_r[0] >= fourth_box_out_group_med_r[1]) && (fourth_box_out_group_med_r[0] <= fourth_box_out_group_med_r[2]))
		|| ((fourth_box_out_group_med_r[0] >= fourth_box_out_group_med_r[2]) && (fourth_box_out_group_med_r[0] <= fourth_box_out_group_med_r[1]))) begin
			fourth_box_out_group_med_med = fourth_box_out_group_med_r[0];
		end
		else if (((fourth_box_out_group_med_r[1] >= fourth_box_out_group_med_r[2]) && (fourth_box_out_group_med_r[1] <= fourth_box_out_group_med_r[0]))
		|| ((fourth_box_out_group_med_r[1] >= fourth_box_out_group_med_r[0]) && (fourth_box_out_group_med_r[1] <= fourth_box_out_group_med_r[2]))) begin
			fourth_box_out_group_med_med = fourth_box_out_group_med_r[1];
		end
		else begin
			fourth_box_out_group_med_med = fourth_box_out_group_med_r[2];
		end
	end
end

// total median
always @(*) begin
	if (curr_state == S_FETCH) begin
		first_box_out_group_total_med_w = 0;
		second_box_out_group_total_med_w = 0;
		third_box_out_group_total_med_w = 0;
		fourth_box_out_group_total_med_w = 0;
	end
	else begin
		first_box_out_group_total_med_w = first_box_out_group_total_med_r;
		second_box_out_group_total_med_w = second_box_out_group_total_med_r;
		third_box_out_group_total_med_w = third_box_out_group_total_med_r;
		fourth_box_out_group_total_med_w = fourth_box_out_group_total_med_r;
		case (counter_r[1:0])
			2'd2: begin
				// first box
				if (((first_box_out_group_min_max <= first_box_out_group_med_med) && (first_box_out_group_med_med <= first_box_out_group_max_min))
				|| ((first_box_out_group_min_max >= first_box_out_group_med_med) && (first_box_out_group_med_med >= first_box_out_group_max_min))) begin
					first_box_out_group_total_med_w = first_box_out_group_med_med;
				end
				else if (((first_box_out_group_med_med <= first_box_out_group_min_max) && (first_box_out_group_min_max <= first_box_out_group_max_min))
				|| ((first_box_out_group_med_med >= first_box_out_group_min_max) && (first_box_out_group_min_max >= first_box_out_group_max_min))) begin
					first_box_out_group_total_med_w = first_box_out_group_min_max;
				end
				else begin
					first_box_out_group_total_med_w = first_box_out_group_max_min;
				end
				// second box
				if (((second_box_out_group_min_max <= second_box_out_group_med_med) && (second_box_out_group_med_med <= second_box_out_group_max_min))
				|| ((second_box_out_group_min_max >= second_box_out_group_med_med) && (second_box_out_group_med_med >= second_box_out_group_max_min))) begin
					second_box_out_group_total_med_w = second_box_out_group_med_med;
				end
				else if (((second_box_out_group_med_med <= second_box_out_group_min_max) && (second_box_out_group_min_max <= second_box_out_group_max_min))
					|| ((second_box_out_group_med_med >= second_box_out_group_min_max) && (second_box_out_group_min_max >= second_box_out_group_max_min))) begin
					second_box_out_group_total_med_w = second_box_out_group_min_max;
				end
				else begin
					second_box_out_group_total_med_w = second_box_out_group_max_min;
				end
			end
			2'd0: begin
				// third box
				if (((third_box_out_group_min_max <= third_box_out_group_med_med) && (third_box_out_group_med_med <= third_box_out_group_max_min))
				|| ((third_box_out_group_min_max >= third_box_out_group_med_med) && (third_box_out_group_med_med >= third_box_out_group_max_min))) begin
					third_box_out_group_total_med_w = third_box_out_group_med_med;
				end
				else if (((third_box_out_group_med_med <= third_box_out_group_min_max) && (third_box_out_group_min_max <= third_box_out_group_max_min))
					|| ((third_box_out_group_med_med >= third_box_out_group_min_max) && (third_box_out_group_min_max >= third_box_out_group_max_min))) begin
					third_box_out_group_total_med_w = third_box_out_group_min_max;
				end
				else begin
					third_box_out_group_total_med_w = third_box_out_group_max_min;
				end
				// fourth box
				if (((fourth_box_out_group_min_max <= fourth_box_out_group_med_med) && (fourth_box_out_group_med_med <= fourth_box_out_group_max_min))
				|| ((fourth_box_out_group_min_max >= fourth_box_out_group_med_med) && (fourth_box_out_group_med_med >= fourth_box_out_group_max_min))) begin
					fourth_box_out_group_total_med_w = fourth_box_out_group_med_med;
				end
				else if (((fourth_box_out_group_med_med <= fourth_box_out_group_min_max) && (fourth_box_out_group_min_max <= fourth_box_out_group_max_min))
					|| ((fourth_box_out_group_med_med >= fourth_box_out_group_min_max) && (fourth_box_out_group_min_max >= fourth_box_out_group_max_min))) begin
						fourth_box_out_group_total_med_w = fourth_box_out_group_min_max;
				end
				else begin
					fourth_box_out_group_total_med_w = fourth_box_out_group_max_min;
				end
			end
		endcase
	end
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		for (i=0;i<16;i=i+1) begin
			sobel_register_files_r[i] <= 0;
			sobel_register_files_for_4_cycle_r[i] <= 0;
		end
		for (i=0;i<3;i=i+1) begin
			first_box_out_group_min_r[i] <= 0;
			first_box_out_group_med_r[i] <= 0;
			first_box_out_group_max_r[i] <= 0;
			second_box_out_group_min_r[i] <= 0;
			second_box_out_group_med_r[i] <= 0;
			second_box_out_group_max_r[i] <= 0;
			third_box_out_group_min_r[i] <= 0;
			third_box_out_group_med_r[i] <= 0;
			third_box_out_group_max_r[i] <= 0;
			fourth_box_out_group_min_r[i] <= 0;
			fourth_box_out_group_med_r[i] <= 0;
			fourth_box_out_group_max_r[i] <= 0;
		end
		for (i = 0;i<4;i=i+1) begin
			sram_data_out_r[i] <= 0;
			sram_addr_r[i] <= 0;
			sram_wen_r[i] <= 1;
			cms_sram_sel_with_delay[i] <= 0;
			cms_sram_sel_with_delay_2[i] <= 0;
			conv_sum_r[i] <= 0;
		end
		curr_state <= S_IDLE;
		counter_r <= 0;
		o_in_ready_r <= 0;
		o_out_data_r <= 0;
		o_out_valid_r <= 0;
		sram_data_in_r <= 0;
		origin_row_r <= 0;
		origin_col_r <= 0;
		channel_depth_r <= 6'd32;
		op_mode_r <= 0;
		sram_sel_with_delay <= 0;
		sram_sel_with_delay_2 <= 0;
		first_box_out_group_total_med_r <= 0;
		second_box_out_group_total_med_r <= 0;
		third_box_out_group_total_med_r <= 0;
		fourth_box_out_group_total_med_r <= 0;
		o_op_ready_r <= 0;
		G00_x_r <= 0;
		G00_y_r <= 0;
		G01_x_r <= 0;
		G01_y_r <= 0;
		G10_x_r <= 0;
		G10_y_r <= 0;
		G11_x_r <= 0;
		G11_y_r <= 0;
		G00_mag_curr <= 0;
		G01_mag_curr <= 0;
		G10_mag_curr <= 0;
		G11_mag_curr <= 0;
		G00_dir_r <= 0;
		G01_dir_r <= 0;
		G10_dir_r <= 0;
		G11_dir_r <= 0;
	end
	else begin
		for (i = 0;i <16;i=i+1 ) begin
			sobel_register_files_r[i] <= sobel_register_files_w[i];
			sobel_register_files_for_4_cycle_r[i] <= sobel_register_files_for_4_cycle_w[i];
		end
		for (i = 0;i <3;i=i+1 ) begin
			first_box_out_group_min_r[i] <= first_box_out_group_min_w[i];
			first_box_out_group_med_r[i] <= first_box_out_group_med_w[i];
			first_box_out_group_max_r[i] <= first_box_out_group_max_w[i];
			second_box_out_group_min_r[i] <= second_box_out_group_min_w[i];
			second_box_out_group_med_r[i] <= second_box_out_group_med_w[i];
			second_box_out_group_max_r[i] <= second_box_out_group_max_w[i];
			third_box_out_group_min_r[i] <= third_box_out_group_min_w[i];
			third_box_out_group_med_r[i] <= third_box_out_group_med_w[i];
			third_box_out_group_max_r[i] <= third_box_out_group_max_w[i];
			fourth_box_out_group_min_r[i] <= fourth_box_out_group_min_w[i];
			fourth_box_out_group_med_r[i] <= fourth_box_out_group_med_w[i];
			fourth_box_out_group_max_r[i] <= fourth_box_out_group_max_w[i];
		end
		for (i = 0;i <4;i=i+1 ) begin
			conv_sum_r[i] <= conv_sum_w[i];
			cms_sram_sel_with_delay[i] <= cms_address_and_sram[i][1:0];
			cms_sram_sel_with_delay_2[i] <= cms_sram_sel_with_delay[i];
			sram_data_out_r[i] <= sram_data_out[i];
			sram_addr_r[i] <= sram_addr_w[i];
			sram_wen_r[i] <= sram_wen[i];
		end
		curr_state <= next_state;
		counter_r <= counter_w;
		o_out_valid_r <= (((curr_state == S_DISPLAY) && (counter_r > 3))
		|| ((curr_state == S_MED) && (counter_r > 11'd6))
		|| ((curr_state == S_CONV) && (counter_r > channel_depth_r_shift2_plus2))
		|| (curr_state == S_SOB) && (counter_r > 11'd9));
		origin_row_r <= origin_row_w;
		origin_col_r <= origin_col_w;
		channel_depth_r <= channel_depth_w;
		op_mode_r <= op_mode_w;
		sram_sel_with_delay <= display_address_and_sram[1:0];
		sram_sel_with_delay_2 <= sram_sel_with_delay;
		first_box_out_group_total_med_r <= first_box_out_group_total_med_w;
		second_box_out_group_total_med_r <= second_box_out_group_total_med_w;
		third_box_out_group_total_med_r <= third_box_out_group_total_med_w;
		fourth_box_out_group_total_med_r <= fourth_box_out_group_total_med_w;
		sram_data_in_r <= sram_data_in_w;
		o_in_ready_r <= 1;
		o_out_data_r <= o_out_data_w;
		o_op_ready_r <= o_op_ready_w;
		G00_x_r <= G00_x_w;
		G00_y_r <= G00_y_w;
		G01_x_r <= G01_x_w;
		G01_y_r <= G01_y_w;
		G10_x_r <= G10_x_w;
		G10_y_r <= G10_y_w;
		G11_x_r <= G11_x_w;
		G11_y_r <= G11_y_w;
		G00_mag_curr <= G00_mag_next;
		G01_mag_curr <= G01_mag_next;
		G10_mag_curr <= G10_mag_next;
		G11_mag_curr <= G11_mag_next;
		G00_dir_r <= G00_dir_w;
		G01_dir_r <= G01_dir_w;
		G10_dir_r <= G10_dir_w;
		G11_dir_r <= G11_dir_w;
	end
end


endmodule
