`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;

// ----------------------------------------------------------------------------
// integer
// ----------------------------------------------------------------------------
integer index;

// ----------------------------------------------------------------------------
// parameter
// ----------------------------------------------------------------------------
localparam S_IDLE = 1'd0;
localparam S_FUNC = 1'd1;
localparam DES_PROCESSING = 1'd0;
localparam DES_OUT_READY = 1'd1;
localparam F1 = 3'd1;
localparam F2 = 3'd2;
localparam F3 = 3'd3;
localparam F4 = 3'd4;
localparam F5 = 3'd5;

// ----------------------------------------------------------------------------
// reg, wire declaration
// ----------------------------------------------------------------------------
reg [7:0] iot_in_r, iot_in_w;
reg [127:0] iot_127_data_r, iot_127_data_w;
reg busy_r, busy_w;
reg valid_r, valid_w;
reg [3:0] counter_r, counter_w;
wire [7:0] iot_in_ii1_xor;
wire [7:0] iot_F5_out;
wire [2:0] iot_F3_out;
wire [3:0] iot_F3_temp [0:10];
reg iot_in_7th_xor_input;
reg state_r, state_w;
reg des_state_r, des_state_w;
wire [63:0] mainkey;
wire [55:0] cipherkey;
wire [55:0] shiftedcipherkey [0:15];
wire [47:0] subkey [0:15];
wire [63:0] plaintext;
wire [63:0] plaintext_after_ip;
wire [31:0] L;
wire [31:0] R;
wire [31:0] R_after_F;
wire [31:0] L_after_Xor;
wire [63:0] FinalP_out;
reg [47:0] key_in_use;

// ----------------------------------------------------------------------------
// wire assignment
// ----------------------------------------------------------------------------
assign busy = busy_r;
assign valid = valid_r;
assign iot_out = iot_127_data_r;

// F1, F2
assign mainkey = iot_127_data_r[127:64];
PC1 pc1(.in(mainkey), .out(cipherkey));
CircularShiftLeft1 key1_csl1u(.in(cipherkey[27:0]), .out(shiftedcipherkey[0][27:0]));
CircularShiftLeft1 key1_csl1d(.in(cipherkey[55:28]), .out(shiftedcipherkey[0][55:28]));
PC2 pc2_1(.in(shiftedcipherkey[0]), .out(subkey[0]));
CircularShiftLeft1 key2_csl1u(.in(shiftedcipherkey[0][27:0]), .out(shiftedcipherkey[1][27:0]));
CircularShiftLeft1 key2_csl1d(.in(shiftedcipherkey[0][55:28]), .out(shiftedcipherkey[1][55:28]));
PC2 pc2_2(.in(shiftedcipherkey[1]), .out(subkey[1]));
CircularShiftLeft2 key3_csl2u(.in(shiftedcipherkey[1][27:0]), .out(shiftedcipherkey[2][27:0]));
CircularShiftLeft2 key3_csl2d(.in(shiftedcipherkey[1][55:28]), .out(shiftedcipherkey[2][55:28]));
PC2 pc2_3(.in(shiftedcipherkey[2]), .out(subkey[2]));
CircularShiftLeft2 key4_csl2u(.in(shiftedcipherkey[2][27:0]), .out(shiftedcipherkey[3][27:0]));
CircularShiftLeft2 key4_csl2d(.in(shiftedcipherkey[2][55:28]), .out(shiftedcipherkey[3][55:28]));
PC2 pc2_4(.in(shiftedcipherkey[3]), .out(subkey[3]));
CircularShiftLeft2 key5_csl2u(.in(shiftedcipherkey[3][27:0]), .out(shiftedcipherkey[4][27:0]));
CircularShiftLeft2 key5_csl2d(.in(shiftedcipherkey[3][55:28]), .out(shiftedcipherkey[4][55:28]));
PC2 pc2_5(.in(shiftedcipherkey[4]), .out(subkey[4]));
CircularShiftLeft2 key6_csl2u(.in(shiftedcipherkey[4][27:0]), .out(shiftedcipherkey[5][27:0]));
CircularShiftLeft2 key6_csl2d(.in(shiftedcipherkey[4][55:28]), .out(shiftedcipherkey[5][55:28]));
PC2 pc2_6(.in(shiftedcipherkey[5]), .out(subkey[5]));
CircularShiftLeft2 key7_csl2u(.in(shiftedcipherkey[5][27:0]), .out(shiftedcipherkey[6][27:0]));
CircularShiftLeft2 key7_csl2d(.in(shiftedcipherkey[5][55:28]), .out(shiftedcipherkey[6][55:28]));
PC2 pc2_7(.in(shiftedcipherkey[6]), .out(subkey[6]));
CircularShiftLeft2 key8_csl2u(.in(shiftedcipherkey[6][27:0]), .out(shiftedcipherkey[7][27:0]));
CircularShiftLeft2 key8_csl2d(.in(shiftedcipherkey[6][55:28]), .out(shiftedcipherkey[7][55:28]));
PC2 pc2_8(.in(shiftedcipherkey[7]), .out(subkey[7]));
CircularShiftLeft1 key9_csl1u(.in(shiftedcipherkey[7][27:0]), .out(shiftedcipherkey[8][27:0]));
CircularShiftLeft1 key9_csl1d(.in(shiftedcipherkey[7][55:28]), .out(shiftedcipherkey[8][55:28]));
PC2 pc2_9(.in(shiftedcipherkey[8]), .out(subkey[8]));
CircularShiftLeft2 key10_csl2u(.in(shiftedcipherkey[8][27:0]), .out(shiftedcipherkey[9][27:0]));
CircularShiftLeft2 key10_csl2d(.in(shiftedcipherkey[8][55:28]), .out(shiftedcipherkey[9][55:28]));
PC2 pc2_10(.in(shiftedcipherkey[9]), .out(subkey[9]));
CircularShiftLeft2 key11_csl2u(.in(shiftedcipherkey[9][27:0]), .out(shiftedcipherkey[10][27:0]));
CircularShiftLeft2 key11_csl2d(.in(shiftedcipherkey[9][55:28]), .out(shiftedcipherkey[10][55:28]));
PC2 pc2_11(.in(shiftedcipherkey[10]), .out(subkey[10]));
CircularShiftLeft2 key12_csl2u(.in(shiftedcipherkey[10][27:0]), .out(shiftedcipherkey[11][27:0]));
CircularShiftLeft2 key12_csl2d(.in(shiftedcipherkey[10][55:28]), .out(shiftedcipherkey[11][55:28]));
PC2 pc2_12(.in(shiftedcipherkey[11]), .out(subkey[11]));
CircularShiftLeft2 key13_csl2u(.in(shiftedcipherkey[11][27:0]), .out(shiftedcipherkey[12][27:0]));
CircularShiftLeft2 key13_csl2d(.in(shiftedcipherkey[11][55:28]), .out(shiftedcipherkey[12][55:28]));
PC2 pc2_13(.in(shiftedcipherkey[12]), .out(subkey[12]));
CircularShiftLeft2 key14_csl2u(.in(shiftedcipherkey[12][27:0]), .out(shiftedcipherkey[13][27:0]));
CircularShiftLeft2 key14_csl2d(.in(shiftedcipherkey[12][55:28]), .out(shiftedcipherkey[13][55:28]));
PC2 pc2_14(.in(shiftedcipherkey[13]), .out(subkey[13]));
CircularShiftLeft2 key15_csl2u(.in(shiftedcipherkey[13][27:0]), .out(shiftedcipherkey[14][27:0]));
CircularShiftLeft2 key15_csl2d(.in(shiftedcipherkey[13][55:28]), .out(shiftedcipherkey[14][55:28]));
PC2 pc2_15(.in(shiftedcipherkey[14]), .out(subkey[14]));
CircularShiftLeft1 key16_csl1u(.in(shiftedcipherkey[14][27:0]), .out(shiftedcipherkey[15][27:0]));
CircularShiftLeft1 key16_csl1d(.in(shiftedcipherkey[14][55:28]), .out(shiftedcipherkey[15][55:28]));
PC2 pc2_16(.in(shiftedcipherkey[15]), .out(subkey[15]));

assign plaintext = (counter_r==0) ? iot_127_data_r[63:0] : {iot_127_data_r[31:0], iot_127_data_r[63:32]};
InitialP ip(.in(plaintext), .out(plaintext_after_ip));

assign R = (counter_r == 0) ? plaintext_after_ip[31:0] : plaintext[31:0];
assign L = (counter_r == 0) ? plaintext_after_ip[63:32] : plaintext[63:32];
F f1(.in(R), .key(key_in_use), .out(R_after_F));
assign L_after_Xor = L ^ R_after_F;

FinalP fp(.in({L_after_Xor, R}), .out(FinalP_out));

// F3
assign iot_F3_temp[0] = (counter_r == 0) ? {3'd0, iot_in_r[7]} : {iot_127_data_r[5:3], iot_in_r[7]};
assign iot_F3_temp[1] = {(iot_F3_temp[0][3]) ? (3'b011 ^ iot_F3_temp[0][2:0]) : iot_F3_temp[0][2:0], iot_in_r[6]};
assign iot_F3_temp[2] = {(iot_F3_temp[1][3]) ? (3'b011 ^ iot_F3_temp[1][2:0]) : iot_F3_temp[1][2:0], iot_in_r[5]};
assign iot_F3_temp[3] = {(iot_F3_temp[2][3]) ? (3'b011 ^ iot_F3_temp[2][2:0]) : iot_F3_temp[2][2:0], iot_in_r[4]};
assign iot_F3_temp[4] = {(iot_F3_temp[3][3]) ? (3'b011 ^ iot_F3_temp[3][2:0]) : iot_F3_temp[3][2:0], iot_in_r[3]};
assign iot_F3_temp[5] = {(iot_F3_temp[4][3]) ? (3'b011 ^ iot_F3_temp[4][2:0]) : iot_F3_temp[4][2:0], iot_in_r[2]};
assign iot_F3_temp[6] = {(iot_F3_temp[5][3]) ? (3'b011 ^ iot_F3_temp[5][2:0]) : iot_F3_temp[5][2:0], iot_in_r[1]};
assign iot_F3_temp[7] = {(iot_F3_temp[6][3]) ? (3'b011 ^ iot_F3_temp[6][2:0]) : iot_F3_temp[6][2:0], iot_in_r[0]};
assign iot_F3_temp[8] = {(iot_F3_temp[7][3]) ? (3'b011 ^ iot_F3_temp[7][2:0]) : iot_F3_temp[7][2:0], 1'b0};
assign iot_F3_temp[9] = {(iot_F3_temp[8][3]) ? (3'b011 ^ iot_F3_temp[8][2:0]) : iot_F3_temp[8][2:0], 1'b0};
assign iot_F3_temp[10] = {(iot_F3_temp[9][3]) ? (3'b011 ^ iot_F3_temp[9][2:0]) : iot_F3_temp[9][2:0], 1'b0};
assign iot_F3_out = (iot_F3_temp[10][3]) ? (3'b011 ^ iot_F3_temp[10][2:0]): iot_F3_temp[10][2:0];

// F4, F5
assign iot_in_ii1_xor[7] = iot_in_r[7] ^ iot_in_7th_xor_input;
generate
    genvar i;
    for (i = 0; i < 7; i = i + 1) begin: xor_gen_block
        assign iot_in_ii1_xor[i] = iot_in_r[i] ^ iot_in_r[i+1];
    end
endgenerate
assign iot_F5_out[7] = iot_in_ii1_xor[7];
assign iot_F5_out[6] = iot_in_ii1_xor[7] ^ iot_in_r[6];
assign iot_F5_out[5] = iot_F5_out[6] ^ iot_in_r[5];
assign iot_F5_out[4] = iot_F5_out[5] ^ iot_in_r[4];
assign iot_F5_out[3] = iot_F5_out[4] ^ iot_in_r[3];
assign iot_F5_out[2] = iot_F5_out[3] ^ iot_in_r[2];
assign iot_F5_out[1] = iot_F5_out[2] ^ iot_in_r[1];
assign iot_F5_out[0] = iot_F5_out[1] ^ iot_in_r[0];

// ----------------------------------------------------------------------------
// combinational logic
// ----------------------------------------------------------------------------


// FSM
always @(*) begin
    state_w = state_r;
    case (state_r)
        S_IDLE: begin
            state_w = in_en ? S_FUNC : S_IDLE;
        end
		// S_FUNC: begin
		// 	state_w = des_state_r ? S_IDLE : S_FUNC;
		// end
    endcase
end

// key_in_use
always @(*) begin
	key_in_use = 48'd0;
	case (fn_sel)
		F1:begin
			case (counter_r)
				4'd0: key_in_use = subkey[0];
				4'd1: key_in_use = subkey[1];
				4'd2: key_in_use = subkey[2];
				4'd3: key_in_use = subkey[3];
				4'd4: key_in_use = subkey[4];
				4'd5: key_in_use = subkey[5];
				4'd6: key_in_use = subkey[6];
				4'd7: key_in_use = subkey[7];
				4'd8: key_in_use = subkey[8];
				4'd9: key_in_use = subkey[9];
				4'd10: key_in_use = subkey[10];
				4'd11: key_in_use = subkey[11];
				4'd12: key_in_use = subkey[12];
				4'd13: key_in_use = subkey[13];
				4'd14: key_in_use = subkey[14];
				4'd15: key_in_use = subkey[15];
			endcase
		end
		F2:begin
			case (counter_r)
				4'd0: key_in_use = subkey[15];
				4'd1: key_in_use = subkey[14];
				4'd2: key_in_use = subkey[13];
				4'd3: key_in_use = subkey[12];
				4'd4: key_in_use = subkey[11];
				4'd5: key_in_use = subkey[10];
				4'd6: key_in_use = subkey[9];
				4'd7: key_in_use = subkey[8];
				4'd8: key_in_use = subkey[7];
				4'd9: key_in_use = subkey[6];
				4'd10: key_in_use = subkey[5];
				4'd11: key_in_use = subkey[4];
				4'd12: key_in_use = subkey[3];
				4'd13: key_in_use = subkey[2];
				4'd14: key_in_use = subkey[1];
				4'd15: key_in_use = subkey[0];
			endcase
		end
	endcase
end

// busy_w
always @(*) begin
	busy_w = 0;
	if ((~fn_sel[2]) & (~(fn_sel[1]&fn_sel[0]))) begin
		if (state_r == S_FUNC) begin
			if (((counter_r > 12) && (des_state_r == DES_PROCESSING)) || ((counter_r < 13) && (des_state_r == DES_OUT_READY))) begin
				busy_w = 1;
			end
		end
	end
end

// iot_in_w
always @(*) begin
    iot_in_w = iot_in;
end

// valid_w
always @(*) begin
    valid_w = 0;
    if (state_r == S_FUNC) begin
        case (fn_sel)
            F1, F2:begin
                if ((des_state_r == DES_OUT_READY) && (counter_r == 15)) begin
                    valid_w = 1;
                end
            end
            F3, F4, F5:begin
                if (counter_r == 15) begin
                    valid_w = 1;
				end
            end
        endcase
    end
end

// iot_in_7th_xor_input
always @(*) begin
	iot_in_7th_xor_input = 0;
	if (state_r == S_FUNC) begin
		case (fn_sel)
			F4, F5:begin
				iot_in_7th_xor_input = (counter_r == 0) ? 0 : des_state_r;
			end
		endcase
	end
end

// iot_127_data_w
always @(*) begin
	iot_127_data_w = 0;
	if (state_r == S_FUNC) begin
		iot_127_data_w = iot_127_data_r;
		case (fn_sel)
			F1, F2:begin
				if (des_state_r == DES_OUT_READY) begin
					iot_127_data_w[63:0] = {L_after_Xor, R};
					if(counter_r == 15) begin
						iot_127_data_w[63:0] = FinalP_out;
					end
				end
				else begin
					case (counter_r)
						0:begin
							iot_127_data_w[127:120] = iot_in_r[7:0];
						end
						1:begin
							iot_127_data_w[119:112] = iot_in_r[7:0];
						end
						2:begin
							iot_127_data_w[111:104] = iot_in_r[7:0];
						end
						3:begin
							iot_127_data_w[103:96] = iot_in_r[7:0];
						end
						4:begin
							iot_127_data_w[95:88] = iot_in_r[7:0];
						end
						5:begin
							iot_127_data_w[87:80] = iot_in_r[7:0];
						end
						6:begin
							iot_127_data_w[79:72] = iot_in_r[7:0];
						end
						7:begin
							iot_127_data_w[71:64] = iot_in_r[7:0];
						end
						8:begin
							iot_127_data_w[63:56] = iot_in_r[7:0];
						end
						9:begin
							iot_127_data_w[55:48] = iot_in_r[7:0];
						end
						10:begin
							iot_127_data_w[47:40] = iot_in_r[7:0];
						end
						11:begin
							iot_127_data_w[39:32] = iot_in_r[7:0];
						end
						12:begin
							iot_127_data_w[31:24] = iot_in_r[7:0];
						end
						13:begin
							iot_127_data_w[23:16] = iot_in_r[7:0];
						end
						14:begin
							iot_127_data_w[15:8] = iot_in_r[7:0];
						end
						15:begin
							iot_127_data_w[7:0] = iot_in_r[7:0];
						end
					endcase
				end
			end
			F3: begin
				if (counter_r == 15) begin
					iot_127_data_w[2:0] = iot_F3_out;
					iot_127_data_w[5:3] = 3'd0;
				end
				else begin
					iot_127_data_w[5:3] = iot_F3_temp[8][3:1];
				end
			end
			F4: begin
				case (counter_r)
					0: begin
						iot_127_data_w[127:120] = iot_in_ii1_xor[7:0];
					end
					1: begin
						iot_127_data_w[119:112] = iot_in_ii1_xor[7:0];
					end
					2: begin
						iot_127_data_w[111:104] = iot_in_ii1_xor[7:0];
					end
					3: begin
						iot_127_data_w[103:96] = iot_in_ii1_xor[7:0];
					end
					4: begin
						iot_127_data_w[95:88] = iot_in_ii1_xor[7:0];
					end
					5: begin
						iot_127_data_w[87:80] = iot_in_ii1_xor[7:0];
					end
					6: begin
						iot_127_data_w[79:72] = iot_in_ii1_xor[7:0];
					end
					7: begin
						iot_127_data_w[71:64] = iot_in_ii1_xor[7:0];
					end
					8: begin
						iot_127_data_w[63:56] = iot_in_ii1_xor[7:0];
					end
					9: begin
						iot_127_data_w[55:48] = iot_in_ii1_xor[7:0];
					end
					10: begin
						iot_127_data_w[47:40] = iot_in_ii1_xor[7:0];
					end
					11: begin
						iot_127_data_w[39:32] = iot_in_ii1_xor[7:0];
					end
					12: begin
						iot_127_data_w[31:24] = iot_in_ii1_xor[7:0];
					end
					13: begin
						iot_127_data_w[23:16] = iot_in_ii1_xor[7:0];
					end
					14: begin
						iot_127_data_w[15:8] = iot_in_ii1_xor[7:0];
					end
					15: begin
						iot_127_data_w[7:0] = iot_in_ii1_xor[7:0];
					end
				endcase
			end
			F5: begin
				case (counter_r)
					0: begin
						iot_127_data_w[127:120] = iot_F5_out[7:0];
					end
					1: begin
						iot_127_data_w[119:112] = iot_F5_out[7:0];
					end
					2: begin
						iot_127_data_w[111:104] = iot_F5_out[7:0];
					end
					3: begin
						iot_127_data_w[103:96] = iot_F5_out[7:0];
					end
					4: begin
						iot_127_data_w[95:88] = iot_F5_out[7:0];
					end
					5: begin
						iot_127_data_w[87:80] = iot_F5_out[7:0];
					end
					6: begin
						iot_127_data_w[79:72] = iot_F5_out[7:0];
					end
					7: begin
						iot_127_data_w[71:64] = iot_F5_out[7:0];
					end
					8: begin
						iot_127_data_w[63:56] = iot_F5_out[7:0];
					end
					9: begin
						iot_127_data_w[55:48] = iot_F5_out[7:0];
					end
					10: begin
						iot_127_data_w[47:40] = iot_F5_out[7:0];
					end
					11: begin
						iot_127_data_w[39:32] = iot_F5_out[7:0];
					end
					12: begin
						iot_127_data_w[31:24] = iot_F5_out[7:0];
					end
					13: begin
						iot_127_data_w[23:16] = iot_F5_out[7:0];
					end
					14: begin
						iot_127_data_w[15:8] = iot_F5_out[7:0];
					end
					15: begin
						iot_127_data_w[7:0] = iot_F5_out[7:0];
					end
				endcase
			end
		endcase
    end
end

// counter_w
always @(*) begin
    counter_w = counter_r;
    case (state_r)
        S_IDLE: begin
            counter_w = 0;
        end
        S_FUNC: begin
            counter_w = counter_r + 1;
			if (counter_r == 15) begin					
				counter_w = 0;
			end
        end
    endcase
end

// des_state_w
always @(*) begin
    des_state_w = des_state_r;
	if (state_r == S_FUNC) begin
		case (fn_sel)
			F1, F2: begin
				if (counter_r == 15) begin					
					case (des_state_r)
						DES_PROCESSING: begin
							des_state_w = DES_OUT_READY;
						end
						DES_OUT_READY: begin
							des_state_w = DES_PROCESSING;
						end
					endcase
				end
			end
			F4: begin
				des_state_w = iot_in_r[0];
			end
			F5: begin
				des_state_w = iot_F5_out[0];
			end
		endcase
	end
end

// ----------------------------------------------------------------------------
// sequential logic
// ----------------------------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        iot_127_data_r <= 0;
        busy_r <= 1;
        valid_r <= 0;
        counter_r <= 0;
        iot_in_r <= 0;
        state_r <= S_IDLE;
        des_state_r <= DES_PROCESSING;
    end else begin
        iot_127_data_r <= iot_127_data_w;
        busy_r <= busy_w;
        valid_r <= valid_w;
        counter_r <= counter_w;
        iot_in_r <= iot_in_w;
        state_r <= state_w;
        des_state_r <= des_state_w;
    end
end

endmodule

module PC2(in, out);
input [55:0] in;
output [47:0] out;
	assign out[47] = in[42];
	assign out[46] = in[39];
	assign out[45] = in[45];
	assign out[44] = in[32];
	assign out[43] = in[55];
	assign out[42] = in[51];
	assign out[41] = in[53];
	assign out[40] = in[28];
	assign out[39] = in[41];
	assign out[38] = in[50];
	assign out[37] = in[35];
	assign out[36] = in[46];
	assign out[35] = in[33];
	assign out[34] = in[37];
	assign out[33] = in[44];
	assign out[32] = in[52];
	assign out[31] = in[30];
	assign out[30] = in[48];
	assign out[29] = in[40];
	assign out[28] = in[49];
	assign out[27] = in[29];
	assign out[26] = in[36];
	assign out[25] = in[43];
	assign out[24] = in[54];
	assign out[23] = in[15];
	assign out[22] = in[4];
	assign out[21] = in[25];
	assign out[20] = in[19];
	assign out[19] = in[9];
	assign out[18] = in[1];
	assign out[17] = in[26];
	assign out[16] = in[16];
	assign out[15] = in[5];
	assign out[14] = in[11];
	assign out[13] = in[23];
	assign out[12] = in[8];
	assign out[11] = in[12];
	assign out[10] = in[7];
	assign out[9] = in[17];
	assign out[8] = in[0];
	assign out[7] = in[22];
	assign out[6] = in[3];
	assign out[5] = in[10];
	assign out[4] = in[14];
	assign out[3] = in[6];
	assign out[2] = in[20];
	assign out[1] = in[27];
	assign out[0] = in[24];
endmodule

module PC1(in, out);
input [63:0] in;
output [55:0] out;
	assign out[55] = in[7];
	assign out[54] = in[15];
	assign out[53] = in[23];
	assign out[52] = in[31];
	assign out[51] = in[39];
	assign out[50] = in[47];
	assign out[49] = in[55];
	assign out[48] = in[63];
	assign out[47] = in[6];
	assign out[46] = in[14];
	assign out[45] = in[22];
	assign out[44] = in[30];
	assign out[43] = in[38];
	assign out[42] = in[46];
	assign out[41] = in[54];
	assign out[40] = in[62];
	assign out[39] = in[5];
	assign out[38] = in[13];
	assign out[37] = in[21];
	assign out[36] = in[29];
	assign out[35] = in[37];
	assign out[34] = in[45];
	assign out[33] = in[53];
	assign out[32] = in[61];
	assign out[31] = in[4];
	assign out[30] = in[12];
	assign out[29] = in[20];
	assign out[28] = in[28];
	assign out[27] = in[1];
	assign out[26] = in[9];
	assign out[25] = in[17];
	assign out[24] = in[25];
	assign out[23] = in[33];
	assign out[22] = in[41];
	assign out[21] = in[49];
	assign out[20] = in[57];
	assign out[19] = in[2];
	assign out[18] = in[10];
	assign out[17] = in[18];
	assign out[16] = in[26];
	assign out[15] = in[34];
	assign out[14] = in[42];
	assign out[13] = in[50];
	assign out[12] = in[58];
	assign out[11] = in[3];
	assign out[10] = in[11];
	assign out[9] = in[19];
	assign out[8] = in[27];
	assign out[7] = in[35];
	assign out[6] = in[43];
	assign out[5] = in[51];
	assign out[4] = in[59];
	assign out[3] = in[36];
	assign out[2] = in[44];
	assign out[1] = in[52];
	assign out[0] = in[60];
endmodule

module F(in, key, out);
input [31:0] in;
input [47:0] key;
output [31:0] out;
wire [47:0] expanded_in;
wire [47:0] expanded_in_xor_key;
wire [31:0] s_out;
Expansion exp(.in(in), .out(expanded_in));
assign expanded_in_xor_key = expanded_in ^ key;
S1 s1(.in(expanded_in_xor_key[47:42]), .out_wire(s_out[31:28]));
S2 s2(.in(expanded_in_xor_key[41:36]), .out_wire(s_out[27:24]));
S3 s3(.in(expanded_in_xor_key[35:30]), .out_wire(s_out[23:20]));
S4 s4(.in(expanded_in_xor_key[29:24]), .out_wire(s_out[19:16]));
S5 s5(.in(expanded_in_xor_key[23:18]), .out_wire(s_out[15:12]));
S6 s6(.in(expanded_in_xor_key[17:12]), .out_wire(s_out[11:8]));
S7 s7(.in(expanded_in_xor_key[11:6]), .out_wire(s_out[7:4]));
S8 s8(.in(expanded_in_xor_key[5:0]), .out_wire(s_out[3:0]));
P p(.in(s_out), .out(out));
endmodule

module S1(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd14;
		6'b000010:out = 4'd4;
		6'b000100:out = 4'd13;
		6'b000110:out = 4'd1;
		6'b001000:out = 4'd2;
		6'b001010:out = 4'd15;
		6'b001100:out = 4'd11;
		6'b001110:out = 4'd8;
		6'b010000:out = 4'd3;
		6'b010010:out = 4'd10;
		6'b010100:out = 4'd6;
		6'b010110:out = 4'd12;
		6'b011000:out = 4'd5;
		6'b011010:out = 4'd9;
		6'b011100:out = 4'd0;
		6'b011110:out = 4'd7;
		6'b000001:out = 4'd0;
		6'b000011:out = 4'd15;
		6'b000101:out = 4'd7;
		6'b000111:out = 4'd4;
		6'b001001:out = 4'd14;
		6'b001011:out = 4'd2;
		6'b001101:out = 4'd13;
		6'b001111:out = 4'd1;
		6'b010001:out = 4'd10;
		6'b010011:out = 4'd6;
		6'b010101:out = 4'd12;
		6'b010111:out = 4'd11;
		6'b011001:out = 4'd9;
		6'b011011:out = 4'd5;
		6'b011101:out = 4'd3;
		6'b011111:out = 4'd8;
		6'b100000:out = 4'd4;
		6'b100010:out = 4'd1;
		6'b100100:out = 4'd14;
		6'b100110:out = 4'd8;
		6'b101000:out = 4'd13;
		6'b101010:out = 4'd6;
		6'b101100:out = 4'd2;
		6'b101110:out = 4'd11;
		6'b110000:out = 4'd15;
		6'b110010:out = 4'd12;
		6'b110100:out = 4'd9;
		6'b110110:out = 4'd7;
		6'b111000:out = 4'd3;
		6'b111010:out = 4'd10;
		6'b111100:out = 4'd5;
		6'b111110:out = 4'd0;
		6'b100001:out = 4'd15;
		6'b100011:out = 4'd12;
		6'b100101:out = 4'd8;
		6'b100111:out = 4'd2;
		6'b101001:out = 4'd4;
		6'b101011:out = 4'd9;
		6'b101101:out = 4'd1;
		6'b101111:out = 4'd7;
		6'b110001:out = 4'd5;
		6'b110011:out = 4'd11;
		6'b110101:out = 4'd3;
		6'b110111:out = 4'd14;
		6'b111001:out = 4'd10;
		6'b111011:out = 4'd0;
		6'b111101:out = 4'd6;
		6'b111111:out = 4'd13;
	endcase
end
endmodule

module S2(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd15;
		6'b000010:out = 4'd1;
		6'b000100:out = 4'd8;
		6'b000110:out = 4'd14;
		6'b001000:out = 4'd6;
		6'b001010:out = 4'd11;
		6'b001100:out = 4'd3;
		6'b001110:out = 4'd4;
		6'b010000:out = 4'd9;
		6'b010010:out = 4'd7;
		6'b010100:out = 4'd2;
		6'b010110:out = 4'd13;
		6'b011000:out = 4'd12;
		6'b011010:out = 4'd0;
		6'b011100:out = 4'd5;
		6'b011110:out = 4'd10;
		6'b000001:out = 4'd3;
		6'b000011:out = 4'd13;
		6'b000101:out = 4'd4;
		6'b000111:out = 4'd7;
		6'b001001:out = 4'd15;
		6'b001011:out = 4'd2;
		6'b001101:out = 4'd8;
		6'b001111:out = 4'd14;
		6'b010001:out = 4'd12;
		6'b010011:out = 4'd0;
		6'b010101:out = 4'd1;
		6'b010111:out = 4'd10;
		6'b011001:out = 4'd6;
		6'b011011:out = 4'd9;
		6'b011101:out = 4'd11;
		6'b011111:out = 4'd5;
		6'b100000:out = 4'd0;
		6'b100010:out = 4'd14;
		6'b100100:out = 4'd7;
		6'b100110:out = 4'd11;
		6'b101000:out = 4'd10;
		6'b101010:out = 4'd4;
		6'b101100:out = 4'd13;
		6'b101110:out = 4'd1;
		6'b110000:out = 4'd5;
		6'b110010:out = 4'd8;
		6'b110100:out = 4'd12;
		6'b110110:out = 4'd6;
		6'b111000:out = 4'd9;
		6'b111010:out = 4'd3;
		6'b111100:out = 4'd2;
		6'b111110:out = 4'd15;
		6'b100001:out = 4'd13;
		6'b100011:out = 4'd8;
		6'b100101:out = 4'd10;
		6'b100111:out = 4'd1;
		6'b101001:out = 4'd3;
		6'b101011:out = 4'd15;
		6'b101101:out = 4'd4;
		6'b101111:out = 4'd2;
		6'b110001:out = 4'd11;
		6'b110011:out = 4'd6;
		6'b110101:out = 4'd7;
		6'b110111:out = 4'd12;
		6'b111001:out = 4'd0;
		6'b111011:out = 4'd5;
		6'b111101:out = 4'd14;
		6'b111111:out = 4'd9;
	endcase
end
endmodule

module S3(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd10;
		6'b000010:out = 4'd0;
		6'b000100:out = 4'd9;
		6'b000110:out = 4'd14;
		6'b001000:out = 4'd6;
		6'b001010:out = 4'd3;
		6'b001100:out = 4'd15;
		6'b001110:out = 4'd5;
		6'b010000:out = 4'd1;
		6'b010010:out = 4'd13;
		6'b010100:out = 4'd12;
		6'b010110:out = 4'd7;
		6'b011000:out = 4'd11;
		6'b011010:out = 4'd4;
		6'b011100:out = 4'd2;
		6'b011110:out = 4'd8;
		6'b000001:out = 4'd13;
		6'b000011:out = 4'd7;
		6'b000101:out = 4'd0;
		6'b000111:out = 4'd9;
		6'b001001:out = 4'd3;
		6'b001011:out = 4'd4;
		6'b001101:out = 4'd6;
		6'b001111:out = 4'd10;
		6'b010001:out = 4'd2;
		6'b010011:out = 4'd8;
		6'b010101:out = 4'd5;
		6'b010111:out = 4'd14;
		6'b011001:out = 4'd12;
		6'b011011:out = 4'd11;
		6'b011101:out = 4'd15;
		6'b011111:out = 4'd1;
		6'b100000:out = 4'd13;
		6'b100010:out = 4'd6;
		6'b100100:out = 4'd4;
		6'b100110:out = 4'd9;
		6'b101000:out = 4'd8;
		6'b101010:out = 4'd15;
		6'b101100:out = 4'd3;
		6'b101110:out = 4'd0;
		6'b110000:out = 4'd11;
		6'b110010:out = 4'd1;
		6'b110100:out = 4'd2;
		6'b110110:out = 4'd12;
		6'b111000:out = 4'd5;
		6'b111010:out = 4'd10;
		6'b111100:out = 4'd14;
		6'b111110:out = 4'd7;
		6'b100001:out = 4'd1;
		6'b100011:out = 4'd10;
		6'b100101:out = 4'd13;
		6'b100111:out = 4'd0;
		6'b101001:out = 4'd6;
		6'b101011:out = 4'd9;
		6'b101101:out = 4'd8;
		6'b101111:out = 4'd7;
		6'b110001:out = 4'd4;
		6'b110011:out = 4'd15;
		6'b110101:out = 4'd14;
		6'b110111:out = 4'd3;
		6'b111001:out = 4'd11;
		6'b111011:out = 4'd5;
		6'b111101:out = 4'd2;
		6'b111111:out = 4'd12;
	endcase
end
endmodule

module S4(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd7;
		6'b000010:out = 4'd13;
		6'b000100:out = 4'd14;
		6'b000110:out = 4'd3;
		6'b001000:out = 4'd0;
		6'b001010:out = 4'd6;
		6'b001100:out = 4'd9;
		6'b001110:out = 4'd10;
		6'b010000:out = 4'd1;
		6'b010010:out = 4'd2;
		6'b010100:out = 4'd8;
		6'b010110:out = 4'd5;
		6'b011000:out = 4'd11;
		6'b011010:out = 4'd12;
		6'b011100:out = 4'd4;
		6'b011110:out = 4'd15;
		6'b000001:out = 4'd13;
		6'b000011:out = 4'd8;
		6'b000101:out = 4'd11;
		6'b000111:out = 4'd5;
		6'b001001:out = 4'd6;
		6'b001011:out = 4'd15;
		6'b001101:out = 4'd0;
		6'b001111:out = 4'd3;
		6'b010001:out = 4'd4;
		6'b010011:out = 4'd7;
		6'b010101:out = 4'd2;
		6'b010111:out = 4'd12;
		6'b011001:out = 4'd1;
		6'b011011:out = 4'd10;
		6'b011101:out = 4'd14;
		6'b011111:out = 4'd9;
		6'b100000:out = 4'd10;
		6'b100010:out = 4'd6;
		6'b100100:out = 4'd9;
		6'b100110:out = 4'd0;
		6'b101000:out = 4'd12;
		6'b101010:out = 4'd11;
		6'b101100:out = 4'd7;
		6'b101110:out = 4'd13;
		6'b110000:out = 4'd15;
		6'b110010:out = 4'd1;
		6'b110100:out = 4'd3;
		6'b110110:out = 4'd14;
		6'b111000:out = 4'd5;
		6'b111010:out = 4'd2;
		6'b111100:out = 4'd8;
		6'b111110:out = 4'd4;
		6'b100001:out = 4'd3;
		6'b100011:out = 4'd15;
		6'b100101:out = 4'd0;
		6'b100111:out = 4'd6;
		6'b101001:out = 4'd10;
		6'b101011:out = 4'd1;
		6'b101101:out = 4'd13;
		6'b101111:out = 4'd8;
		6'b110001:out = 4'd9;
		6'b110011:out = 4'd4;
		6'b110101:out = 4'd5;
		6'b110111:out = 4'd11;
		6'b111001:out = 4'd12;
		6'b111011:out = 4'd7;
		6'b111101:out = 4'd2;
		6'b111111:out = 4'd14;
	endcase
end
endmodule

module S5(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd2;
		6'b000010:out = 4'd12;
		6'b000100:out = 4'd4;
		6'b000110:out = 4'd1;
		6'b001000:out = 4'd7;
		6'b001010:out = 4'd10;
		6'b001100:out = 4'd11;
		6'b001110:out = 4'd6;
		6'b010000:out = 4'd8;
		6'b010010:out = 4'd5;
		6'b010100:out = 4'd3;
		6'b010110:out = 4'd15;
		6'b011000:out = 4'd13;
		6'b011010:out = 4'd0;
		6'b011100:out = 4'd14;
		6'b011110:out = 4'd9;
		6'b000001:out = 4'd14;
		6'b000011:out = 4'd11;
		6'b000101:out = 4'd2;
		6'b000111:out = 4'd12;
		6'b001001:out = 4'd4;
		6'b001011:out = 4'd7;
		6'b001101:out = 4'd13;
		6'b001111:out = 4'd1;
		6'b010001:out = 4'd5;
		6'b010011:out = 4'd0;
		6'b010101:out = 4'd15;
		6'b010111:out = 4'd10;
		6'b011001:out = 4'd3;
		6'b011011:out = 4'd9;
		6'b011101:out = 4'd8;
		6'b011111:out = 4'd6;
		6'b100000:out = 4'd4;
		6'b100010:out = 4'd2;
		6'b100100:out = 4'd1;
		6'b100110:out = 4'd11;
		6'b101000:out = 4'd10;
		6'b101010:out = 4'd13;
		6'b101100:out = 4'd7;
		6'b101110:out = 4'd8;
		6'b110000:out = 4'd15;
		6'b110010:out = 4'd9;
		6'b110100:out = 4'd12;
		6'b110110:out = 4'd5;
		6'b111000:out = 4'd6;
		6'b111010:out = 4'd3;
		6'b111100:out = 4'd0;
		6'b111110:out = 4'd14;
		6'b100001:out = 4'd11;
		6'b100011:out = 4'd8;
		6'b100101:out = 4'd12;
		6'b100111:out = 4'd7;
		6'b101001:out = 4'd1;
		6'b101011:out = 4'd14;
		6'b101101:out = 4'd2;
		6'b101111:out = 4'd13;
		6'b110001:out = 4'd6;
		6'b110011:out = 4'd15;
		6'b110101:out = 4'd0;
		6'b110111:out = 4'd9;
		6'b111001:out = 4'd10;
		6'b111011:out = 4'd4;
		6'b111101:out = 4'd5;
		6'b111111:out = 4'd3;
	endcase
end
endmodule

module S6(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd12;
		6'b000010:out = 4'd1;
		6'b000100:out = 4'd10;
		6'b000110:out = 4'd15;
		6'b001000:out = 4'd9;
		6'b001010:out = 4'd2;
		6'b001100:out = 4'd6;
		6'b001110:out = 4'd8;
		6'b010000:out = 4'd0;
		6'b010010:out = 4'd13;
		6'b010100:out = 4'd3;
		6'b010110:out = 4'd4;
		6'b011000:out = 4'd14;
		6'b011010:out = 4'd7;
		6'b011100:out = 4'd5;
		6'b011110:out = 4'd11;
		6'b000001:out = 4'd10;
		6'b000011:out = 4'd15;
		6'b000101:out = 4'd4;
		6'b000111:out = 4'd2;
		6'b001001:out = 4'd7;
		6'b001011:out = 4'd12;
		6'b001101:out = 4'd9;
		6'b001111:out = 4'd5;
		6'b010001:out = 4'd6;
		6'b010011:out = 4'd1;
		6'b010101:out = 4'd13;
		6'b010111:out = 4'd14;
		6'b011001:out = 4'd0;
		6'b011011:out = 4'd11;
		6'b011101:out = 4'd3;
		6'b011111:out = 4'd8;
		6'b100000:out = 4'd9;
		6'b100010:out = 4'd14;
		6'b100100:out = 4'd15;
		6'b100110:out = 4'd5;
		6'b101000:out = 4'd2;
		6'b101010:out = 4'd8;
		6'b101100:out = 4'd12;
		6'b101110:out = 4'd3;
		6'b110000:out = 4'd7;
		6'b110010:out = 4'd0;
		6'b110100:out = 4'd4;
		6'b110110:out = 4'd10;
		6'b111000:out = 4'd1;
		6'b111010:out = 4'd13;
		6'b111100:out = 4'd11;
		6'b111110:out = 4'd6;
		6'b100001:out = 4'd4;
		6'b100011:out = 4'd3;
		6'b100101:out = 4'd2;
		6'b100111:out = 4'd12;
		6'b101001:out = 4'd9;
		6'b101011:out = 4'd5;
		6'b101101:out = 4'd15;
		6'b101111:out = 4'd10;
		6'b110001:out = 4'd11;
		6'b110011:out = 4'd14;
		6'b110101:out = 4'd1;
		6'b110111:out = 4'd7;
		6'b111001:out = 4'd6;
		6'b111011:out = 4'd0;
		6'b111101:out = 4'd8;
		6'b111111:out = 4'd13;
	endcase
end
endmodule

module S7(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd4;
		6'b000010:out = 4'd11;
		6'b000100:out = 4'd2;
		6'b000110:out = 4'd14;
		6'b001000:out = 4'd15;
		6'b001010:out = 4'd0;
		6'b001100:out = 4'd8;
		6'b001110:out = 4'd13;
		6'b010000:out = 4'd3;
		6'b010010:out = 4'd12;
		6'b010100:out = 4'd9;
		6'b010110:out = 4'd7;
		6'b011000:out = 4'd5;
		6'b011010:out = 4'd10;
		6'b011100:out = 4'd6;
		6'b011110:out = 4'd1;
		6'b000001:out = 4'd13;
		6'b000011:out = 4'd0;
		6'b000101:out = 4'd11;
		6'b000111:out = 4'd7;
		6'b001001:out = 4'd4;
		6'b001011:out = 4'd9;
		6'b001101:out = 4'd1;
		6'b001111:out = 4'd10;
		6'b010001:out = 4'd14;
		6'b010011:out = 4'd3;
		6'b010101:out = 4'd5;
		6'b010111:out = 4'd12;
		6'b011001:out = 4'd2;
		6'b011011:out = 4'd15;
		6'b011101:out = 4'd8;
		6'b011111:out = 4'd6;
		6'b100000:out = 4'd1;
		6'b100010:out = 4'd4;
		6'b100100:out = 4'd11;
		6'b100110:out = 4'd13;
		6'b101000:out = 4'd12;
		6'b101010:out = 4'd3;
		6'b101100:out = 4'd7;
		6'b101110:out = 4'd14;
		6'b110000:out = 4'd10;
		6'b110010:out = 4'd15;
		6'b110100:out = 4'd6;
		6'b110110:out = 4'd8;
		6'b111000:out = 4'd0;
		6'b111010:out = 4'd5;
		6'b111100:out = 4'd9;
		6'b111110:out = 4'd2;
		6'b100001:out = 4'd6;
		6'b100011:out = 4'd11;
		6'b100101:out = 4'd13;
		6'b100111:out = 4'd8;
		6'b101001:out = 4'd1;
		6'b101011:out = 4'd4;
		6'b101101:out = 4'd10;
		6'b101111:out = 4'd7;
		6'b110001:out = 4'd9;
		6'b110011:out = 4'd5;
		6'b110101:out = 4'd0;
		6'b110111:out = 4'd15;
		6'b111001:out = 4'd14;
		6'b111011:out = 4'd2;
		6'b111101:out = 4'd3;
		6'b111111:out = 4'd12;
	endcase
end
endmodule

module S8(in, out_wire);
input [5:0] in;
output [3:0] out_wire;
reg [3:0] out;
assign out_wire = out;
always @(*) begin
    out = 4'd0;
	case(in)
		6'b000000:out = 4'd13;
		6'b000010:out = 4'd2;
		6'b000100:out = 4'd8;
		6'b000110:out = 4'd4;
		6'b001000:out = 4'd6;
		6'b001010:out = 4'd15;
		6'b001100:out = 4'd11;
		6'b001110:out = 4'd1;
		6'b010000:out = 4'd10;
		6'b010010:out = 4'd9;
		6'b010100:out = 4'd3;
		6'b010110:out = 4'd14;
		6'b011000:out = 4'd5;
		6'b011010:out = 4'd0;
		6'b011100:out = 4'd12;
		6'b011110:out = 4'd7;
		6'b000001:out = 4'd1;
		6'b000011:out = 4'd15;
		6'b000101:out = 4'd13;
		6'b000111:out = 4'd8;
		6'b001001:out = 4'd10;
		6'b001011:out = 4'd3;
		6'b001101:out = 4'd7;
		6'b001111:out = 4'd4;
		6'b010001:out = 4'd12;
		6'b010011:out = 4'd5;
		6'b010101:out = 4'd6;
		6'b010111:out = 4'd11;
		6'b011001:out = 4'd0;
		6'b011011:out = 4'd14;
		6'b011101:out = 4'd9;
		6'b011111:out = 4'd2;
		6'b100000:out = 4'd7;
		6'b100010:out = 4'd11;
		6'b100100:out = 4'd4;
		6'b100110:out = 4'd1;
		6'b101000:out = 4'd9;
		6'b101010:out = 4'd12;
		6'b101100:out = 4'd14;
		6'b101110:out = 4'd2;
		6'b110000:out = 4'd0;
		6'b110010:out = 4'd6;
		6'b110100:out = 4'd10;
		6'b110110:out = 4'd13;
		6'b111000:out = 4'd15;
		6'b111010:out = 4'd3;
		6'b111100:out = 4'd5;
		6'b111110:out = 4'd8;
		6'b100001:out = 4'd2;
		6'b100011:out = 4'd1;
		6'b100101:out = 4'd14;
		6'b100111:out = 4'd7;
		6'b101001:out = 4'd4;
		6'b101011:out = 4'd10;
		6'b101101:out = 4'd8;
		6'b101111:out = 4'd13;
		6'b110001:out = 4'd15;
		6'b110011:out = 4'd12;
		6'b110101:out = 4'd9;
		6'b110111:out = 4'd0;
		6'b111001:out = 4'd3;
		6'b111011:out = 4'd5;
		6'b111101:out = 4'd6;
		6'b111111:out = 4'd11;
	endcase
end
endmodule

module InitialP(in, out);
input [63:0] in;
output [63:0] out;
	assign out[63] = in[6];
	assign out[62] = in[14];
	assign out[61] = in[22];
	assign out[60] = in[30];
	assign out[59] = in[38];
	assign out[58] = in[46];
	assign out[57] = in[54];
	assign out[56] = in[62];
	assign out[55] = in[4];
	assign out[54] = in[12];
	assign out[53] = in[20];
	assign out[52] = in[28];
	assign out[51] = in[36];
	assign out[50] = in[44];
	assign out[49] = in[52];
	assign out[48] = in[60];
	assign out[47] = in[2];
	assign out[46] = in[10];
	assign out[45] = in[18];
	assign out[44] = in[26];
	assign out[43] = in[34];
	assign out[42] = in[42];
	assign out[41] = in[50];
	assign out[40] = in[58];
	assign out[39] = in[0];
	assign out[38] = in[8];
	assign out[37] = in[16];
	assign out[36] = in[24];
	assign out[35] = in[32];
	assign out[34] = in[40];
	assign out[33] = in[48];
	assign out[32] = in[56];
	assign out[31] = in[7];
	assign out[30] = in[15];
	assign out[29] = in[23];
	assign out[28] = in[31];
	assign out[27] = in[39];
	assign out[26] = in[47];
	assign out[25] = in[55];
	assign out[24] = in[63];
	assign out[23] = in[5];
	assign out[22] = in[13];
	assign out[21] = in[21];
	assign out[20] = in[29];
	assign out[19] = in[37];
	assign out[18] = in[45];
	assign out[17] = in[53];
	assign out[16] = in[61];
	assign out[15] = in[3];
	assign out[14] = in[11];
	assign out[13] = in[19];
	assign out[12] = in[27];
	assign out[11] = in[35];
	assign out[10] = in[43];
	assign out[9] = in[51];
	assign out[8] = in[59];
	assign out[7] = in[1];
	assign out[6] = in[9];
	assign out[5] = in[17];
	assign out[4] = in[25];
	assign out[3] = in[33];
	assign out[2] = in[41];
	assign out[1] = in[49];
	assign out[0] = in[57];
endmodule

module FinalP(in, out);
input [63:0] in;
output [63:0] out;
	assign out[63] = in[24];
	assign out[62] = in[56];
	assign out[61] = in[16];
	assign out[60] = in[48];
	assign out[59] = in[8];
	assign out[58] = in[40];
	assign out[57] = in[0];
	assign out[56] = in[32];
	assign out[55] = in[25];
	assign out[54] = in[57];
	assign out[53] = in[17];
	assign out[52] = in[49];
	assign out[51] = in[9];
	assign out[50] = in[41];
	assign out[49] = in[1];
	assign out[48] = in[33];
	assign out[47] = in[26];
	assign out[46] = in[58];
	assign out[45] = in[18];
	assign out[44] = in[50];
	assign out[43] = in[10];
	assign out[42] = in[42];
	assign out[41] = in[2];
	assign out[40] = in[34];
	assign out[39] = in[27];
	assign out[38] = in[59];
	assign out[37] = in[19];
	assign out[36] = in[51];
	assign out[35] = in[11];
	assign out[34] = in[43];
	assign out[33] = in[3];
	assign out[32] = in[35];
	assign out[31] = in[28];
	assign out[30] = in[60];
	assign out[29] = in[20];
	assign out[28] = in[52];
	assign out[27] = in[12];
	assign out[26] = in[44];
	assign out[25] = in[4];
	assign out[24] = in[36];
	assign out[23] = in[29];
	assign out[22] = in[61];
	assign out[21] = in[21];
	assign out[20] = in[53];
	assign out[19] = in[13];
	assign out[18] = in[45];
	assign out[17] = in[5];
	assign out[16] = in[37];
	assign out[15] = in[30];
	assign out[14] = in[62];
	assign out[13] = in[22];
	assign out[12] = in[54];
	assign out[11] = in[14];
	assign out[10] = in[46];
	assign out[9] = in[6];
	assign out[8] = in[38];
	assign out[7] = in[31];
	assign out[6] = in[63];
	assign out[5] = in[23];
	assign out[4] = in[55];
	assign out[3] = in[15];
	assign out[2] = in[47];
	assign out[1] = in[7];
	assign out[0] = in[39];
endmodule

module Expansion(in, out);
input [31:0] in;
output [47:0] out;
	 assign out[47] = in[0];
	 assign out[46] = in[31];
	 assign out[45] = in[30];
	 assign out[44] = in[29];
	 assign out[43] = in[28];
	 assign out[42] = in[27];
	 assign out[41] = in[28];
	 assign out[40] = in[27];
	 assign out[39] = in[26];
	 assign out[38] = in[25];
	 assign out[37] = in[24];
	 assign out[36] = in[23];
	 assign out[35] = in[24];
	 assign out[34] = in[23];
	 assign out[33] = in[22];
	 assign out[32] = in[21];
	 assign out[31] = in[20];
	 assign out[30] = in[19];
	 assign out[29] = in[20];
	 assign out[28] = in[19];
	 assign out[27] = in[18];
	 assign out[26] = in[17];
	 assign out[25] = in[16];
	 assign out[24] = in[15];
	 assign out[23] = in[16];
	 assign out[22] = in[15];
	 assign out[21] = in[14];
	 assign out[20] = in[13];
	 assign out[19] = in[12];
	 assign out[18] = in[11];
	 assign out[17] = in[12];
	 assign out[16] = in[11];
	 assign out[15] = in[10];
	 assign out[14] = in[9];
	 assign out[13] = in[8];
	 assign out[12] = in[7];
	 assign out[11] = in[8];
	 assign out[10] = in[7];
	 assign out[9] = in[6];
	 assign out[8] = in[5];
	 assign out[7] = in[4];
	 assign out[6] = in[3];
	 assign out[5] = in[4];
	 assign out[4] = in[3];
	 assign out[3] = in[2];
	 assign out[2] = in[1];
	 assign out[1] = in[0];
	 assign out[0] = in[31];
endmodule

module P(in, out);
input [31:0] in;
output [31:0] out;
	assign out[31] = in[16];
	assign out[30] = in[25];
	assign out[29] = in[12];
	assign out[28] = in[11];
	assign out[27] = in[3];
	assign out[26] = in[20];
	assign out[25] = in[4];
	assign out[24] = in[15];
	assign out[23] = in[31];
	assign out[22] = in[17];
	assign out[21] = in[9];
	assign out[20] = in[6];
	assign out[19] = in[27];
	assign out[18] = in[14];
	assign out[17] = in[1];
	assign out[16] = in[22];
	assign out[15] = in[30];
	assign out[14] = in[24];
	assign out[13] = in[8];
	assign out[12] = in[18];
	assign out[11] = in[0];
	assign out[10] = in[5];
	assign out[9] = in[29];
	assign out[8] = in[23];
	assign out[7] = in[13];
	assign out[6] = in[19];
	assign out[5] = in[2];
	assign out[4] = in[26];
	assign out[3] = in[10];
	assign out[2] = in[21];
	assign out[1] = in[28];
	assign out[0] = in[7];
endmodule

module CircularShiftLeft1(in, out);
input [27:0] in;
output [27:0] out;
    assign out = {in[26:0], in[27]};
endmodule

module CircularShiftLeft2(in, out);
input [27:0] in;
output [27:0] out;
    assign out = {in[25:0], in[27:26]};
endmodule