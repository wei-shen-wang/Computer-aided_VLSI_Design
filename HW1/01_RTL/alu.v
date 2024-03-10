module alu #(
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                     i_clk,
    input                     i_rst_n,
    input signed [DATA_W-1:0] i_data_a,
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,
    output                    o_valid,
    output                    o_busy,
    output       [DATA_W-1:0] o_data
);

// ----------------------------------------------------------------------------
// parameters: Definition of State
// ----------------------------------------------------------------------------
parameter ADD_FX = 4'b0000;
parameter SUB_FX = 4'b0001;
parameter MUL_FX = 4'b0010;
parameter MAC = 4'b0011;
parameter GELU = 4'b0100;
parameter CLZ = 4'b0101;
parameter LRCW = 4'b0110;
parameter LFSR = 4'b0111;
parameter ADD_FP = 4'b1000;
parameter SUB_FP = 4'b1001;

parameter BEFORE_INPUT = 1'b0;
parameter START_INPUT = 1'b1;

parameter SIGNED_ONE = $signed(16'b0000_0100_0000_0000);

// ----------------------------------------------------------------------------
// wires and registers declaration
// ----------------------------------------------------------------------------
reg o_valid_r, o_valid_w;
reg o_busy_r, o_busy_w;
reg [DATA_W-1:0] o_data_r;
reg [DATA_W-1:0] o_data_w;
reg [DATA_W-1:0] alu_out_data;
reg signed [DATA_W:0] alu_temp;
reg signed [15:0] alu_temp_15;
reg signed [2 * DATA_W - 1:0] alu_large_temp;
reg signed [21:0] alu_large_temp_rounded;
reg cur_state, nxt_state;
reg [1:0] CPOP_1_1, CPOP_1_2, CPOP_1_3, CPOP_1_4, CPOP_1_5, CPOP_1_6, CPOP_1_7, CPOP_1_8;
reg [2:0] CPOP_2_1, CPOP_2_2, CPOP_2_3, CPOP_2_4;
reg [3:0] CPOP_3_1, CPOP_3_2;
reg [4:0] CPOP;
reg [DATA_W-1:0] lfsr1, lfsr2, lfsr3, lfsr4, lfsr5, lfsr6, lfsr7, lfsr8;
reg signed [75:0] arg_in_tanh;
reg signed [15:0] arg_in_tanh_rounded;
reg signed [15:0] result_tanh;
reg signed [31:0] alu_temp_31;
reg signed [15:0] i_data_larger;
reg signed [15:0] i_data_smaller;
reg [21:0] fp_m_22_larger;
reg [21:0] fp_m_22_smaller;
reg [21:0] fp_m_22_smaller_before_shift;
reg [21:0] fp_m_result;
reg [10:0] fp_m_result_shifted;
reg [10:0] fp_m_result_rounded;
reg stickybit;
reg Rbit;
reg Gbit;
reg [4:0] leadingZeros;
reg signed [15:0] i_data_b_neg;

// ----------------------------------------------------------------------------
// wire assignment: continuous assignments 
// ----------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_busy  = o_busy_r;
assign o_data  = o_data_r;

// ----------------------------------------------------------------------------
// Continuout Part: Output-logic (OL)
// Continuout Part: Next-state logic (NL)
// ----------------------------------------------------------------------------
always @(*) begin    
    o_data_w = (o_valid_w == 1'b1) ? alu_out_data : o_data_r;
end

always @(*) begin
    if ( ( o_busy_r == 1'b0 ) ) begin
        nxt_state = START_INPUT;
        o_busy_w = 1'b1;
        o_valid_w = o_valid_r;
    end
    else if ( ( o_busy_r == 1'b1 ) && ( o_valid_r == 1'b0 ) ) begin
        nxt_state = cur_state;
        if ( nxt_state == START_INPUT ) begin
            o_busy_w = o_busy_r;
            o_valid_w = 1'b1;
        end 
        else begin
            o_busy_w = 1'b0;
            o_valid_w = o_valid_r;
        end
    end 
    else if( ( o_busy_r == 1'b1 ) && ( o_valid_r == 1'b1 ) ) begin
        nxt_state = cur_state;
        o_valid_w = 1'b0;
        o_busy_w = 1'b0;
    end 
    else begin
        nxt_state = BEFORE_INPUT;
        o_valid_w = o_valid_r;
        o_busy_w = o_busy_r;
    end
end

always @(*) begin
    case(i_inst)
        ADD_FX: begin
            alu_temp = i_data_a + i_data_b;
            if ( alu_temp > $signed(17'b0_0111_1111_1111_1111) ) begin
                alu_out_data = 16'b0111_1111_1111_1111;
            end
            else if ( alu_temp < $signed(17'b1_1000_0000_0000_0000) ) begin
                alu_out_data = 16'b1000_0000_0000_0000;
            end
            else begin
                alu_out_data = alu_temp[15:0];
            end
        end
        SUB_FX: begin
            alu_temp = i_data_a - i_data_b;
            if ( alu_temp > $signed(17'b0_0111_1111_1111_1111) ) begin
                alu_out_data = 16'b0111_1111_1111_1111;
            end
            else if ( alu_temp < $signed(17'b1_1000_0000_0000_0000) ) begin
                alu_out_data = 16'b1000_0000_0000_0000;
            end
            else begin
                alu_out_data = alu_temp[15:0];
            end
        end
        MUL_FX: begin
            alu_large_temp = i_data_a * i_data_b;
            alu_large_temp_rounded = alu_large_temp[ 2*DATA_W - 1 : 2 * DATA_W - 22 ] + alu_large_temp[ 2*DATA_W - 23 ];
            if ( alu_large_temp_rounded > $signed(22'b00_0000_0111_1111_1111_1111) ) begin
                alu_out_data = 16'b0111_1111_1111_1111;
            end
            else if ( alu_large_temp_rounded < $signed(22'b11_1111_1000_0000_0000_0000) ) begin
                alu_out_data = 16'b1000_0000_0000_0000;
            end
            else begin
                alu_out_data = alu_large_temp_rounded[15 : 0];
            end
        end
        MAC: begin
            alu_large_temp = i_data_a * i_data_b + $signed({ {6{ o_data_r[DATA_W-1] }}, o_data_r, 10'b00_0000_0000 });
            alu_large_temp_rounded = alu_large_temp[ 2*DATA_W - 1 : 2 * DATA_W - 22 ] + alu_large_temp[ 2*DATA_W - 23 ];
            if ( alu_large_temp_rounded > $signed(22'b00_0000_0111_1111_1111_1111) ) begin
                alu_out_data = 16'b0111_1111_1111_1111;
            end
            else if ( alu_large_temp_rounded < $signed(22'b11_1111_1000_0000_0000_0000) ) begin
                alu_out_data = 16'b1000_0000_0000_0000;
            end
            else begin
                alu_out_data = alu_large_temp_rounded[15:0];
            end
        end
        GELU: begin
            arg_in_tanh = SIGNED_ONE * SIGNED_ONE * SIGNED_ONE * $signed({{6{1'b0}}, 10'b11_0011_0001}) * i_data_a
            + $signed({{6{1'b0}}, 10'b11_0011_0001}) * $signed({{6{1'b0}}, 10'b00_0010_1110}) * i_data_a * i_data_a * i_data_a;
            arg_in_tanh_rounded = arg_in_tanh[55:40] + arg_in_tanh[39];
            if( arg_in_tanh_rounded < $signed(16'b1111_1010_0000_0000 ) ) begin
                result_tanh = 16'b1111_1100_0000_0000;
            end
            else if ( arg_in_tanh_rounded < $signed(16'b1111_1110_0000_0000) ) begin
                alu_temp_15 = arg_in_tanh_rounded - $signed(16'b0000_0010_0000_0000);
                result_tanh = (alu_temp_15[0]) ? ( ( alu_temp_15 + 1 ) >>> 1 ) : ( alu_temp_15 >>> 1);
            end
            else if ( arg_in_tanh_rounded < $signed(16'b0000_0010_0000_0000) ) begin
                result_tanh = arg_in_tanh_rounded;
            end
            else if ( arg_in_tanh_rounded < $signed(16'b0000_0110_0000_0000) ) begin
                alu_temp_15 = arg_in_tanh_rounded + $signed(16'b0000_0010_0000_0000);
                result_tanh = (alu_temp_15[0]) ? ( ( alu_temp_15 + 1 ) >>> 1 ) : ( alu_temp_15 >>> 1);
            end
            else begin
                result_tanh = 16'b0000_0100_0000_0000;
            end
            alu_large_temp = i_data_a * ($signed(16'b0000_0100_0000_0000) + result_tanh);
            alu_temp_31 = alu_large_temp >> 1;
            alu_out_data = alu_temp_31[25:10] + alu_temp_31[9];
        end
        CLZ: begin
            if( i_data_a == 16'b0000_0000_0000_0000 ) begin
                alu_out_data = 16;
            end
            else if ( i_data_a == 16'b0000_0000_0000_0001 ) begin
                alu_out_data = 15;
            end
            else if ( i_data_a[15:1] == 15'b000_0000_0000_0001 ) begin
                alu_out_data = 14;
            end
            else if ( i_data_a[15:2] == 14'b00_0000_0000_0001 ) begin
                alu_out_data = 13;
            end
            else if ( i_data_a[15:3] == 13'b0_0000_0000_0001 ) begin
                alu_out_data = 12;
            end
            else if ( i_data_a[15:4] == 12'b0000_0000_0001 ) begin
                alu_out_data = 11;
            end
            else if ( i_data_a[15:5] == 11'b000_0000_0001 ) begin
                alu_out_data = 10;
            end
            else if ( i_data_a[15:6] == 10'b00_0000_0001 ) begin
                alu_out_data = 9;
            end
            else if ( i_data_a[15:7] == 9'b0_0000_0001 ) begin
                alu_out_data = 8;
            end
            else if ( i_data_a[15:8] == 8'b0000_0001 ) begin
                alu_out_data = 7;
            end
            else if ( i_data_a[15:9] == 7'b000_0001 ) begin
                alu_out_data = 6;
            end
            else if ( i_data_a[15:10] == 6'b00_0001 ) begin
                alu_out_data = 5;
            end
            else if ( i_data_a[15:11] == 5'b0_0001 ) begin
                alu_out_data = 4;
            end
            else if ( i_data_a[15:12] == 4'b0001 ) begin
                alu_out_data = 3;
            end
            else if ( i_data_a[15:13] == 3'b001 ) begin
                alu_out_data = 2;
            end
            else if ( i_data_a[15:14] == 2'b01 ) begin
                alu_out_data = 1;
            end
            else begin
                alu_out_data = 0;
            end
        end
        LRCW: begin
            CPOP_1_1 = i_data_a[15] + i_data_a[14];
            CPOP_1_2 = i_data_a[13] + i_data_a[12];
            CPOP_1_3 = i_data_a[11] + i_data_a[10];
            CPOP_1_4 = i_data_a[9] + i_data_a[8];
            CPOP_1_5 = i_data_a[7] + i_data_a[6];
            CPOP_1_6 = i_data_a[5] + i_data_a[4];
            CPOP_1_7 = i_data_a[3] + i_data_a[2];
            CPOP_1_8 = i_data_a[1] + i_data_a[0];
            CPOP_2_1 = CPOP_1_1 + CPOP_1_2;
            CPOP_2_2 = CPOP_1_3 + CPOP_1_4;
            CPOP_2_3 = CPOP_1_5 + CPOP_1_6;
            CPOP_2_4 = CPOP_1_7 + CPOP_1_8;
            CPOP_3_1 = CPOP_2_1 + CPOP_2_2;
            CPOP_3_2 = CPOP_2_3 + CPOP_2_4;
            CPOP = CPOP_3_1 + CPOP_3_2;
            case(CPOP)
                0: begin
                    alu_out_data = i_data_b;
                end
                1: begin
                    alu_out_data = { i_data_b[14:0], ~(i_data_b[15]) };
                end
                2: begin
                    alu_out_data = { i_data_b[13:0], ~(i_data_b[15:14]) };
                end
                3: begin
                    alu_out_data = { i_data_b[12:0], ~(i_data_b[15:13]) };
                end
                4: begin
                    alu_out_data = { i_data_b[11:0], ~(i_data_b[15:12]) };
                end
                5: begin
                    alu_out_data = { i_data_b[10:0], ~(i_data_b[15:11]) };
                end
                6: begin
                    alu_out_data = { i_data_b[9:0], ~(i_data_b[15:10]) };
                end
                7: begin
                    alu_out_data = { i_data_b[8:0], ~(i_data_b[15:9]) };
                end
                8: begin
                    alu_out_data = { i_data_b[7:0], ~(i_data_b[15:8]) };
                end
                9: begin
                    alu_out_data = { i_data_b[6:0], ~(i_data_b[15:7]) };
                end
                10: begin
                    alu_out_data = { i_data_b[5:0], ~(i_data_b[15:6]) };
                end
                11: begin
                    alu_out_data = { i_data_b[4:0], ~(i_data_b[15:5]) };
                end
                12: begin
                    alu_out_data = { i_data_b[3:0], ~(i_data_b[15:4]) };
                end
                13: begin
                    alu_out_data = { i_data_b[2:0], ~(i_data_b[15:3]) };
                end
                14: begin
                    alu_out_data = { i_data_b[1:0], ~(i_data_b[15:2]) };
                end
                15: begin
                    alu_out_data = { i_data_b[0], ~(i_data_b[15:1]) };
                end
                16: begin
                    alu_out_data = ~i_data_b;
                end
                default: begin
                    alu_out_data = 16'b0000_0000_0000_0000;
                end
            endcase

        end
        LFSR: begin
            lfsr1 = {i_data_a[DATA_W-2:0], (i_data_a[DATA_W-1]^i_data_a[DATA_W-3])^(i_data_a[DATA_W-4]^i_data_a[DATA_W-6])};
            lfsr2 = {lfsr1[DATA_W-2:0], (lfsr1[DATA_W-1]^lfsr1[DATA_W-3])^(lfsr1[DATA_W-4]^lfsr1[DATA_W-6])};
            lfsr3 = {lfsr2[DATA_W-2:0], (lfsr2[DATA_W-1]^lfsr2[DATA_W-3])^(lfsr2[DATA_W-4]^lfsr2[DATA_W-6])};
            lfsr4 = {lfsr3[DATA_W-2:0], (lfsr3[DATA_W-1]^lfsr3[DATA_W-3])^(lfsr3[DATA_W-4]^lfsr3[DATA_W-6])};
            lfsr5 = {lfsr4[DATA_W-2:0], (lfsr4[DATA_W-1]^lfsr4[DATA_W-3])^(lfsr4[DATA_W-4]^lfsr4[DATA_W-6])};
            lfsr6 = {lfsr5[DATA_W-2:0], (lfsr5[DATA_W-1]^lfsr5[DATA_W-3])^(lfsr5[DATA_W-4]^lfsr5[DATA_W-6])};
            lfsr7 = {lfsr6[DATA_W-2:0], (lfsr6[DATA_W-1]^lfsr6[DATA_W-3])^(lfsr6[DATA_W-4]^lfsr6[DATA_W-6])};
            lfsr8 = {lfsr7[DATA_W-2:0], (lfsr7[DATA_W-1]^lfsr7[DATA_W-3])^(lfsr7[DATA_W-4]^lfsr7[DATA_W-6])};
            case (i_data_b)
                0: begin
                    alu_out_data = i_data_a;
                end
                1: begin
                    alu_out_data = lfsr1;
                end
                2: begin
                    alu_out_data = lfsr2;
                end
                3: begin
                    alu_out_data = lfsr3;
                end
                4: begin
                    alu_out_data = lfsr4;
                end
                5: begin
                    alu_out_data = lfsr5;
                end
                6: begin
                    alu_out_data = lfsr6;
                end
                7: begin
                    alu_out_data = lfsr7;
                end
                8: begin
                    alu_out_data = lfsr8;
                end
                default: begin
                    alu_out_data = 16'b0000_0000_0000_0000;
                end
            endcase
        end
        ADD_FP: begin
            i_data_larger = ( i_data_a[14:0] < i_data_b[14:0] ) ? i_data_b : i_data_a ;
            i_data_smaller = ( i_data_a[14:0] < i_data_b[14:0] ) ? i_data_a : i_data_b ;
            fp_m_22_larger = { 2'b01, i_data_larger[9:0], {10{1'b0}} };
            fp_m_22_smaller_before_shift = { 2'b01, i_data_smaller[9:0], {10{1'b0}} };
            case (i_data_larger[14:10] - i_data_smaller[14:10])
                10: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 10;
                end
                9: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 9;
                end
                8: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 8;
                end
                7: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 7;
                end
                6: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 6;
                end
                5: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 5;
                end
                4: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 4;
                end
                3: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 3;
                end
                2: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 2;
                end
                1: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 1;
                end
                0: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift;
                end
                default: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift;
                end 
            endcase

            if(i_data_larger[15] ^ i_data_smaller[15]) begin
                fp_m_result = fp_m_22_larger - fp_m_22_smaller;
            end
            else begin
                fp_m_result = fp_m_22_larger + fp_m_22_smaller;
            end

            if (fp_m_result == 1) begin
                leadingZeros = 21;
            end
            else if (fp_m_result[21:1] == 1) begin
                leadingZeros = 20;
            end
            else if (fp_m_result[21:2] == 1) begin
                leadingZeros = 19;
            end
            else if (fp_m_result[21:3] == 1) begin
                leadingZeros = 18;
            end
            else if (fp_m_result[21:4] == 1) begin
                leadingZeros = 17;
            end
            else if (fp_m_result[21:5] == 1) begin
                leadingZeros = 16;
            end
            else if (fp_m_result[21:6] == 1) begin
                leadingZeros = 15;
            end
            else if (fp_m_result[21:7] == 1) begin
                leadingZeros = 14;
            end
            else if (fp_m_result[21:8] == 1) begin
                leadingZeros = 13;
            end
            else if (fp_m_result[21:9] == 1) begin
                leadingZeros = 12;
            end
            else if (fp_m_result[21:10] == 1) begin
                leadingZeros = 11;
            end
            else if (fp_m_result[21:11] == 1) begin
                leadingZeros = 10;
            end
            else if (fp_m_result[21:12] == 1) begin
                leadingZeros = 9;
            end
            else if (fp_m_result[21:13] == 1) begin
                leadingZeros = 8;
            end
            else if (fp_m_result[21:14] == 1) begin
                leadingZeros = 7;
            end
            else if (fp_m_result[21:15] == 1) begin
                leadingZeros = 6;
            end
            else if (fp_m_result[21:16] == 1) begin
                leadingZeros = 5;
            end
            else if (fp_m_result[21:17] == 1) begin
                leadingZeros = 4;
            end
            else if (fp_m_result[21:18] == 1) begin
                leadingZeros = 3;
            end
            else if (fp_m_result[21:19] == 1) begin
                leadingZeros = 2;
            end
            else if (fp_m_result[21:20] == 1) begin
                leadingZeros = 1;
            end
            else if (fp_m_result[21] == 1) begin
                leadingZeros = 0;
            end
            else begin
                leadingZeros = 0;
            end

            case (leadingZeros)
                21: begin
                    fp_m_result_shifted = {fp_m_result[0], {10{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end 
                20: begin
                    fp_m_result_shifted = {fp_m_result[1:0], {9{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                19: begin
                    fp_m_result_shifted = {fp_m_result[2:0], {8{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                18: begin
                    fp_m_result_shifted = {fp_m_result[3:0], { 7{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                17: begin
                    fp_m_result_shifted = {fp_m_result[4:0], { 6{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                16: begin
                    fp_m_result_shifted = {fp_m_result[5:0], { 5{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                15: begin
                    fp_m_result_shifted = {fp_m_result[6:0], { 4{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                14: begin
                    fp_m_result_shifted = {fp_m_result[7:0], { 3{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                13: begin
                    fp_m_result_shifted = {fp_m_result[8:0], { 2{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                12: begin
                    fp_m_result_shifted = {fp_m_result[9:0], { 1{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                11: begin
                    fp_m_result_shifted = fp_m_result[10:0];
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                10: begin
                    fp_m_result_shifted = fp_m_result[11:1];
                    Gbit = fp_m_result[1];
                    Rbit = fp_m_result[0];
                    stickybit = 0;
                end
                9: begin
                    fp_m_result_shifted = fp_m_result[12:2];
                    Gbit = fp_m_result[2];
                    Rbit = fp_m_result[1];
                    stickybit = (fp_m_result[0]!=0);
                end
                8: begin
                    fp_m_result_shifted = fp_m_result[13:3];
                    Gbit = fp_m_result[3];
                    Rbit = fp_m_result[2];
                    stickybit = (fp_m_result[1:0]!=0);
                end
                7: begin
                    fp_m_result_shifted = fp_m_result[14:4];
                    Gbit = fp_m_result[4];
                    Rbit = fp_m_result[3];
                    stickybit = (fp_m_result[2:0]!=0);
                end
                6: begin
                    fp_m_result_shifted = fp_m_result[15:5];
                    Gbit = fp_m_result[5];
                    Rbit = fp_m_result[4];
                    stickybit = (fp_m_result[3:0]!=0);
                end
                5: begin
                    fp_m_result_shifted = fp_m_result[16:6];
                    Gbit = fp_m_result[6];
                    Rbit = fp_m_result[5];
                    stickybit = (fp_m_result[4:0]!=0);
                end
                4: begin
                    fp_m_result_shifted = fp_m_result[17:7];
                    Gbit = fp_m_result[7];
                    Rbit = fp_m_result[6];
                    stickybit = (fp_m_result[5:0]!=0);
                end
                3: begin
                    fp_m_result_shifted = fp_m_result[18:8];
                    Gbit = fp_m_result[8];
                    Rbit = fp_m_result[7];
                    stickybit = (fp_m_result[6:0]!=0);
                end
                2: begin
                    fp_m_result_shifted = fp_m_result[19:9];
                    Gbit = fp_m_result[9];
                    Rbit = fp_m_result[8];
                    stickybit = (fp_m_result[7:0]!=0);
                end
                1: begin
                    fp_m_result_shifted = fp_m_result[20:10];
                    Gbit = fp_m_result[10];
                    Rbit = fp_m_result[9];
                    stickybit = (fp_m_result[8:0]!=0);
                end
                0: begin
                    fp_m_result_shifted = fp_m_result[21:11];
                    Gbit = fp_m_result[11];
                    Rbit = fp_m_result[10];
                    stickybit = (fp_m_result[9:0]!=0);
                end
                default: begin
                    fp_m_result_shifted = fp_m_result[21:11];
                    Gbit = fp_m_result[11];
                    Rbit = fp_m_result[10];
                    stickybit = (fp_m_result[9:0]!=0);
                end
            endcase

            if (Rbit & (stickybit | Gbit)) begin
                if (fp_m_result_shifted == 11'b111_1111_1111) begin
                    alu_out_data[14:10] = i_data_larger[14:10] - leadingZeros + 2;
                end
                else begin
                    alu_out_data[14:10] = i_data_larger[14:10] - leadingZeros + 1;
                end
                fp_m_result_rounded = fp_m_result_shifted + 1;
            end
            else begin
                alu_out_data[14:10] = i_data_larger[14:10] - leadingZeros + 1;
                fp_m_result_rounded = fp_m_result_shifted;
            end
            alu_out_data[9:0] = fp_m_result_rounded[9:0];
            alu_out_data[15] = i_data_larger[15];
        end
        SUB_FP: begin
            i_data_b_neg = {~i_data_b[15], i_data_b[14:0]};
            i_data_larger = ( i_data_a[14:0] < i_data_b[14:0] ) ? i_data_b_neg : i_data_a ;
            i_data_smaller = ( i_data_a[14:0] < i_data_b[14:0] ) ? i_data_a : i_data_b_neg ;
            fp_m_22_larger = { 2'b01, i_data_larger[9:0], {10{1'b0}} };
            fp_m_22_smaller_before_shift = { 2'b01, i_data_smaller[9:0], {10{1'b0}} };
            case (i_data_larger[14:10] - i_data_smaller[14:10])
                10: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 10;
                end
                9: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 9;
                end
                8: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 8;
                end
                7: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 7;
                end
                6: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 6;
                end
                5: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 5;
                end
                4: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 4;
                end
                3: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 3;
                end
                2: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 2;
                end
                1: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift >> 1;
                end
                0: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift;
                end
                default: begin
                    fp_m_22_smaller = fp_m_22_smaller_before_shift;
                end 
            endcase

            if(i_data_larger[15] ^ i_data_smaller[15]) begin
                fp_m_result = fp_m_22_larger - fp_m_22_smaller;
            end
            else begin
                fp_m_result = fp_m_22_larger + fp_m_22_smaller;
            end

            if (fp_m_result == 1) begin
                leadingZeros = 21;
            end
            else if (fp_m_result[21:1] == 1) begin
                leadingZeros = 20;
            end
            else if (fp_m_result[21:2] == 1) begin
                leadingZeros = 19;
            end
            else if (fp_m_result[21:3] == 1) begin
                leadingZeros = 18;
            end
            else if (fp_m_result[21:4] == 1) begin
                leadingZeros = 17;
            end
            else if (fp_m_result[21:5] == 1) begin
                leadingZeros = 16;
            end
            else if (fp_m_result[21:6] == 1) begin
                leadingZeros = 15;
            end
            else if (fp_m_result[21:7] == 1) begin
                leadingZeros = 14;
            end
            else if (fp_m_result[21:8] == 1) begin
                leadingZeros = 13;
            end
            else if (fp_m_result[21:9] == 1) begin
                leadingZeros = 12;
            end
            else if (fp_m_result[21:10] == 1) begin
                leadingZeros = 11;
            end
            else if (fp_m_result[21:11] == 1) begin
                leadingZeros = 10;
            end
            else if (fp_m_result[21:12] == 1) begin
                leadingZeros = 9;
            end
            else if (fp_m_result[21:13] == 1) begin
                leadingZeros = 8;
            end
            else if (fp_m_result[21:14] == 1) begin
                leadingZeros = 7;
            end
            else if (fp_m_result[21:15] == 1) begin
                leadingZeros = 6;
            end
            else if (fp_m_result[21:16] == 1) begin
                leadingZeros = 5;
            end
            else if (fp_m_result[21:17] == 1) begin
                leadingZeros = 4;
            end
            else if (fp_m_result[21:18] == 1) begin
                leadingZeros = 3;
            end
            else if (fp_m_result[21:19] == 1) begin
                leadingZeros = 2;
            end
            else if (fp_m_result[21:20] == 1) begin
                leadingZeros = 1;
            end
            else if (fp_m_result[21] == 1) begin
                leadingZeros = 0;
            end
            else begin
                leadingZeros = 0;
            end

            case (leadingZeros)
                21: begin
                    fp_m_result_shifted = {fp_m_result[0], {10{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end 
                20: begin
                    fp_m_result_shifted = {fp_m_result[1:0], {9{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                19: begin
                    fp_m_result_shifted = {fp_m_result[2:0], {8{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                18: begin
                    fp_m_result_shifted = {fp_m_result[3:0], { 7{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                17: begin
                    fp_m_result_shifted = {fp_m_result[4:0], { 6{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                16: begin
                    fp_m_result_shifted = {fp_m_result[5:0], { 5{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                15: begin
                    fp_m_result_shifted = {fp_m_result[6:0], { 4{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                14: begin
                    fp_m_result_shifted = {fp_m_result[7:0], { 3{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                13: begin
                    fp_m_result_shifted = {fp_m_result[8:0], { 2{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                12: begin
                    fp_m_result_shifted = {fp_m_result[9:0], { 1{1'b0}}};
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                11: begin
                    fp_m_result_shifted = fp_m_result[10:0];
                    Gbit = fp_m_result[0];
                    Rbit = 0;
                    stickybit = 0;
                end
                10: begin
                    fp_m_result_shifted = fp_m_result[11:1];
                    Gbit = fp_m_result[1];
                    Rbit = fp_m_result[0];
                    stickybit = 0;
                end
                9: begin
                    fp_m_result_shifted = fp_m_result[12:2];
                    Gbit = fp_m_result[2];
                    Rbit = fp_m_result[1];
                    stickybit = (fp_m_result[0]!=0);
                end
                8: begin
                    fp_m_result_shifted = fp_m_result[13:3];
                    Gbit = fp_m_result[3];
                    Rbit = fp_m_result[2];
                    stickybit = (fp_m_result[1:0]!=0);
                end
                7: begin
                    fp_m_result_shifted = fp_m_result[14:4];
                    Gbit = fp_m_result[4];
                    Rbit = fp_m_result[3];
                    stickybit = (fp_m_result[2:0]!=0);
                end
                6: begin
                    fp_m_result_shifted = fp_m_result[15:5];
                    Gbit = fp_m_result[5];
                    Rbit = fp_m_result[4];
                    stickybit = (fp_m_result[3:0]!=0);
                end
                5: begin
                    fp_m_result_shifted = fp_m_result[16:6];
                    Gbit = fp_m_result[6];
                    Rbit = fp_m_result[5];
                    stickybit = (fp_m_result[4:0]!=0);
                end
                4: begin
                    fp_m_result_shifted = fp_m_result[17:7];
                    Gbit = fp_m_result[7];
                    Rbit = fp_m_result[6];
                    stickybit = (fp_m_result[5:0]!=0);
                end
                3: begin
                    fp_m_result_shifted = fp_m_result[18:8];
                    Gbit = fp_m_result[8];
                    Rbit = fp_m_result[7];
                    stickybit = (fp_m_result[6:0]!=0);
                end
                2: begin
                    fp_m_result_shifted = fp_m_result[19:9];
                    Gbit = fp_m_result[9];
                    Rbit = fp_m_result[8];
                    stickybit = (fp_m_result[7:0]!=0);
                end
                1: begin
                    fp_m_result_shifted = fp_m_result[20:10];
                    Gbit = fp_m_result[10];
                    Rbit = fp_m_result[9];
                    stickybit = (fp_m_result[8:0]!=0);
                end
                0: begin
                    fp_m_result_shifted = fp_m_result[21:11];
                    Gbit = fp_m_result[11];
                    Rbit = fp_m_result[10];
                    stickybit = (fp_m_result[9:0]!=0);
                end
                default: begin
                    fp_m_result_shifted = fp_m_result[21:11];
                    Gbit = fp_m_result[11];
                    Rbit = fp_m_result[10];
                    stickybit = (fp_m_result[9:0]!=0);
                end
            endcase
            if (Rbit & (stickybit | Gbit)) begin
                if (fp_m_result_shifted == 11'b111_1111_1111) begin
                    alu_out_data[14:10] = i_data_larger[14:10] - leadingZeros + 2;
                end
                else begin
                    alu_out_data[14:10] = i_data_larger[14:10] - leadingZeros + 1;
                end
                fp_m_result_rounded = fp_m_result_shifted + 1;
            end
            else begin
                alu_out_data[14:10] = i_data_larger[14:10] - leadingZeros + 1;
                fp_m_result_rounded = fp_m_result_shifted;
            end
            alu_out_data[9:0] = fp_m_result_rounded[9:0];
            alu_out_data[15] = i_data_larger[15];
        end
        default: begin
            alu_out_data = 16'b0000_0000_0000_0000;
        end
    endcase
end

// ----------------------------------------------------------------------------
// Sequential Part: Current-state (CS)
// ----------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        cur_state <= BEFORE_INPUT;
        o_valid_r <= 1'b0;
        o_busy_r <= 1'b1;
        o_data_r <= 0;
    end else begin
        cur_state <= nxt_state;
        o_valid_r <= o_valid_w;
        o_busy_r <= o_busy_w;
        o_data_r <= o_data_w;
    end
end
endmodule
