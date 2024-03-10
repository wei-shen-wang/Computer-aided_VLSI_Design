module core #( // DO NOT MODIFY!!!
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (   
    input                    i_clk,
    input                    i_rst_n,
    output  [ADDR_WIDTH-1:0] o_i_addr,
    input   [INST_WIDTH-1:0] i_i_inst,
    output                   o_d_we,
    output  [ADDR_WIDTH-1:0] o_d_addr,
    output  [DATA_WIDTH-1:0] o_d_wdata,
    input   [DATA_WIDTH-1:0] i_d_rdata,
    output  [           1:0] o_status,
    output                   o_status_valid
);

// ----------------------------------------------------------------------------
// parameters: Definition of State
// ----------------------------------------------------------------------------
parameter S_IDLE = 3'd0;
parameter S_FETCH = 3'd1;
parameter S_DECODE = 3'd2;
parameter S_EXECUTE = 3'd3;
parameter S_WRITEBACK = 3'd4;
parameter S_NEXT_PC = 3'd5;
parameter S_END = 3'd6;

parameter R_TYPE_INST = 2'd0;
parameter I_TYPE_INST = 2'd1;
parameter EOF_TYPE_INST = 2'd2;

integer i;

// ----------------------------------------------------------------------------
// wires and registers declaration
// ----------------------------------------------------------------------------
reg [5:0] opcode;
reg [4:0] r_s2, r_s3, r_s1, i_s1, i_s2;
reg [15:0] i_imm;

reg [31:0] register_file [0:31], next_register_file [0:31];
reg signed [ADDR_WIDTH-1:0] curr_pc, next_pc;
reg [2:0] curr_state, next_state;
reg o_d_we_w, o_d_we_r;
reg [ADDR_WIDTH-1:0] o_d_addr_w, o_d_addr_r;
reg [31:0] o_d_wdata_w, o_d_wdata_r;
reg [2:0] o_status_w, o_status_r;
reg o_status_valid_w, o_status_valid_r;
reg [1:0] instruction_type;

reg signed [31:0] alu_out;
reg signed [63:0] alu_mul_reg;

reg eof_true, overflow_true, branch_true;

reg pc_overflow, arithmetic_overflow, data_address_overflow;

reg signed [31:0] second_operand_negated;
reg signed [31:0] data_larger;
reg signed [31:0] data_smaller;
reg [34:0] fp_mantissa_larger, fp_mantissa_smaller_before_shift, fp_mantissa_smaller;
reg [34:0] fp_mantissa_result;
reg [23:0] fp_mantissa_result_shifted;
reg [23:0] fp_mantissa_result_shifted_rounded;
reg [23:0] fp_mul_1st_operand_mantissa;
reg [23:0] fp_mul_2nd_operand_mantissa;
reg [47:0] fp_mul_result_mantissa;
reg sticky_bit;
reg Rbit;
reg Gbit;
reg [5:0] leadingZeros;

// ----------------------------------------------------------------------------
// wire assignment: continuous assignments 
// ----------------------------------------------------------------------------
assign o_status = o_status_r;
assign o_status_valid = o_status_valid_r;
assign o_i_addr = curr_pc;
assign o_d_we = o_d_we_r;
assign o_d_addr = o_d_addr_r;
assign o_d_wdata = o_d_wdata_r;

// ----------------------------------------------------------------------------
// Combinational Part: Output-logic (OL)
// Combinational Part: Next-state logic (NL)
// ----------------------------------------------------------------------------

// write data memory enable
always @(*) begin
    o_d_we_w = (opcode==`OP_SW) ? 1 : 0;
end

// output status
always @(*) begin
    o_status_w = o_status_r;
    if(eof_true) begin
        o_status_w = `MIPS_END;
    end 
    else if(overflow_true) begin
        o_status_w = `MIPS_OVERFLOW;
    end 
    else if((curr_state == S_NEXT_PC) || (curr_state == S_END)) begin
        case (instruction_type)
            R_TYPE_INST: o_status_w = `R_TYPE_SUCCESS;
            I_TYPE_INST: o_status_w = `I_TYPE_SUCCESS;
        endcase
    end
end

// output status valid
always @(*) begin
    if((curr_state == S_NEXT_PC) || (curr_state == S_END)) begin
        o_status_valid_w = 1;
    end
    else begin
        o_status_valid_w = 0;
    end
end

// overflow
always @(*) begin
    if (pc_overflow || arithmetic_overflow || data_address_overflow) begin
        overflow_true = 1;
    end else begin
        overflow_true = 0;
    end
end

// decoding instruction parameters
always @(*) begin
    opcode = i_i_inst[31:26];
    r_s2 = i_i_inst[25:21];
    r_s3 = i_i_inst[20:16];
    r_s1 = i_i_inst[15:11];
    i_s2 = i_i_inst[25:21];
    i_s1 = i_i_inst[20:16];
    i_imm = i_i_inst[15:0];
end

// decoding instruction type
always @(*) begin
    case (opcode)
        `OP_ADD: instruction_type = R_TYPE_INST;
        `OP_SUB: instruction_type = R_TYPE_INST;
        `OP_MUL: instruction_type = R_TYPE_INST;
        `OP_FP_ADD: instruction_type = R_TYPE_INST;
        `OP_FP_SUB: instruction_type = R_TYPE_INST;
        `OP_FP_MUL: instruction_type = R_TYPE_INST;
        `OP_ADDI: instruction_type = I_TYPE_INST;
        `OP_LW: instruction_type = I_TYPE_INST;
        `OP_SW: instruction_type = I_TYPE_INST;
        `OP_AND: instruction_type = R_TYPE_INST;
        `OP_OR: instruction_type = R_TYPE_INST;
        `OP_NOR: instruction_type = R_TYPE_INST;
        `OP_BEQ: instruction_type = I_TYPE_INST;
        `OP_BNE: instruction_type = I_TYPE_INST;
        `OP_SLT: instruction_type = R_TYPE_INST;
        `OP_SLL: instruction_type = R_TYPE_INST;
        `OP_SRL: instruction_type = R_TYPE_INST;
        `OP_EOF: instruction_type = EOF_TYPE_INST;
        default: instruction_type = R_TYPE_INST;
    endcase
end 

// EXECUTING
always @(*) begin
    arithmetic_overflow = 0;
    data_address_overflow = 0;
    branch_true = 0;
    alu_out = 0;
    alu_mul_reg = 0;
    second_operand_negated = 0;
    data_larger = 0;
    data_smaller = 0;
    fp_mantissa_larger = 0;
    fp_mantissa_smaller_before_shift = 0;
    fp_mantissa_smaller = 0;
    fp_mantissa_result = 0;
    fp_mantissa_result_shifted = 0;
    fp_mantissa_result_shifted_rounded = 0;
    sticky_bit = 0;
    Rbit = 0;
    Gbit = 0;
    leadingZeros = 0;
    fp_mul_result_mantissa = 0;
    fp_mul_1st_operand_mantissa = 0;
    fp_mul_2nd_operand_mantissa = 0;
    case (opcode)
        `OP_ADD : begin
            alu_out = $signed(register_file[r_s2]) + $signed(register_file[r_s3]);
            if ((alu_out[31] != register_file[r_s2][31]) && (register_file[r_s2][31] == register_file[r_s3][31])) begin
                arithmetic_overflow = 1;
            end
        end 
        `OP_SUB : begin
            alu_out = $signed(register_file[r_s2]) - $signed(register_file[r_s3]);
            if ((alu_out[31] != register_file[r_s2][31]) && (register_file[r_s2][31] != register_file[r_s3][31])) begin
                arithmetic_overflow = 1;
            end
        end
        `OP_MUL : begin
            alu_mul_reg = $signed(register_file[r_s2]) * $signed(register_file[r_s3]);
            alu_out = alu_mul_reg[31:0];
            if (alu_mul_reg[31] != (register_file[r_s2][31] ^ register_file[r_s3][31])) begin
                arithmetic_overflow = 1;
            end
        end
        `OP_FP_ADD : begin
            data_larger = ( register_file[r_s2][30:0] > register_file[r_s3][30:0] ) ? register_file[r_s2] : register_file[r_s3];
            data_smaller = ( register_file[r_s2][30:0] > register_file[r_s3][30:0] ) ? register_file[r_s3] : register_file[r_s2];
            fp_mantissa_larger = { 2'b01, data_larger[22:0], {10{1'b0}} };
            fp_mantissa_smaller_before_shift = { 2'b01, data_smaller[22:0], {10{1'b0}} };
            fp_mantissa_smaller = fp_mantissa_smaller_before_shift >> (data_larger[30:23] - data_smaller[30:23]);
            fp_mantissa_result = ( data_larger[31] == data_smaller[31] ) ? ( fp_mantissa_larger + fp_mantissa_smaller ) : ( fp_mantissa_larger - fp_mantissa_smaller );
            if (fp_mantissa_result == 1) begin
                leadingZeros = 34;
            end
            else if (fp_mantissa_result[34:1] == 1) begin
                leadingZeros = 33;
            end
            else if (fp_mantissa_result[34:2] == 1) begin
                leadingZeros = 32;
            end
            else if (fp_mantissa_result[34:3] == 1) begin
                leadingZeros = 31;
            end
            else if (fp_mantissa_result[34:4] == 1) begin
                leadingZeros = 30;
            end
            else if (fp_mantissa_result[34:5] == 1) begin
                leadingZeros = 29;
            end
            else if (fp_mantissa_result[34:6] == 1) begin
                leadingZeros = 28;
            end
            else if (fp_mantissa_result[34:7] == 1) begin
                leadingZeros = 27;
            end
            else if (fp_mantissa_result[34:8] == 1) begin
                leadingZeros = 26;
            end
            else if (fp_mantissa_result[34:9] == 1) begin
                leadingZeros = 25;
            end
            else if (fp_mantissa_result[34:10] == 1) begin
                leadingZeros = 24;
            end
            else if (fp_mantissa_result[34:11] == 1) begin
                leadingZeros = 23;
            end
            else if (fp_mantissa_result[34:12] == 1) begin
                leadingZeros = 22;
            end
            else if (fp_mantissa_result[34:13] == 1) begin
                leadingZeros = 21;
            end
            else if (fp_mantissa_result[34:14] == 1) begin
                leadingZeros = 20;
            end
            else if (fp_mantissa_result[34:15] == 1) begin
                leadingZeros = 19;
            end
            else if (fp_mantissa_result[34:16] == 1) begin
                leadingZeros = 18;
            end
            else if (fp_mantissa_result[34:17] == 1) begin
                leadingZeros = 17;
            end
            else if (fp_mantissa_result[34:18] == 1) begin
                leadingZeros = 16;
            end
            else if (fp_mantissa_result[34:19] == 1) begin
                leadingZeros = 15;
            end
            else if (fp_mantissa_result[34:20] == 1) begin
                leadingZeros = 14;
            end
            else if (fp_mantissa_result[34:21] == 1) begin
                leadingZeros = 13;
            end
            else if (fp_mantissa_result[34:22] == 1) begin
                leadingZeros = 12;
            end
            else if (fp_mantissa_result[34:23] == 1) begin
                leadingZeros = 11;
            end
            else if (fp_mantissa_result[34:24] == 1) begin
                leadingZeros = 10;
            end
            else if (fp_mantissa_result[34:25] == 1) begin
                leadingZeros = 9;
            end
            else if (fp_mantissa_result[34:26] == 1) begin
                leadingZeros = 8;
            end
            else if (fp_mantissa_result[34:27] == 1) begin
                leadingZeros = 7;
            end
            else if (fp_mantissa_result[34:28] == 1) begin
                leadingZeros = 6;
            end
            else if (fp_mantissa_result[34:29] == 1) begin
                leadingZeros = 5;
            end
            else if (fp_mantissa_result[34:30] == 1) begin
                leadingZeros = 4;
            end
            else if (fp_mantissa_result[34:31] == 1) begin
                leadingZeros = 3;
            end
            else if (fp_mantissa_result[34:32] == 1) begin
                leadingZeros = 2;
            end
            else if (fp_mantissa_result[34:33] == 1) begin
                leadingZeros = 1;
            end
            else if (fp_mantissa_result[34] == 1) begin
                leadingZeros = 0;
            end
            else begin
                leadingZeros = 0;
            end

            case (leadingZeros)
                34: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[0], {23{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                33: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[1:0], {22{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                32: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[2:0], {21{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                31: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[3:0], {20{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                30: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[4:0], {19{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                29: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[5:0], {18{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                28: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[6:0], {17{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                27: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[7:0], {16{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                26: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[8:0], {15{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                25: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[9:0], {14{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                24: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[10:0], {13{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                23: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[11:0], {12{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                22: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[12:0], {11{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                21: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[13:0], {10{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                20: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[14:0], {9{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                19: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[15:0], {8{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                18: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[16:0], {7{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                17: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[17:0], {6{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                16: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[18:0], {5{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                15: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[19:0], {4{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                14: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[20:0], {3{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                13: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[21:0], {2{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                12: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[22:0], {1{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                11: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[23:0];
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                10: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[24:1];
                    Gbit = fp_mantissa_result[1];
                    Rbit = fp_mantissa_result[0];
                    sticky_bit = 0;
                end
                9: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[25:2];
                    Gbit = fp_mantissa_result[2];
                    Rbit = fp_mantissa_result[1];
                    sticky_bit = (fp_mantissa_result[0] != 0);
                end
                8: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[26:3];
                    Gbit = fp_mantissa_result[3];
                    Rbit = fp_mantissa_result[2];
                    sticky_bit = (fp_mantissa_result[1:0] != 0);
                end
                7: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[27:4];
                    Gbit = fp_mantissa_result[4];
                    Rbit = fp_mantissa_result[3];
                    sticky_bit = (fp_mantissa_result[2:0] != 0);
                end
                6: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[28:5];
                    Gbit = fp_mantissa_result[5];
                    Rbit = fp_mantissa_result[4];
                    sticky_bit = (fp_mantissa_result[3:0] != 0);
                end
                5: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[29:6];
                    Gbit = fp_mantissa_result[6];
                    Rbit = fp_mantissa_result[5];
                    sticky_bit = (fp_mantissa_result[4:0] != 0);
                end
                4: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[30:7];
                    Gbit = fp_mantissa_result[7];
                    Rbit = fp_mantissa_result[6];
                    sticky_bit = (fp_mantissa_result[5:0] != 0);
                end
                3: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[31:8];
                    Gbit = fp_mantissa_result[8];
                    Rbit = fp_mantissa_result[7];
                    sticky_bit = (fp_mantissa_result[6:0] != 0);
                end
                2: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[32:9];
                    Gbit = fp_mantissa_result[9];
                    Rbit = fp_mantissa_result[8];
                    sticky_bit = (fp_mantissa_result[7:0] != 0);
                end
                1: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[33:10];
                    Gbit = fp_mantissa_result[10];
                    Rbit = fp_mantissa_result[9];
                    sticky_bit = (fp_mantissa_result[8:0] != 0);
                end
                0: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[34:11];
                    Gbit = fp_mantissa_result[11];
                    Rbit = fp_mantissa_result[10];
                    sticky_bit = (fp_mantissa_result[9:0] != 0);
                end
                default: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[34:11];
                    Gbit = fp_mantissa_result[11];
                    Rbit = fp_mantissa_result[10];
                    sticky_bit = (fp_mantissa_result[9:0] != 0);
                end
            endcase

            if (Rbit & (sticky_bit | Gbit)) begin
                if (fp_mantissa_result_shifted == 24'b1111_1111_1111_1111_1111_1111) begin
                    alu_out[30:23] = data_larger[30:23] - leadingZeros + 2;
                end
                else begin
                    alu_out[30:23] = data_larger[30:23] - leadingZeros + 1;
                end
                fp_mantissa_result_shifted_rounded = fp_mantissa_result_shifted + 1;
            end
            else begin
                alu_out[30:23] = data_larger[30:23] - leadingZeros + 1;
                fp_mantissa_result_shifted_rounded = fp_mantissa_result_shifted;
            end
            alu_out[22:0] = fp_mantissa_result_shifted_rounded[22:0];
            alu_out[31] = data_larger[31];
        end
        `OP_FP_SUB : begin
            second_operand_negated = { ~register_file[r_s3][31], register_file[r_s3][30:0] };
            data_larger = ( register_file[r_s2][30:0] > register_file[r_s3][30:0] ) ? register_file[r_s2] : second_operand_negated;
            data_smaller = ( register_file[r_s2][30:0] > register_file[r_s3][30:0] ) ? second_operand_negated : register_file[r_s2];
            fp_mantissa_larger = { 2'b01, data_larger[22:0], {10{1'b0}} };
            fp_mantissa_smaller_before_shift = { 2'b01, data_smaller[22:0], {10{1'b0}} };
            fp_mantissa_smaller = fp_mantissa_smaller_before_shift >> (data_larger[30:23] - data_smaller[30:23]);
            fp_mantissa_result = ( data_larger[31] == data_smaller[31] ) ? ( fp_mantissa_larger + fp_mantissa_smaller ) : ( fp_mantissa_larger - fp_mantissa_smaller );
            if (fp_mantissa_result == 1) begin
                leadingZeros = 34;
            end
            else if (fp_mantissa_result[34:1] == 1) begin
                leadingZeros = 33;
            end
            else if (fp_mantissa_result[34:2] == 1) begin
                leadingZeros = 32;
            end
            else if (fp_mantissa_result[34:3] == 1) begin
                leadingZeros = 31;
            end
            else if (fp_mantissa_result[34:4] == 1) begin
                leadingZeros = 30;
            end
            else if (fp_mantissa_result[34:5] == 1) begin
                leadingZeros = 29;
            end
            else if (fp_mantissa_result[34:6] == 1) begin
                leadingZeros = 28;
            end
            else if (fp_mantissa_result[34:7] == 1) begin
                leadingZeros = 27;
            end
            else if (fp_mantissa_result[34:8] == 1) begin
                leadingZeros = 26;
            end
            else if (fp_mantissa_result[34:9] == 1) begin
                leadingZeros = 25;
            end
            else if (fp_mantissa_result[34:10] == 1) begin
                leadingZeros = 24;
            end
            else if (fp_mantissa_result[34:11] == 1) begin
                leadingZeros = 23;
            end
            else if (fp_mantissa_result[34:12] == 1) begin
                leadingZeros = 22;
            end
            else if (fp_mantissa_result[34:13] == 1) begin
                leadingZeros = 21;
            end
            else if (fp_mantissa_result[34:14] == 1) begin
                leadingZeros = 20;
            end
            else if (fp_mantissa_result[34:15] == 1) begin
                leadingZeros = 19;
            end
            else if (fp_mantissa_result[34:16] == 1) begin
                leadingZeros = 18;
            end
            else if (fp_mantissa_result[34:17] == 1) begin
                leadingZeros = 17;
            end
            else if (fp_mantissa_result[34:18] == 1) begin
                leadingZeros = 16;
            end
            else if (fp_mantissa_result[34:19] == 1) begin
                leadingZeros = 15;
            end
            else if (fp_mantissa_result[34:20] == 1) begin
                leadingZeros = 14;
            end
            else if (fp_mantissa_result[34:21] == 1) begin
                leadingZeros = 13;
            end
            else if (fp_mantissa_result[34:22] == 1) begin
                leadingZeros = 12;
            end
            else if (fp_mantissa_result[34:23] == 1) begin
                leadingZeros = 11;
            end
            else if (fp_mantissa_result[34:24] == 1) begin
                leadingZeros = 10;
            end
            else if (fp_mantissa_result[34:25] == 1) begin
                leadingZeros = 9;
            end
            else if (fp_mantissa_result[34:26] == 1) begin
                leadingZeros = 8;
            end
            else if (fp_mantissa_result[34:27] == 1) begin
                leadingZeros = 7;
            end
            else if (fp_mantissa_result[34:28] == 1) begin
                leadingZeros = 6;
            end
            else if (fp_mantissa_result[34:29] == 1) begin
                leadingZeros = 5;
            end
            else if (fp_mantissa_result[34:30] == 1) begin
                leadingZeros = 4;
            end
            else if (fp_mantissa_result[34:31] == 1) begin
                leadingZeros = 3;
            end
            else if (fp_mantissa_result[34:32] == 1) begin
                leadingZeros = 2;
            end
            else if (fp_mantissa_result[34:33] == 1) begin
                leadingZeros = 1;
            end
            else if (fp_mantissa_result[34] == 1) begin
                leadingZeros = 0;
            end
            else begin
                leadingZeros = 0;
            end

            case (leadingZeros)
                34: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[0], {23{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                33: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[1:0], {22{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                32: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[2:0], {21{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                31: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[3:0], {20{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                30: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[4:0], {19{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                29: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[5:0], {18{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                28: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[6:0], {17{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                27: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[7:0], {16{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                26: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[8:0], {15{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                25: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[9:0], {14{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                24: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[10:0], {13{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                23: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[11:0], {12{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                22: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[12:0], {11{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                21: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[13:0], {10{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                20: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[14:0], {9{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                19: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[15:0], {8{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                18: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[16:0], {7{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                17: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[17:0], {6{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                16: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[18:0], {5{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                15: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[19:0], {4{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                14: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[20:0], {3{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                13: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[21:0], {2{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                12: begin
                    fp_mantissa_result_shifted = {fp_mantissa_result[22:0], {1{1'b0}}};
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                11: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[23:0];
                    Gbit = fp_mantissa_result[0];
                    Rbit = 0;
                    sticky_bit = 0;
                end
                10: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[24:1];
                    Gbit = fp_mantissa_result[1];
                    Rbit = fp_mantissa_result[0];
                    sticky_bit = 0;
                end
                9: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[25:2];
                    Gbit = fp_mantissa_result[2];
                    Rbit = fp_mantissa_result[1];
                    sticky_bit = (fp_mantissa_result[0] != 0);
                end
                8: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[26:3];
                    Gbit = fp_mantissa_result[3];
                    Rbit = fp_mantissa_result[2];
                    sticky_bit = (fp_mantissa_result[1:0] != 0);
                end
                7: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[27:4];
                    Gbit = fp_mantissa_result[4];
                    Rbit = fp_mantissa_result[3];
                    sticky_bit = (fp_mantissa_result[2:0] != 0);
                end
                6: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[28:5];
                    Gbit = fp_mantissa_result[5];
                    Rbit = fp_mantissa_result[4];
                    sticky_bit = (fp_mantissa_result[3:0] != 0);
                end
                5: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[29:6];
                    Gbit = fp_mantissa_result[6];
                    Rbit = fp_mantissa_result[5];
                    sticky_bit = (fp_mantissa_result[4:0] != 0);
                end
                4: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[30:7];
                    Gbit = fp_mantissa_result[7];
                    Rbit = fp_mantissa_result[6];
                    sticky_bit = (fp_mantissa_result[5:0] != 0);
                end
                3: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[31:8];
                    Gbit = fp_mantissa_result[8];
                    Rbit = fp_mantissa_result[7];
                    sticky_bit = (fp_mantissa_result[6:0] != 0);
                end
                2: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[32:9];
                    Gbit = fp_mantissa_result[9];
                    Rbit = fp_mantissa_result[8];
                    sticky_bit = (fp_mantissa_result[7:0] != 0);
                end
                1: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[33:10];
                    Gbit = fp_mantissa_result[10];
                    Rbit = fp_mantissa_result[9];
                    sticky_bit = (fp_mantissa_result[8:0] != 0);
                end
                0: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[34:11];
                    Gbit = fp_mantissa_result[11];
                    Rbit = fp_mantissa_result[10];
                    sticky_bit = (fp_mantissa_result[9:0] != 0);
                end
                default: begin
                    fp_mantissa_result_shifted = fp_mantissa_result[34:11];
                    Gbit = fp_mantissa_result[11];
                    Rbit = fp_mantissa_result[10];
                    sticky_bit = (fp_mantissa_result[9:0] != 0);
                end
            endcase

            if (Rbit & (sticky_bit | Gbit)) begin
                if (fp_mantissa_result_shifted == 24'b1111_1111_1111_1111_1111_1111) begin
                    alu_out[30:23] = data_larger[30:23] - leadingZeros + 2;
                end
                else begin
                    alu_out[30:23] = data_larger[30:23] - leadingZeros + 1;
                end
                fp_mantissa_result_shifted_rounded = fp_mantissa_result_shifted + 1;
            end
            else begin
                alu_out[30:23] = data_larger[30:23] - leadingZeros + 1;
                fp_mantissa_result_shifted_rounded = fp_mantissa_result_shifted;
            end
            alu_out[22:0] = fp_mantissa_result_shifted_rounded[22:0];
            alu_out[31] = data_larger[31];
        end
        `OP_FP_MUL : begin
            fp_mul_1st_operand_mantissa = { 1'b1, register_file[r_s2][22:0]};
            fp_mul_2nd_operand_mantissa = { 1'b1, register_file[r_s3][22:0]};
            fp_mul_result_mantissa = fp_mul_1st_operand_mantissa * fp_mul_2nd_operand_mantissa;
            if (fp_mul_result_mantissa[47] == 1'b1) begin
                fp_mantissa_result_shifted = fp_mul_result_mantissa[47:24];
                Gbit = fp_mul_result_mantissa[24];
                Rbit = fp_mul_result_mantissa[23];
                sticky_bit = (fp_mul_result_mantissa[22:0] != 0);
            end
            else begin
                fp_mantissa_result_shifted = fp_mul_result_mantissa[46:23];
                Gbit = fp_mul_result_mantissa[23];
                Rbit = fp_mul_result_mantissa[22];
                sticky_bit = (fp_mul_result_mantissa[21:0] != 0);
            end
            if (Rbit & ( sticky_bit | Gbit )) begin
                if (fp_mantissa_result_shifted == 24'b1111_1111_1111_1111_1111_1111 ) begin
                    alu_out[30:23] = register_file[r_s2][30:23] + register_file[r_s3][30:23] - 126;
                end
                else begin
                    alu_out[30:23] = register_file[r_s2][30:23] + register_file[r_s3][30:23] - 127;
                end
                fp_mantissa_result_shifted_rounded = fp_mantissa_result_shifted + 1;
            end
            else begin
                alu_out[30:23] = register_file[r_s2][30:23] + register_file[r_s3][30:23] - 127;
                fp_mantissa_result_shifted_rounded = fp_mantissa_result_shifted;
            end
            alu_out[22:0] = fp_mantissa_result_shifted_rounded[22:0];
            alu_out[31] = register_file[r_s2][31] ^ register_file[r_s3][31];
        end
        `OP_ADDI : begin
            alu_out = $signed(register_file[i_s2]) + $signed({{16{i_imm[15]}}, i_imm});
            if ( (alu_out[31] != register_file[i_s2][31]) && (register_file[i_s2][31] == i_imm[15])) begin
                arithmetic_overflow = 1;
            end
        end
        `OP_LW : begin
            alu_out = $signed(register_file[i_s2]) + $signed({{16{i_imm[15]}}, i_imm}); // alu_out is only an address here
            if ((alu_out[31] == 1) || (alu_out[31] != register_file[i_s2][31]) && (register_file[i_s2][31] == i_imm[15])) begin
                data_address_overflow = 1;
            end
            else if (alu_out > 252) begin
                data_address_overflow = 1;
            end
        end
        `OP_SW : begin
            alu_out = $signed(register_file[i_s2]) + $signed({{16{i_imm[15]}}, i_imm}); // alu_out is only an address here
            if ((alu_out[31] == 1) || (alu_out[31] != register_file[i_s2][31]) && (register_file[i_s2][31] == i_imm[15])) begin
                data_address_overflow = 1;
            end
            else if (alu_out > 252) begin
                data_address_overflow = 1;
            end
        end
        `OP_AND : begin
            alu_out = register_file[r_s2] & register_file[r_s3];
        end
        `OP_OR : begin
            alu_out = register_file[r_s2] | register_file[r_s3];
        end
        `OP_NOR : begin
            alu_out = ~(register_file[r_s2] | register_file[r_s3]);
        end
        `OP_BEQ : begin
            // will take effect in the next next cycle
            if (register_file[i_s1] == register_file[i_s2]) begin
                branch_true = 1;
            end
        end
        `OP_BNE : begin
            // will take effect in the next next cycle
            if (register_file[i_s1] != register_file[i_s2]) begin
                branch_true = 1;
            end
        end
        `OP_SLT : begin
            alu_out = $signed(register_file[r_s2]) < $signed(register_file[r_s3]);
        end
        `OP_SLL : begin
            alu_out = register_file[r_s2] << register_file[r_s3];
        end
        `OP_SRL : begin
            alu_out = register_file[r_s2] >> register_file[r_s3];
        end
    endcase
end


// FSM
always @(*) begin
    case (curr_state)
        S_IDLE: next_state = S_FETCH;
        S_FETCH: next_state = S_DECODE;
        S_DECODE: next_state = eof_true ? S_END : S_EXECUTE;
        S_EXECUTE: next_state = overflow_true ? S_END : S_WRITEBACK;
        S_WRITEBACK: next_state = S_NEXT_PC;
        S_NEXT_PC: next_state = overflow_true ? S_END : S_FETCH;
        S_END: next_state = S_END;
        default: next_state = curr_state;
    endcase
end

// EOF
always @(*) begin
    if (opcode == `OP_EOF) begin
        eof_true = 1;
    end else begin
        eof_true = 0;
    end
end

// PC counter
always @(*) begin
    pc_overflow = 0;
    next_pc = curr_pc;
    if (curr_state == S_NEXT_PC) begin
        if (branch_true) begin
            next_pc = curr_pc + $signed({{16{i_imm[15]}}, i_imm});
        end 
        else begin
            next_pc = curr_pc + 4;
        end
        if (next_pc > 4096 || next_pc < 0 ) begin
            pc_overflow = 1;
        end
    end 
end

// memory access
// same cycle as execute
// To load data from the data memory, set o_d_we to 0 and o_d_addr to relative address value. 
// i_d_rdata can be received at the next rising edge of the clock.
// To save data to the data memory, set o_d_we to 1, o_d_addr to relative address
// value, and o_d_wdata to the written data.
always @(*) begin
    o_d_wdata_w = o_d_wdata_r;
    o_d_addr_w = o_d_addr_r;
    case (opcode)
        `OP_LW : begin
            o_d_addr_w = alu_out;
        end
        `OP_SW : begin
            o_d_addr_w = alu_out;
            o_d_wdata_w = register_file[i_s1];
        end
    endcase
end

// write back register file
always @(*) begin
    for ( i = 0 ; i < 32 ; i = i + 1 ) begin
        next_register_file[i] = register_file[i];
    end
    if (curr_state == S_WRITEBACK) begin
        case (opcode)
            `OP_ADD : next_register_file[r_s1] = alu_out;
            `OP_SUB : next_register_file[r_s1] = alu_out;
            `OP_MUL : next_register_file[r_s1] = alu_out;
            `OP_FP_ADD : next_register_file[r_s1] = alu_out;
            `OP_FP_SUB : next_register_file[r_s1] = alu_out;
            `OP_FP_MUL : next_register_file[r_s1] = alu_out;
            `OP_ADDI : next_register_file[i_s1] = alu_out;
            `OP_LW : next_register_file[i_s1] = i_d_rdata;
            `OP_AND : next_register_file[r_s1] = alu_out;
            `OP_OR : next_register_file[r_s1] = alu_out;
            `OP_NOR : next_register_file[r_s1] = alu_out;
            `OP_SLT : next_register_file[r_s1] = alu_out;
            `OP_SLL : next_register_file[r_s1] = alu_out;
            `OP_SRL : next_register_file[r_s1] = alu_out;
        endcase
    end
end

// ----------------------------------------------------------------------------
// Sequential Part: Current-state (CS)
// ----------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        // reset
        curr_pc <= 0;
        curr_state <= S_IDLE;
        o_d_we_r <= 0;
        o_d_addr_r <= 0;
        o_d_wdata_r <= 0;
        o_status_r <= 0;
        o_status_valid_r <= 0;
        for ( i = 0 ; i < 32 ; i = i + 1 ) begin
            register_file[i] <= 0;
        end
    end else begin
        // CS
        curr_pc <= next_pc;
        curr_state <= next_state;
        o_d_we_r <= o_d_we_w;
        o_d_addr_r <= o_d_addr_w;
        o_d_wdata_r <= o_d_wdata_w;
        o_status_r <= o_status_w;
        o_status_valid_r <= o_status_valid_w;
        for ( i = 0 ; i < 32 ; i = i + 1 ) begin
            register_file[i] <= next_register_file[i];
        end
    end
end

endmodule