module QR_Engine (
    i_clk,
    i_rst,
    i_trig,
    i_data,
    o_rd_vld,
    o_last_data,
    o_y_hat,
    o_r
);

// Parameter

parameter h_int = 1;
parameter h_frac = 6; //22
parameter h_width = h_int + h_frac + 1;

parameter r_int = 1; // 3
parameter r_frac = 6; //16
parameter r_width = r_int + r_frac + 1;

parameter y_int = 1;
parameter y_frac = 6; //16
parameter y_width = y_int + y_frac + 1;

parameter R11_int = 5; //6
parameter R11_frac = 16; //32
parameter R11_width = R11_int + R11_frac; // Unsigned

parameter inv_sqrt_int = 2;
parameter inv_sqrt_frac = 5; //16
parameter inv_sqrt_width = inv_sqrt_int + inv_sqrt_frac;

parameter Q_int = 1;
parameter Q_frac = 6; //22
parameter Q_width = Q_int + Q_frac + 1;

parameter mul_width = 8; // Max. of (h_width, r_width, y_width, inv_sqrt_width, Q_width)

integer i;
integer j;

// IO description

input          i_clk;
input          i_rst;
input          i_trig;
input  [ 47:0] i_data;
output         o_rd_vld;
output         o_last_data;
output [159:0] o_y_hat;
output [319:0] o_r;

reg i_trig_r;
reg [47:0] i_data_r;

reg o_rd_vld_w, o_rd_vld_r, o_last_data_w, o_last_data_r;
reg [159:0] o_y_hat_w, o_y_hat_r;
reg [159:0] o_y_hat_now_w, o_y_hat_now_r;
reg [119:0] o_y_hat_next_w, o_y_hat_next_r;
reg [319:0] o_r_w, o_r_r;

reg [1:0] counter_in_i_w, counter_in_i_r;
reg [2:0] counter_in_j_w, counter_in_j_r;
reg [3:0] counter_re_w, counter_re_r;
reg first_vld_w, first_vld_r;

reg [2*h_width - 1 : 0] h_i0_w [4:1][4:1];
reg [2*h_width - 1 : 0] h_i0_r [4:1][4:1];

wire signed [h_width - 1 : 0] h_i_data [1:0];

assign h_i_data[1] = (i_data[47 -: h_width] != 8'b0111_1111)? i_data[47 -: h_width] + i_data[47 - h_width] : i_data[47 -: h_width];
assign h_i_data[0] = (i_data[23 -: h_width] != 8'b0111_1111)? i_data[23 -: h_width] + i_data[23 - h_width] : i_data[23 -: h_width];

// assign h_i_data[1] = (i_data[47 -: h_width] != 8'b0111_1111)? i_data[47 -: h_width] : i_data[47 -: h_width];
// assign h_i_data[0] = (i_data[23 -: h_width] != 8'b0111_1111)? i_data[23 -: h_width] : i_data[23 -: h_width];

reg Q_computing_r;

reg Q_computing_previous_r, Q_computing_previous_w;

// reg Q_computing_previous_w
// assign Q_computing_previous = ({counter_in_i_r, counter_in_j_r} == 5'b11_000)  || ({counter_in_i_r, counter_in_j_r} == 5'b00_011) || ({counter_in_i_r, counter_in_j_r[2]} == 3'b01_1) || ({counter_in_i_r, counter_in_j_r} == 5'b10_011);

reg  [10 : 0] R11_w, R11_r; 

// Multipliers (16)

wire signed [2*mul_width - 1 : 0] mul_ans [15:0];
wire signed [  mul_width - 1 : 0] mul_1   [15:0];
wire signed [  mul_width - 1 : 0] mul_2   [15:0];

reg signed [  mul_width - 1 : 0] mul_1_w   [15:0];
reg signed [  mul_width - 1 : 0] mul_1_r   [15:0];
reg signed [  mul_width - 1 : 0] mul_2_w   [7:0];
reg signed [  mul_width - 1 : 0] mul_2_r   [7:0];

genvar k;
generate
    for (k=0;k<16;k=k+1) begin 
        assign mul_ans[k] = $signed(mul_1[k]) * $signed(mul_2[k]);
    end
endgenerate

wire [6:0] inv_sqrt;

reg [  mul_width - 1 : 0] inv_sqrt_r;

genvar a,b,c;

wire signed [  mul_width - 1 : 0] muls_h_i0  [4:1][4:1][1:0];
wire signed [  mul_width - 1 : 0] muls_o_y   [7:0];
// wire signed [  mul_width - 1 : 0] muls_o_r   [1:0];

generate
    for (a=1;a<5;a=a+1) begin 
        for (b=1;b<5;b=b+1) begin 
            assign muls_h_i0[a][b][1] = $signed(h_i0_r[a][b][2*h_width - 1 : h_width]);
            assign muls_h_i0[a][b][0] = $signed(h_i0_r[a][b][h_width - 1 : 0]);
        end 
    end
    
endgenerate

assign muls_o_y[0] = $signed(o_y_hat_now_r[19  -: y_width]);
assign muls_o_y[1] = $signed(o_y_hat_now_r[39  -: y_width]);
assign muls_o_y[2] = $signed(o_y_hat_now_r[59  -: y_width]);
assign muls_o_y[3] = $signed(o_y_hat_now_r[79  -: y_width]);
assign muls_o_y[4] = $signed(o_y_hat_now_r[99  -: y_width]);
assign muls_o_y[5] = $signed(o_y_hat_now_r[119  -: y_width]);
assign muls_o_y[6] = $signed(o_y_hat_now_r[139  -: y_width]);
assign muls_o_y[7] = $signed(o_y_hat_now_r[159  -: y_width]);

assign mul_1[ 0] =  mul_1_r[0];
assign mul_2[ 0] =  mul_2_r[0];
assign mul_1[ 1] =  mul_1_r[1]; 
assign mul_2[ 1] =  mul_2_r[1];
assign mul_1[ 2] =  mul_1_r[2]; 
assign mul_2[ 2] =  mul_2_r[2];
assign mul_1[ 3] =  mul_1_r[3]; 
assign mul_2[ 3] =  mul_2_r[3];
assign mul_1[ 4] =  mul_1_r[4];
assign mul_2[ 4] =  mul_2_r[4];
assign mul_1[ 5] =  mul_1_r[5];
assign mul_2[ 5] =  mul_2_r[5];
assign mul_1[ 6] =  mul_1_r[6];
assign mul_2[ 6] =  mul_2_r[6];
assign mul_1[ 7] =  mul_1_r[7];
assign mul_2[ 7] =  mul_2_r[7];

assign mul_1[ 8] =  mul_1_r[8];
assign mul_2[ 8] = (Q_computing_r)? inv_sqrt_r : mul_2_r[0];
assign mul_1[ 9] =  mul_1_r[9]; 
assign mul_2[ 9] = (Q_computing_r)? inv_sqrt_r : mul_2_r[1];
assign mul_1[10] =  mul_1_r[10];
assign mul_2[10] = (Q_computing_r)? inv_sqrt_r : mul_2_r[2];
assign mul_1[11] =  mul_1_r[11];
assign mul_2[11] = (Q_computing_r)? inv_sqrt_r : mul_2_r[3];
assign mul_1[12] =  mul_1_r[12];
assign mul_2[12] = (Q_computing_r)? inv_sqrt_r : mul_2_r[4];
assign mul_1[13] =  mul_1_r[13];
assign mul_2[13] = (Q_computing_r)? inv_sqrt_r : mul_2_r[5];
assign mul_1[14] = mul_1_r[14];
assign mul_2[14] = (Q_computing_r)? inv_sqrt_r : mul_2_r[6];
assign mul_1[15] = mul_1_r[15];
assign mul_2[15] = (Q_computing_r)? inv_sqrt_r : mul_2_r[7];


wire [10 : 0] R11_temp; 
wire [7:0] Rii_sq [7:0];


assign R11_temp = Rii_sq[0] + Rii_sq[1] + Rii_sq[2] + Rii_sq[3] + Rii_sq[4] + Rii_sq[5] + Rii_sq[6] + Rii_sq[7]; 

wire signed [h_width + inv_sqrt_width - 1 + 1: 0] Q_im [4:1]; // 如果和h2(1) h3(1) h4(1) 共用的話就必須考量長度 : h_width + inv_sqrt_width vs. r_width + Q_width
wire signed [h_width + inv_sqrt_width - 1 + 1: 0] Q_re [4:1]; 

assign Q_im[1] = (mul_ans[8][2*mul_width - 1 : 5] + mul_ans[8][4]) << 5;
assign Q_re[1] = (mul_ans[9][2*mul_width - 1 : 5] + mul_ans[9][4]) << 5;
assign Q_im[2] = (mul_ans[10][2*mul_width - 1 : 5] + mul_ans[10][4]) << 5;
assign Q_re[2] = (mul_ans[11][2*mul_width - 1 : 5] + mul_ans[11][4]) << 5;
assign Q_im[3] = (mul_ans[12][2*mul_width - 1 : 5] + mul_ans[12][4]) << 5;
assign Q_re[3] = (mul_ans[13][2*mul_width - 1 : 5] + mul_ans[13][4]) << 5;
assign Q_im[4] = (mul_ans[14][2*mul_width - 1 : 5] + mul_ans[14][4]) << 5;
assign Q_re[4] = (mul_ans[15][2*mul_width - 1 : 5] + mul_ans[15][4]) << 5;

wire signed [Q_width + h_width - 1 + 3: 0] R1_234_im; 
wire signed [Q_width + h_width - 1 + 3: 0] R1_234_re;

wire signed [Q_width + h_width - 1 + 3 - 4: 0] R1_234_im_dao; 
wire signed [Q_width + h_width - 1 + 3 - 4: 0] R1_234_re_dao;

wire signed [Q_width + y_width - 1 + 3: 0] y_im; 
wire signed [Q_width + y_width - 1 + 3: 0] y_re; 

// wire signed [Q_width + y_width - 1 + 3 - 4: 0] y_im_dao; 
// wire signed [Q_width + y_width - 1 + 3 - 4: 0] y_re_dao; 

assign R1_234_im_dao = $signed(mul_ans[0][2*mul_width - 1 : 4]) - $signed(mul_ans[1][2*mul_width - 1 : 4]) + $signed(mul_ans[2][2*mul_width - 1 : 4]) - $signed(mul_ans[3][2*mul_width - 1 : 4]) + $signed(mul_ans[4][2*mul_width - 1 : 4]) - $signed(mul_ans[5][2*mul_width - 1 : 4]) + $signed(mul_ans[6][2*mul_width - 1 : 4]) - $signed(mul_ans[7][2*mul_width - 1 : 4]); 
assign R1_234_re_dao = $signed(mul_ans[8][2*mul_width - 1 : 4]) + $signed(mul_ans[9][2*mul_width - 1 : 4]) + $signed(mul_ans[10][2*mul_width - 1 : 4]) + $signed(mul_ans[11][2*mul_width - 1 : 4]) + $signed(mul_ans[12][2*mul_width - 1 : 4]) + $signed(mul_ans[13][2*mul_width - 1 : 4]) + $signed(mul_ans[14][2*mul_width - 1 : 4]) + $signed(mul_ans[15][2*mul_width - 1 : 4]); 

assign R1_234_im = ($signed(R1_234_im_dao[Q_width + h_width - 1 + 3 - 4 : 2]) + R1_234_im_dao[1]) << 6;
assign R1_234_re = ($signed(R1_234_re_dao[Q_width + h_width - 1 + 3 - 4 : 2]) + R1_234_re_dao[1]) << 6;

// assign y_im = mul_ans[0] - mul_ans[1] + mul_ans[2] - mul_ans[3] + mul_ans[4] - mul_ans[5] + mul_ans[6] - mul_ans[7]; 
// assign y_re = mul_ans[8] + mul_ans[9] + mul_ans[10] + mul_ans[11] + mul_ans[12] + mul_ans[13] + mul_ans[14] + mul_ans[15]; 

// assign y_im_dao = $signed(mul_ans[0][2*mul_width - 1 : 4]) - $signed(mul_ans[1][2*mul_width - 1 : 4]) + $signed(mul_ans[2][2*mul_width - 1 : 4]) - $signed(mul_ans[3][2*mul_width - 1 : 4]) + $signed(mul_ans[4][2*mul_width - 1 : 4]) - $signed(mul_ans[5][2*mul_width - 1 : 4]) + $signed(mul_ans[6][2*mul_width - 1 : 4]) - $signed(mul_ans[7][2*mul_width - 1 : 4]); 
// assign y_re_dao = $signed(mul_ans[8][2*mul_width - 1 : 4]) + $signed(mul_ans[9][2*mul_width - 1 : 4]) + $signed(mul_ans[10][2*mul_width - 1 : 4]) + $signed(mul_ans[11][2*mul_width - 1 : 4]) + $signed(mul_ans[12][2*mul_width - 1 : 4]) + $signed(mul_ans[13][2*mul_width - 1 : 4]) + $signed(mul_ans[14][2*mul_width - 1 : 4]) + $signed(mul_ans[15][2*mul_width - 1 : 4]); 

assign y_im = R1_234_im;
assign y_re = R1_234_re;

wire signed [r_width + Q_width : 0] R1x_e1_im [4:1];
wire signed [r_width + Q_width : 0] R1x_e1_re [4:1];

wire signed [r_width + Q_width -4: 0] R1x_e1_im_dao [4:1];
wire signed [r_width + Q_width -4: 0] R1x_e1_re_dao [4:1];

assign R1x_e1_im_dao[1] = $signed(mul_ans[9][2*mul_width - 1 : 4]) + $signed(mul_ans[0][2*mul_width - 1 : 4]);
assign R1x_e1_re_dao[1] = $signed(mul_ans[8][2*mul_width - 1 : 4]) - $signed(mul_ans[1][2*mul_width - 1 : 4]);
assign R1x_e1_im_dao[2] = $signed(mul_ans[11][2*mul_width - 1 : 4]) + $signed(mul_ans[2][2*mul_width - 1 : 4]);
assign R1x_e1_re_dao[2] = $signed(mul_ans[10][2*mul_width - 1 : 4]) - $signed(mul_ans[3][2*mul_width - 1 : 4]);
assign R1x_e1_im_dao[3] = $signed(mul_ans[13][2*mul_width - 1 : 4]) + $signed(mul_ans[4][2*mul_width - 1 : 4]);
assign R1x_e1_re_dao[3] = $signed(mul_ans[12][2*mul_width - 1 : 4]) - $signed(mul_ans[5][2*mul_width - 1 : 4]);
assign R1x_e1_im_dao[4] = $signed(mul_ans[15][2*mul_width - 1 : 4]) + $signed(mul_ans[6][2*mul_width - 1 : 4]);
assign R1x_e1_re_dao[4] = $signed(mul_ans[14][2*mul_width - 1 : 4]) - $signed(mul_ans[7][2*mul_width - 1 : 4]);

assign R1x_e1_im[1] = ($signed(R1x_e1_im_dao[1][r_width + Q_width -4 : 2]) + R1x_e1_im_dao[1][1]) << 6;
assign R1x_e1_re[1] = ($signed(R1x_e1_re_dao[1][r_width + Q_width -4 : 2]) + R1x_e1_re_dao[1][1]) << 6;
assign R1x_e1_im[2] = ($signed(R1x_e1_im_dao[2][r_width + Q_width -4 : 2]) + R1x_e1_im_dao[2][1]) << 6;
assign R1x_e1_re[2] = ($signed(R1x_e1_re_dao[2][r_width + Q_width -4 : 2]) + R1x_e1_re_dao[2][1]) << 6;
assign R1x_e1_im[3] = ($signed(R1x_e1_im_dao[3][r_width + Q_width -4 : 2]) + R1x_e1_im_dao[3][1]) << 6;
assign R1x_e1_re[3] = ($signed(R1x_e1_re_dao[3][r_width + Q_width -4 : 2]) + R1x_e1_re_dao[3][1]) << 6;
assign R1x_e1_im[4] = ($signed(R1x_e1_im_dao[4][r_width + Q_width -4 : 2]) + R1x_e1_im_dao[4][1]) << 6;
assign R1x_e1_re[4] = ($signed(R1x_e1_re_dao[4][r_width + Q_width -4 : 2]) + R1x_e1_re_dao[4][1]) << 6;

wire [2*h_width - 1 : 0] h_i123 [4:1];
genvar h;
generate
    for(h=1;h<5;h=h+1) begin 
        assign h_i123[h][h_width +: h_frac] = R1x_e1_im[h][Q_frac + r_frac - 1 -: h_frac]; 
        assign h_i123[h][2*h_width - 1 -: (h_int+1)] = {R1x_e1_im[h][r_width + Q_width], R1x_e1_im[h][Q_frac + r_frac +: h_int]}; 
        assign h_i123[h][0 +: h_frac] = R1x_e1_re[h][Q_frac + r_frac - 1 -: h_frac];   
        assign h_i123[h][h_width - 1 -: (h_int+1)] = {R1x_e1_re[h][r_width + Q_width], R1x_e1_re[h][Q_frac + r_frac +: h_int]}; 
    end
endgenerate

// Continuous Assignments

assign o_rd_vld = o_rd_vld_r;
assign o_last_data = o_last_data_r;
assign o_y_hat = o_y_hat_r;
assign o_r = o_r_r;

// Submodule


wire signed [19 : 0] root_inst; // .R11_frac/2



sqrt sqrt1(.sqrt_in(R11_r), .sqrt_out(root_inst));
inv_sqrt inv_sqrt1(.inv_sqrt_in(R11_temp), .inv_sqrt_out(inv_sqrt));

sq sq0(.sq_in(mul_1_r[0]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[0]));
sq sq1(.sq_in(mul_1_r[1]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[1]));
sq sq2(.sq_in(mul_1_r[2]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[2]));
sq sq3(.sq_in(mul_1_r[3]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[3]));
sq sq4(.sq_in(mul_1_r[4]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[4]));
sq sq5(.sq_in(mul_1_r[5]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[5]));
sq sq6(.sq_in(mul_1_r[6]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[6]));
sq sq7(.sq_in(mul_1_r[7]), .sq_en(Q_computing_previous_r), .sq_out(Rii_sq[7]));


// Combinational

always@(*) begin
    o_rd_vld_w = o_rd_vld_r;
    // o_y_hat_w = o_y_hat_r;
    // o_y_hat_now_w = o_y_hat_now_r;
    // o_y_hat_next_w = o_y_hat_next_r;
    // o_r_w = o_r_r;
    // counter_in_i_w = counter_in_i_r;
    // counter_in_j_w = counter_in_j_r;
    // counter_re_w = counter_re_r;
    // R11_w = R11_r;
    first_vld_w = first_vld_r;
    o_last_data_w = o_last_data_r;
    Q_computing_previous_w = Q_computing_previous_r;

    // for (i=1;i<5;i=i+1) begin 
    //     for (j=1;j<5;j=j+1) h_i0_w[i][j] = h_i0_r[i][j];
    //     //Q_w[i] = Q_r[i];
    // end  
    for (i=0;i<16;i=i+1) begin 
        mul_1_w[i] = mul_1_r[i];
    end
    // for (i=0;i<8;i=i+1) begin 
    //     mul_2_w[i] = mul_2_r[i];
    // end
    
    //Load Data

    counter_in_j_w = ((!i_trig_r) || counter_in_j_r == 4)? 0 : counter_in_j_r + 1;
    counter_in_i_w = (counter_in_j_r == 4)? counter_in_i_r + 1 : counter_in_i_r;
    counter_re_w = (counter_re_r == 9)? 0 : counter_re_r + 1;
    // if (counter_in_j_r == 4) begin 
    //     if (counter_in_i_r == 3) o_y_hat_now_w[120 +: 40] = {i_data_r[47 -: y_width], {(20-y_width){1'b0}}, i_data_r[23 -: y_width], {(20-y_width){1'b0}}};
    //     else o_y_hat_next_w[counter_in_i_r*40 +: 40] = {i_data_r[47 -: y_width], {(20-y_width){1'b0}}, i_data_r[23 -: y_width], {(20-y_width){1'b0}}};
    // end
    // if (counter_in_i_r == 0 && counter_in_j_r == 0) o_y_hat_now_w[119:0] = o_y_hat_next_r[119:0];

    o_y_hat_now_w[159 : 120] = {i_data_r[47 -: y_width], {(20-y_width){1'b0}}, i_data_r[23 -: y_width], {(20-y_width){1'b0}}};
    o_y_hat_next_w[39 :  0] = {i_data_r[47 -: y_width], {(20-y_width){1'b0}}, i_data_r[23 -: y_width], {(20-y_width){1'b0}}};
    o_y_hat_next_w[79 : 40] = {i_data_r[47 -: y_width], {(20-y_width){1'b0}}, i_data_r[23 -: y_width], {(20-y_width){1'b0}}};
    o_y_hat_next_w[119 : 80] = {i_data_r[47 -: y_width], {(20-y_width){1'b0}}, i_data_r[23 -: y_width], {(20-y_width){1'b0}}};
    o_y_hat_now_w[119:0] = o_y_hat_next_r[119:0];

    // New Attempt

    case({counter_in_i_r,counter_in_j_r})
        5'b00_000 : begin 

            // h_i0_w[2][1][2*h_width-1 -: h_width] = $signed(h_i0_r[1][2][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            // h_i0_w[2][1][0 +: h_width] =  $signed(h_i0_r[1][2][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
            // h_i0_w[2][2][2*h_width-1 -: h_width] = $signed(h_i0_r[2][2][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            // h_i0_w[2][2][0 +: h_width] =  $signed(h_i0_r[2][2][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
            // h_i0_w[4][1][2*h_width-1 -: h_width] = $signed(h_i0_r[3][2][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            // h_i0_w[4][1][0 +: h_width] =  $signed(h_i0_r[3][2][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
            // h_i0_w[4][2][2*h_width-1 -: h_width] = $signed(h_i0_r[4][2][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            // h_i0_w[4][2][0 +: h_width] =  $signed(h_i0_r[4][2][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
            
            mul_1_w[0] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[1] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[2] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[3] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[4] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[5] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[6] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[7] = $signed({o_r_r[119],o_r_r[116 - r_frac +: (r_width-1)]});
            mul_1_w[8] =  $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            mul_1_w[9] =  $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            mul_1_w[10] = $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            mul_1_w[11] = $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            mul_1_w[12] = $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            mul_1_w[13] = $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            mul_1_w[14] = $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            mul_1_w[15] = $signed({o_r_r[99],o_r_r[96 - r_frac +: (r_width-1)]});
            
        end
        5'b00_001 : begin 

            // h_i0_w[3][1][2*h_width-1 -: h_width] = $signed(h_i0_r[1][3][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            // h_i0_w[3][1][0 +: h_width] =  $signed(h_i0_r[1][3][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
            // h_i0_w[3][2][2*h_width-1 -: h_width] = $signed(h_i0_r[2][3][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            // h_i0_w[3][2][0 +: h_width] =  $signed(h_i0_r[2][3][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
            // h_i0_w[3][3][2*h_width-1 -: h_width] = $signed(h_i0_r[3][3][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            // h_i0_w[3][3][0 +: h_width] =  $signed(h_i0_r[3][3][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
            // h_i0_w[4][3][2*h_width-1 -: h_width] = $signed(h_i0_r[4][3][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            // h_i0_w[4][3][0 +: h_width] =  $signed(h_i0_r[4][3][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
            
            
            mul_1_w[0] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[1] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[2] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[3] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[4] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[5] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[6] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[7] = $signed({o_r_r[219],o_r_r[216 - r_frac +: (r_width-1)]});
            mul_1_w[8] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
            mul_1_w[9] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
            mul_1_w[10] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
            mul_1_w[11] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
            mul_1_w[12] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
            mul_1_w[13] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
            mul_1_w[14] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
            mul_1_w[15] = $signed({o_r_r[199],o_r_r[196 - r_frac +: (r_width-1)]});
        end
        5'b00_010 : begin 
            
            // h_i0_w[3][4][2*h_width-1 -: h_width] = $signed(h_i0_r[1][4][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            // h_i0_w[3][4][0 +: h_width] =  $signed(h_i0_r[1][4][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
            // h_i0_w[4][1][2*h_width-1 -: h_width] = $signed(h_i0_r[2][4][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            // h_i0_w[4][1][0 +: h_width] =  $signed(h_i0_r[2][4][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
            // h_i0_w[4][2][2*h_width-1 -: h_width] = $signed(h_i0_r[3][4][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            // h_i0_w[4][2][0 +: h_width] =  $signed(h_i0_r[3][4][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
            // h_i0_w[4][4][2*h_width-1 -: h_width] = $signed(h_i0_r[4][4][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            // h_i0_w[4][4][0 +: h_width] =  $signed(h_i0_r[4][4][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
            
            mul_1_w[0] = muls_h_i0[2][1][1];
            mul_1_w[1] = muls_h_i0[2][1][0];
            mul_1_w[2] = muls_h_i0[2][2][1];
            mul_1_w[3] = muls_h_i0[2][2][0];
            mul_1_w[4] = muls_h_i0[4][1][1];
            mul_1_w[5] = muls_h_i0[4][1][0];
            mul_1_w[6] = muls_h_i0[4][2][1];
            mul_1_w[7] = muls_h_i0[4][2][0];

            mul_1_w[8] = muls_o_y[0];
            mul_1_w[9] = muls_o_y[1];
            mul_1_w[10] = muls_o_y[2];
            mul_1_w[11] = muls_o_y[3];
            mul_1_w[12] = muls_o_y[4];
            mul_1_w[13] = muls_o_y[5];
            mul_1_w[14] = muls_o_y[6];
            mul_1_w[15] = muls_o_y[7];

            Q_computing_previous_w = 1;

        end
        5'b00_011 : begin 
  
            // o_y_hat_w[19:0] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));
       
            mul_1_w[0] = muls_o_y[1];
            mul_1_w[1] = muls_o_y[0];
            mul_1_w[2] = muls_o_y[3];
            mul_1_w[3] = muls_o_y[2];
            mul_1_w[4] = muls_o_y[5];
            mul_1_w[5] = muls_o_y[4];
            mul_1_w[6] = muls_o_y[7];
            mul_1_w[7] = muls_o_y[6];

            mul_1_w[8] = mul_1_r[0];
            mul_1_w[9] = mul_1_r[1];
            mul_1_w[10] = mul_1_r[2];
            mul_1_w[11] = mul_1_r[3];
            mul_1_w[12] = mul_1_r[4];
            mul_1_w[13] = mul_1_r[5];
            mul_1_w[14] = mul_1_r[6];
            mul_1_w[15] = mul_1_r[7];

            // R11_w = R11_temp << 8; 
            
            Q_computing_previous_w = 0;

        end
        5'b00_100 : begin 
       
            // o_y_hat_w[39:20] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));

            // o_r_w[79:60] = root_inst;

            mul_1_w[0] = muls_h_i0[3][1][1];
            mul_1_w[1] = muls_h_i0[3][1][0];
            mul_1_w[2] = muls_h_i0[3][2][1];
            mul_1_w[3] = muls_h_i0[3][2][0];
            mul_1_w[4] = muls_h_i0[3][3][1];
            mul_1_w[5] = muls_h_i0[3][3][0];
            mul_1_w[6] = muls_h_i0[4][3][1];
            mul_1_w[7] = muls_h_i0[4][3][0];
            mul_1_w[8] = muls_h_i0[3][1][0];
            mul_1_w[9] = muls_h_i0[3][1][1];
            mul_1_w[10] = muls_h_i0[3][2][0];
            mul_1_w[11] = muls_h_i0[3][2][1];
            mul_1_w[12] = muls_h_i0[3][3][0];
            mul_1_w[13] = muls_h_i0[3][3][1];
            mul_1_w[14] = muls_h_i0[4][3][0];
            mul_1_w[15] = muls_h_i0[4][3][1];

            // mul_2_w[0] = $signed({Q_re[1][h_width + inv_sqrt_width - 1 + 1], Q_re[1][h_frac + inv_sqrt_frac +: Q_int], Q_re[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[1] = $signed({Q_im[1][h_width + inv_sqrt_width - 1 + 1], Q_im[1][h_frac + inv_sqrt_frac +: Q_int], Q_im[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[2] = $signed({Q_re[2][h_width + inv_sqrt_width - 1 + 1], Q_re[2][h_frac + inv_sqrt_frac +: Q_int], Q_re[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[3] = $signed({Q_im[2][h_width + inv_sqrt_width - 1 + 1], Q_im[2][h_frac + inv_sqrt_frac +: Q_int], Q_im[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[4] = $signed({Q_re[3][h_width + inv_sqrt_width - 1 + 1], Q_re[3][h_frac + inv_sqrt_frac +: Q_int], Q_re[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[5] = $signed({Q_im[3][h_width + inv_sqrt_width - 1 + 1], Q_im[3][h_frac + inv_sqrt_frac +: Q_int], Q_im[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[6] = $signed({Q_re[4][h_width + inv_sqrt_width - 1 + 1], Q_re[4][h_frac + inv_sqrt_frac +: Q_int], Q_re[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[7] = $signed({Q_im[4][h_width + inv_sqrt_width - 1 + 1], Q_im[4][h_frac + inv_sqrt_frac +: Q_int], Q_im[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});

        end
        5'b01_000 : begin 

                // o_r_w[159:140] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
                // o_r_w[139:120] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
             
            mul_1_w[0] = muls_h_i0[3][4][1];
            mul_1_w[1] = muls_h_i0[3][4][0];
            mul_1_w[2] = muls_h_i0[4][1][1];
            mul_1_w[3] = muls_h_i0[4][1][0];
            mul_1_w[4] = muls_h_i0[4][2][1];
            mul_1_w[5] = muls_h_i0[4][2][0];
            mul_1_w[6] = muls_h_i0[4][4][1];
            mul_1_w[7] = muls_h_i0[4][4][0];

            mul_1_w[8] = muls_h_i0[3][4][0];
            mul_1_w[9] = muls_h_i0[3][4][1];
            mul_1_w[10] = muls_h_i0[4][1][0];
            mul_1_w[11] = muls_h_i0[4][1][1];
            mul_1_w[12] = muls_h_i0[4][2][0];
            mul_1_w[13] = muls_h_i0[4][2][1];
            mul_1_w[14] = muls_h_i0[4][4][0];
            mul_1_w[15] = muls_h_i0[4][4][1];



        end
        5'b01_001 : begin 

                // o_r_w[259:240] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
                // o_r_w[239:220] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));

            mul_1_w[0] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[1] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[2] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[3] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[4] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[5] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[6] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[7] = $signed({o_r_r[159],o_r_r[156 - r_frac +: (r_width-1)]});
            mul_1_w[8] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});
            mul_1_w[9] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});
            mul_1_w[10] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});
            mul_1_w[11] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});
            mul_1_w[12] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});
            mul_1_w[13] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});
            mul_1_w[14] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});
            mul_1_w[15] = $signed({o_r_r[139],o_r_r[136 - r_frac +: (r_width-1)]});

        end
        5'b01_010 : begin 
            
            // h_i0_w[3][1][2*h_width-1 -: h_width] = $signed(h_i0_r[3][1][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            // h_i0_w[3][1][0 +: h_width] =  $signed(h_i0_r[3][1][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
            // h_i0_w[3][2][2*h_width-1 -: h_width] = $signed(h_i0_r[3][2][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            // h_i0_w[3][2][0 +: h_width] =  $signed(h_i0_r[3][2][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
            // h_i0_w[3][3][2*h_width-1 -: h_width] = $signed(h_i0_r[3][3][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            // h_i0_w[3][3][0 +: h_width] =  $signed(h_i0_r[3][3][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
            // h_i0_w[4][3][2*h_width-1 -: h_width] = $signed(h_i0_r[4][3][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            // h_i0_w[4][3][0 +: h_width] =  $signed(h_i0_r[4][3][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
            
           
            mul_1_w[0] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[1] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[2] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[3] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[4] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[5] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[6] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[7] = $signed({o_r_r[259],o_r_r[256 - r_frac +: (r_width-1)]});
            mul_1_w[8] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
            mul_1_w[9] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
            mul_1_w[10] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
            mul_1_w[11] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
            mul_1_w[12] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
            mul_1_w[13] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
            mul_1_w[14] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
            mul_1_w[15] = $signed({o_r_r[239],o_r_r[236 - r_frac +: (r_width-1)]});
        end
        5'b01_011 : begin 
             
            // h_i0_w[3][4][2*h_width-1 -: h_width] = $signed(h_i0_r[3][4][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            // h_i0_w[3][4][0 +: h_width] =  $signed(h_i0_r[3][4][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
            // h_i0_w[4][1][2*h_width-1 -: h_width] = $signed(h_i0_r[4][1][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            // h_i0_w[4][1][0 +: h_width] =  $signed(h_i0_r[4][1][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
            // h_i0_w[4][2][2*h_width-1 -: h_width] = $signed(h_i0_r[4][2][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            // h_i0_w[4][2][0 +: h_width] =  $signed(h_i0_r[4][2][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
            // h_i0_w[4][4][2*h_width-1 -: h_width] = $signed(h_i0_r[4][4][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            // h_i0_w[4][4][0 +: h_width] =  $signed(h_i0_r[4][4][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);

            mul_1_w[0] = muls_h_i0[3][1][1];
            mul_1_w[1] = muls_h_i0[3][1][0];
            mul_1_w[2] = muls_h_i0[3][2][1];
            mul_1_w[3] = muls_h_i0[3][2][0];
            mul_1_w[4] = muls_h_i0[3][3][1];
            mul_1_w[5] = muls_h_i0[3][3][0];
            mul_1_w[6] = muls_h_i0[4][3][1];
            mul_1_w[7] = muls_h_i0[4][3][0];

            
            mul_1_w[8] = muls_o_y[0];
            mul_1_w[9] = muls_o_y[1];
            mul_1_w[10] = muls_o_y[2];
            mul_1_w[11] = muls_o_y[3];
            mul_1_w[12] = muls_o_y[4];
            mul_1_w[13] = muls_o_y[5];
            mul_1_w[14] = muls_o_y[6];
            mul_1_w[15] = muls_o_y[7];

            Q_computing_previous_w = 1;

        end
        5'b01_100 : begin 

            // o_y_hat_w[59:40] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));

            mul_1_w[0] = muls_o_y[1];
            mul_1_w[1] = muls_o_y[0];
            mul_1_w[2] = muls_o_y[3];
            mul_1_w[3] = muls_o_y[2];
            mul_1_w[4] = muls_o_y[5];
            mul_1_w[5] = muls_o_y[4];
            mul_1_w[6] = muls_o_y[7];
            mul_1_w[7] = muls_o_y[6];

            mul_1_w[8] = mul_1_r[0];
            mul_1_w[9] = mul_1_r[1];
            mul_1_w[10] = mul_1_r[2];
            mul_1_w[11] = mul_1_r[3];
            mul_1_w[12] = mul_1_r[4];
            mul_1_w[13] = mul_1_r[5];
            mul_1_w[14] = mul_1_r[6];
            mul_1_w[15] = mul_1_r[7];

            // R11_w = R11_temp << 8; 

            Q_computing_previous_w = 0;

        end
        5'b10_000 : begin 

            // o_y_hat_w[79:60] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));

            // o_r_w[179:160] = root_inst;

            mul_1_w[0] = muls_h_i0[3][4][1];
            mul_1_w[1] = muls_h_i0[3][4][0];
            mul_1_w[2] = muls_h_i0[4][1][1];
            mul_1_w[3] = muls_h_i0[4][1][0];
            mul_1_w[4] = muls_h_i0[4][2][1];
            mul_1_w[5] = muls_h_i0[4][2][0];
            mul_1_w[6] = muls_h_i0[4][4][1];
            mul_1_w[7] = muls_h_i0[4][4][0];

            mul_1_w[8] = muls_h_i0[3][4][0];
            mul_1_w[9] = muls_h_i0[3][4][1];
            mul_1_w[10] = muls_h_i0[4][1][0];
            mul_1_w[11] = muls_h_i0[4][1][1];
            mul_1_w[12] = muls_h_i0[4][2][0];
            mul_1_w[13] = muls_h_i0[4][2][1];
            mul_1_w[14] = muls_h_i0[4][4][0];
            mul_1_w[15] = muls_h_i0[4][4][1];


            // mul_2_w[0] = $signed({Q_re[1][h_width + inv_sqrt_width - 1 + 1], Q_re[1][h_frac + inv_sqrt_frac +: Q_int], Q_re[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[1] = $signed({Q_im[1][h_width + inv_sqrt_width - 1 + 1], Q_im[1][h_frac + inv_sqrt_frac +: Q_int], Q_im[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[2] = $signed({Q_re[2][h_width + inv_sqrt_width - 1 + 1], Q_re[2][h_frac + inv_sqrt_frac +: Q_int], Q_re[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[3] = $signed({Q_im[2][h_width + inv_sqrt_width - 1 + 1], Q_im[2][h_frac + inv_sqrt_frac +: Q_int], Q_im[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[4] = $signed({Q_re[3][h_width + inv_sqrt_width - 1 + 1], Q_re[3][h_frac + inv_sqrt_frac +: Q_int], Q_re[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[5] = $signed({Q_im[3][h_width + inv_sqrt_width - 1 + 1], Q_im[3][h_frac + inv_sqrt_frac +: Q_int], Q_im[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[6] = $signed({Q_re[4][h_width + inv_sqrt_width - 1 + 1], Q_re[4][h_frac + inv_sqrt_frac +: Q_int], Q_re[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[7] = $signed({Q_im[4][h_width + inv_sqrt_width - 1 + 1], Q_im[4][h_frac + inv_sqrt_frac +: Q_int], Q_im[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});

        end
        5'b10_001 : begin 

                // o_r_w[299:280] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
                // o_r_w[279:260] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));

            mul_1_w[0] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[1] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[2] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[3] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[4] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[5] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[6] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[7] = $signed({R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[8] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[9] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[10] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[11] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[12] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[13] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[14] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});
            mul_1_w[15] = $signed({R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[h_frac + Q_frac - r_frac +: (r_width-1)]});

        end
        5'b10_010 : begin 

            // h_i0_w[3][4][2*h_width-1 -: h_width] = $signed(h_i0_r[3][4][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            // h_i0_w[3][4][0 +: h_width] =  $signed(h_i0_r[3][4][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
            // h_i0_w[4][1][2*h_width-1 -: h_width] = $signed(h_i0_r[4][1][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            // h_i0_w[4][1][0 +: h_width] =  $signed(h_i0_r[4][1][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
            // h_i0_w[4][2][2*h_width-1 -: h_width] = $signed(h_i0_r[4][2][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            // h_i0_w[4][2][0 +: h_width] =  $signed(h_i0_r[4][2][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
            // h_i0_w[4][4][2*h_width-1 -: h_width] = $signed(h_i0_r[4][4][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            // h_i0_w[4][4][0 +: h_width] =  $signed(h_i0_r[4][4][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
                  
            mul_1_w[0] = $signed(h_i0_r[3][4][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            mul_1_w[1] = $signed(h_i0_r[3][4][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
            mul_1_w[2] = $signed(h_i0_r[4][1][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            mul_1_w[3] = $signed(h_i0_r[4][1][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
            mul_1_w[4] = $signed(h_i0_r[4][2][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            mul_1_w[5] = $signed(h_i0_r[4][2][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
            mul_1_w[6] = $signed(h_i0_r[4][4][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            mul_1_w[7] = $signed(h_i0_r[4][4][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
            mul_1_w[8] = muls_o_y[0];
            mul_1_w[9] = muls_o_y[1];
            mul_1_w[10] = muls_o_y[2];
            mul_1_w[11] = muls_o_y[3];
            mul_1_w[12] = muls_o_y[4];
            mul_1_w[13] = muls_o_y[5];
            mul_1_w[14] = muls_o_y[6];
            mul_1_w[15] = muls_o_y[7];

            Q_computing_previous_w = 1;

        end
        5'b10_011 : begin 

            // o_y_hat_w[99:80] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));  

            mul_1_w[0] = muls_o_y[1];
            mul_1_w[1] = muls_o_y[0];
            mul_1_w[2] = muls_o_y[3];
            mul_1_w[3] = muls_o_y[2];
            mul_1_w[4] = muls_o_y[5];
            mul_1_w[5] = muls_o_y[4];
            mul_1_w[6] = muls_o_y[7];
            mul_1_w[7] = muls_o_y[6];

            mul_1_w[8] = mul_1_r[0];
            mul_1_w[9] = mul_1_r[1];
            mul_1_w[10] = mul_1_r[2];
            mul_1_w[11] = mul_1_r[3];
            mul_1_w[12] = mul_1_r[4];
            mul_1_w[13] = mul_1_r[5];
            mul_1_w[14] = mul_1_r[6];
            mul_1_w[15] = mul_1_r[7];

            // R11_w = R11_temp << 8; 

            Q_computing_previous_w = 0;

        end
        5'b10_100 : begin 

                // o_y_hat_w[119:100] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));  
                
                // o_r_w[319:300] = root_inst;        
                    
            mul_1_w[8] = muls_o_y[0];
            mul_1_w[9] = muls_o_y[1];
            mul_1_w[10] = muls_o_y[2];
            mul_1_w[11] = muls_o_y[3];
            mul_1_w[12] = muls_o_y[4];
            mul_1_w[13] = muls_o_y[5];
            mul_1_w[14] = muls_o_y[6];
            mul_1_w[15] = muls_o_y[7];

            mul_1_w[0] = $signed(h_i_data[1]);
            mul_1_w[1] = $signed(h_i_data[0]);
            mul_1_w[2] = muls_h_i0[1][1][1];
            mul_1_w[3] = muls_h_i0[1][1][0];
            mul_1_w[4] = muls_h_i0[2][1][1];
            mul_1_w[5] = muls_h_i0[2][1][0];
            mul_1_w[6] = muls_h_i0[3][1][1];
            mul_1_w[7] = muls_h_i0[3][1][0];

            // mul_2_w[0] = $signed({Q_re[1][h_width + inv_sqrt_width - 1 + 1], Q_re[1][h_frac + inv_sqrt_frac +: Q_int], Q_re[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[1] = $signed({Q_im[1][h_width + inv_sqrt_width - 1 + 1], Q_im[1][h_frac + inv_sqrt_frac +: Q_int], Q_im[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[2] = $signed({Q_re[2][h_width + inv_sqrt_width - 1 + 1], Q_re[2][h_frac + inv_sqrt_frac +: Q_int], Q_re[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[3] = $signed({Q_im[2][h_width + inv_sqrt_width - 1 + 1], Q_im[2][h_frac + inv_sqrt_frac +: Q_int], Q_im[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[4] = $signed({Q_re[3][h_width + inv_sqrt_width - 1 + 1], Q_re[3][h_frac + inv_sqrt_frac +: Q_int], Q_re[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[5] = $signed({Q_im[3][h_width + inv_sqrt_width - 1 + 1], Q_im[3][h_frac + inv_sqrt_frac +: Q_int], Q_im[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[6] = $signed({Q_re[4][h_width + inv_sqrt_width - 1 + 1], Q_re[4][h_frac + inv_sqrt_frac +: Q_int], Q_re[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[7] = $signed({Q_im[4][h_width + inv_sqrt_width - 1 + 1], Q_im[4][h_frac + inv_sqrt_frac +: Q_int], Q_im[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});

            Q_computing_previous_w = 1;

        end
        5'b11_000 : begin 
                // o_y_hat_w[139:120] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));  // now

            mul_1_w[0] = muls_o_y[1];
            mul_1_w[1] = muls_o_y[0];
            mul_1_w[2] = muls_o_y[3];
            mul_1_w[3] = muls_o_y[2];
            mul_1_w[4] = muls_o_y[5];
            mul_1_w[5] = muls_o_y[4];
            mul_1_w[6] = muls_o_y[7];
            mul_1_w[7] = muls_o_y[6];


            mul_1_w[ 8] = muls_h_i0[1][1][1];
            mul_1_w[ 9] = muls_h_i0[1][1][0];
            mul_1_w[10] = muls_h_i0[2][1][1];
            mul_1_w[11] = muls_h_i0[2][1][0];
            mul_1_w[12] = muls_h_i0[3][1][1];
            mul_1_w[13] = muls_h_i0[3][1][0];
            mul_1_w[14] = $signed(i_data_r[47 -: h_width]);
            mul_1_w[15] = $signed(i_data_r[23 -: h_width]);

            // R11_w = R11_temp << 8; 

            Q_computing_previous_w = 0;

            

        end
        5'b11_001 : begin 
            //if (counter_re_r != 0) begin 
            // o_y_hat_w[159:140] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));
            //end

            mul_1_w[0] = muls_h_i0[1][2][1];
            mul_1_w[1] = muls_h_i0[1][2][0];
            mul_1_w[2] = muls_h_i0[2][2][1];
            mul_1_w[3] = muls_h_i0[2][2][0];
            mul_1_w[4] = muls_h_i0[3][2][1];
            mul_1_w[5] = muls_h_i0[3][2][0];
            mul_1_w[6] = $signed(i_data_r[47 -: h_width]);
            mul_1_w[7] = $signed(i_data_r[23 -: h_width]);
            mul_1_w[8] = muls_h_i0[1][2][0];
            mul_1_w[9] = muls_h_i0[1][2][1];
            mul_1_w[10] = muls_h_i0[2][2][0];
            mul_1_w[11] = muls_h_i0[2][2][1];
            mul_1_w[12] = muls_h_i0[3][2][0];
            mul_1_w[13] = muls_h_i0[3][2][1];
            mul_1_w[14] = $signed(i_data_r[23 -: h_width]);
            mul_1_w[15] = $signed(i_data_r[47 -: h_width]);

            // mul_2_w[0] = $signed({Q_re[1][h_width + inv_sqrt_width - 1 + 1], Q_re[1][h_frac + inv_sqrt_frac +: Q_int], Q_re[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[1] = $signed({Q_im[1][h_width + inv_sqrt_width - 1 + 1], Q_im[1][h_frac + inv_sqrt_frac +: Q_int], Q_im[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[2] = $signed({Q_re[2][h_width + inv_sqrt_width - 1 + 1], Q_re[2][h_frac + inv_sqrt_frac +: Q_int], Q_re[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[3] = $signed({Q_im[2][h_width + inv_sqrt_width - 1 + 1], Q_im[2][h_frac + inv_sqrt_frac +: Q_int], Q_im[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[4] = $signed({Q_re[3][h_width + inv_sqrt_width - 1 + 1], Q_re[3][h_frac + inv_sqrt_frac +: Q_int], Q_re[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[5] = $signed({Q_im[3][h_width + inv_sqrt_width - 1 + 1], Q_im[3][h_frac + inv_sqrt_frac +: Q_int], Q_im[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[6] = $signed({Q_re[4][h_width + inv_sqrt_width - 1 + 1], Q_re[4][h_frac + inv_sqrt_frac +: Q_int], Q_re[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
            // mul_2_w[7] = $signed({Q_im[4][h_width + inv_sqrt_width - 1 + 1], Q_im[4][h_frac + inv_sqrt_frac +: Q_int], Q_im[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});

            o_rd_vld_w = first_vld_r;
            first_vld_w = 1;


        end
        5'b11_010 : begin 

                // o_r_w[59 : 40] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
                // o_r_w[39 : 20] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
            

            mul_1_w[0] = muls_h_i0[1][3][1];
            mul_1_w[1] = muls_h_i0[1][3][0];
            mul_1_w[2] = muls_h_i0[2][3][1];
            mul_1_w[3] = muls_h_i0[2][3][0];
            mul_1_w[4] = muls_h_i0[3][3][1];
            mul_1_w[5] = muls_h_i0[3][3][0];
            mul_1_w[6] = $signed(i_data_r[47 -: h_width]);
            mul_1_w[7] = $signed(i_data_r[23 -: h_width]);
            mul_1_w[8] = muls_h_i0[1][3][0];
            mul_1_w[9] = muls_h_i0[1][3][1];
            mul_1_w[10] = muls_h_i0[2][3][0];
            mul_1_w[11] = muls_h_i0[2][3][1];
            mul_1_w[12] = muls_h_i0[3][3][0];
            mul_1_w[13] = muls_h_i0[3][3][1];
            mul_1_w[14] = $signed(i_data_r[23 -: h_width]);
            mul_1_w[15] = $signed(i_data_r[47 -: h_width]);

            // o_r_w[19:0] = root_inst;

            o_rd_vld_w = 0;

            o_last_data_w = (counter_re_r == 9);

        end
        5'b11_011 : begin 

                // o_r_w[119:100] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
                // o_r_w[99:80] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
            

            mul_1_w[0] = muls_h_i0[1][4][1];
            mul_1_w[1] = muls_h_i0[1][4][0];
            mul_1_w[2] = muls_h_i0[2][4][1];
            mul_1_w[3] = muls_h_i0[2][4][0];
            mul_1_w[4] = muls_h_i0[3][4][1];
            mul_1_w[5] = muls_h_i0[3][4][0];
            mul_1_w[6] = $signed(i_data_r[47 -: h_width]);
            mul_1_w[7] = $signed(i_data_r[23 -: h_width]);
            mul_1_w[8] = muls_h_i0[1][4][0];
            mul_1_w[9] = muls_h_i0[1][4][1];
            mul_1_w[10] = muls_h_i0[2][4][0];
            mul_1_w[11] = muls_h_i0[2][4][1];
            mul_1_w[12] = muls_h_i0[3][4][0];
            mul_1_w[13] = muls_h_i0[3][4][1];
            mul_1_w[14] = $signed(i_data_r[23 -: h_width]);
            mul_1_w[15] = $signed(i_data_r[47 -: h_width]);
        end
        5'b11_100 : begin 

                // o_r_w[219:200] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
                // o_r_w[199:180] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
            

            mul_1_w[0] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[1] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[2] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[3] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[4] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[5] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[6] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[7] = $signed({o_r_r[59],o_r_r[56 - r_frac +: (r_width-1)]});
            mul_1_w[8] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});
            mul_1_w[9] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});
            mul_1_w[10] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});
            mul_1_w[11] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});
            mul_1_w[12] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});
            mul_1_w[13] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});
            mul_1_w[14] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});
            mul_1_w[15] = $signed({o_r_r[39],o_r_r[36 - r_frac +: (r_width-1)]});

        end
    endcase

    R11_w = R11_temp; 

    o_r_w[299:280] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
    o_r_w[279:260] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));

    o_r_w[259:240] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
    o_r_w[239:220] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));

    o_r_w[219:200] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
    o_r_w[199:180] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));  

    o_r_w[159:140] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
    o_r_w[139:120] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));   

    o_r_w[119:100] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
    o_r_w[99:80] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));

    o_r_w[59 : 40] = {R1_234_im[Q_width + h_width - 1 + 3], R1_234_im[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));
    o_r_w[39 : 20] = {R1_234_re[Q_width + h_width - 1 + 3], R1_234_re[0 +: (h_frac + Q_frac - 16 + 19)]} << (16-(h_frac + Q_frac));

    o_r_w[19:0] = root_inst;
    o_r_w[319:300] = root_inst;
    o_r_w[179:160] = root_inst;
    o_r_w[79:60] = root_inst;

    o_y_hat_w[159:140] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));
    o_y_hat_w[139:120] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));
    o_y_hat_w[119:100] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));  
    o_y_hat_w[99:80] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));  
    o_y_hat_w[79:60] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));
    o_y_hat_w[59:40] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));
    o_y_hat_w[39:20] = {y_im[Q_width + y_width - 1 + 3], y_im[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));
    o_y_hat_w[19:0] = {y_re[Q_width + y_width - 1 + 3], y_re[0 +: (y_frac + Q_frac - 16 + 19)]} << (16-(y_frac + Q_frac));

    h_i0_w[1][1] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
    h_i0_w[1][2] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
    h_i0_w[1][3] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
    h_i0_w[1][4] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
    h_i0_w[2][3] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
    h_i0_w[2][4] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[2][1][2*h_width-1 -: h_width] = $signed(h_i0_r[1][2][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            h_i0_w[2][1][0 +: h_width] =  $signed(h_i0_r[1][2][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
        end
        5'b01_000 : begin 
            h_i0_w[2][1] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[2][2][2*h_width-1 -: h_width] = $signed(h_i0_r[2][2][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            h_i0_w[2][2][0 +: h_width] =  $signed(h_i0_r[2][2][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);   
        end
        5'b01_001 : begin 
            h_i0_w[2][2] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[3][3][2*h_width-1 -: h_width] = $signed(h_i0_r[3][3][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            h_i0_w[3][3][0 +: h_width] =  $signed(h_i0_r[3][3][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
        end
        5'b10_010 : begin 
            h_i0_w[3][3] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[4][3][2*h_width-1 -: h_width] = $signed(h_i0_r[4][3][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            h_i0_w[4][3][0 +: h_width] =  $signed(h_i0_r[4][3][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
        end
        5'b11_010 : begin 
            h_i0_w[4][3] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[4][4][2*h_width-1 -: h_width] = $signed(h_i0_r[4][4][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            h_i0_w[4][4][0 +: h_width] =  $signed(h_i0_r[4][4][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
        end
        5'b11_011 : begin 
            h_i0_w[4][4] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[3][4][2*h_width-1 -: h_width] = $signed(h_i0_r[3][4][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            h_i0_w[3][4][0 +: h_width] = $signed(h_i0_r[3][4][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
        end
        5'b00_010 : begin 
            h_i0_w[3][4][2*h_width-1 -: h_width] = $signed(h_i0_r[1][4][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            h_i0_w[3][4][0 +: h_width] = $signed(h_i0_r[1][4][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
        end
        5'b10_011 : begin 
            h_i0_w[3][4] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end

    endcase

    case({counter_in_i_r,counter_in_j_r})
        default : begin 
            h_i0_w[4][1][2*h_width-1 -: h_width] = $signed(h_i0_r[4][1][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            h_i0_w[4][1][0 +: h_width] =  $signed(h_i0_r[4][1][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);

        end
        5'b00_000 : begin 
            h_i0_w[4][1][2*h_width-1 -: h_width] = $signed(h_i0_r[3][2][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            h_i0_w[4][1][0 +: h_width] =  $signed(h_i0_r[3][2][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
        end
        5'b00_010 : begin 
            h_i0_w[4][1][2*h_width-1 -: h_width] = $signed(h_i0_r[2][4][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            h_i0_w[4][1][0 +: h_width] =  $signed(h_i0_r[2][4][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
        end
        5'b11_000 : begin 
            h_i0_w[4][1] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default : begin 
            h_i0_w[4][2][2*h_width-1 -: h_width] = $signed(h_i0_r[4][2][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            h_i0_w[4][2][0 +: h_width] =  $signed(h_i0_r[4][2][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
        end
        5'b00_000 : begin 
            h_i0_w[4][2][2*h_width-1 -: h_width] = $signed(h_i0_r[4][2][2*h_width-1 -: h_width]) - $signed(h_i123[4][2*h_width-1 -: h_width]);
            h_i0_w[4][2][0 +: h_width] =  $signed(h_i0_r[4][2][0 +: h_width]) - $signed(h_i123[4][0 +: h_width]);
        end
        5'b00_010 : begin 
            h_i0_w[4][2][2*h_width-1 -: h_width] = $signed(h_i0_r[3][4][2*h_width-1 -: h_width]) - $signed(h_i123[3][2*h_width-1 -: h_width]);
            h_i0_w[4][2][0 +: h_width] =  $signed(h_i0_r[3][4][0 +: h_width]) - $signed(h_i123[3][0 +: h_width]);
        end
        5'b11_001 : begin 
            h_i0_w[4][2] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[3][1][2*h_width-1 -: h_width] = $signed(h_i0_r[3][1][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            h_i0_w[3][1][0 +: h_width] =  $signed(h_i0_r[3][1][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
        end
        5'b00_001 : begin 
            h_i0_w[3][1][2*h_width-1 -: h_width] = $signed(h_i0_r[1][3][2*h_width-1 -: h_width]) - $signed(h_i123[1][2*h_width-1 -: h_width]);
            h_i0_w[3][1][0 +: h_width] =  $signed(h_i0_r[1][3][0 +: h_width]) - $signed(h_i123[1][0 +: h_width]);
        end
        5'b10_000 : begin 
            h_i0_w[3][1] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    case({counter_in_i_r,counter_in_j_r})
        default: begin 
            h_i0_w[3][2][2*h_width-1 -: h_width] = $signed(h_i0_r[3][2][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            h_i0_w[3][2][0 +: h_width] =  $signed(h_i0_r[3][2][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
        end
        5'b00_001 : begin 
            h_i0_w[3][2][2*h_width-1 -: h_width] = $signed(h_i0_r[2][3][2*h_width-1 -: h_width]) - $signed(h_i123[2][2*h_width-1 -: h_width]);
            h_i0_w[3][2][0 +: h_width] =  $signed(h_i0_r[2][3][0 +: h_width]) - $signed(h_i123[2][0 +: h_width]);
        end
        5'b10_001 : begin 
            h_i0_w[3][2] = {i_data_r[47 -: h_width],i_data_r[23 -: h_width]};
        end
    endcase

    mul_2_w[0] = $signed({Q_re[1][h_width + inv_sqrt_width - 1 + 1], Q_re[1][h_frac + inv_sqrt_frac +: Q_int], Q_re[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
    mul_2_w[1] = $signed({Q_im[1][h_width + inv_sqrt_width - 1 + 1], Q_im[1][h_frac + inv_sqrt_frac +: Q_int], Q_im[1][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
    mul_2_w[2] = $signed({Q_re[2][h_width + inv_sqrt_width - 1 + 1], Q_re[2][h_frac + inv_sqrt_frac +: Q_int], Q_re[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
    mul_2_w[3] = $signed({Q_im[2][h_width + inv_sqrt_width - 1 + 1], Q_im[2][h_frac + inv_sqrt_frac +: Q_int], Q_im[2][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
    mul_2_w[4] = $signed({Q_re[3][h_width + inv_sqrt_width - 1 + 1], Q_re[3][h_frac + inv_sqrt_frac +: Q_int], Q_re[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
    mul_2_w[5] = $signed({Q_im[3][h_width + inv_sqrt_width - 1 + 1], Q_im[3][h_frac + inv_sqrt_frac +: Q_int], Q_im[3][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
    mul_2_w[6] = $signed({Q_re[4][h_width + inv_sqrt_width - 1 + 1], Q_re[4][h_frac + inv_sqrt_frac +: Q_int], Q_re[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});
    mul_2_w[7] = $signed({Q_im[4][h_width + inv_sqrt_width - 1 + 1], Q_im[4][h_frac + inv_sqrt_frac +: Q_int], Q_im[4][h_frac + inv_sqrt_frac - 1 -: Q_frac]});

end

// Sequential

always@(posedge i_clk or posedge i_rst) begin 
    if (i_rst) begin 
        o_rd_vld_r <= 0;
        o_last_data_r <= 0;
        o_y_hat_r <= 0;
        o_y_hat_next_r <= 0;
        o_y_hat_now_r <= 0;
        o_r_r <= 0;
        counter_in_i_r <= 0;
        counter_in_j_r <= 0;
        counter_re_r <= 0;
        R11_r <= 0;
        Q_computing_r <= 0;
        inv_sqrt_r <= 0;
        first_vld_r <= 0;
        Q_computing_previous_r <= 0;
        
        for (i=1;i<5;i=i+1) begin 
            for (j=1;j<5;j=j+1) h_i0_r[i][j] <= 0;
            // Q_r[i] <= 0;
        end 
        for (i=0;i<16;i=i+1) begin 
            mul_1_r[i] <= 0;
        end
        for (i=0;i<8;i=i+1) begin 
            mul_2_r[i] <= 0;
        end
    end
    else begin 
        o_rd_vld_r <= o_rd_vld_w;
        // o_last_data_r <= (counter_re_r == 9 && {counter_in_i_r,counter_in_j_r} == 5'b11010)? 1 : 0;
        o_last_data_r <= o_last_data_w;
        first_vld_r <= first_vld_w;
        Q_computing_previous_r <= Q_computing_previous_w;

        if ({counter_in_i_r, counter_in_j_r} == 5'b11_001)  o_y_hat_r[159:140] <= o_y_hat_w[159:140];
        if ({counter_in_i_r, counter_in_j_r} == 5'b11_000)  o_y_hat_r[139:120] <= o_y_hat_w[139:120];
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b10_1) o_y_hat_r[119:100] <= o_y_hat_w[119:100];
        if ({counter_in_i_r, counter_in_j_r} == 5'b10_011)  o_y_hat_r[ 99: 80] <= o_y_hat_w[ 99: 80];
        if ({counter_in_i_r, counter_in_j_r} == 5'b10_000)  o_y_hat_r[ 79: 60] <= o_y_hat_w[ 79: 60];
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b01_1) o_y_hat_r[ 59: 40] <= o_y_hat_w[ 59: 40];
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b00_1) o_y_hat_r[ 39: 20] <= o_y_hat_w[ 39: 20];
        if ({counter_in_i_r, counter_in_j_r} == 5'b00_011)  o_y_hat_r[ 19:  0] <= o_y_hat_w[ 19:  0];

        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b10_1) o_y_hat_next_r[119:80] <= o_y_hat_next_w[119:80];
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b01_1) o_y_hat_next_r[ 79:40] <= o_y_hat_next_w[ 79:40];
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b00_1) o_y_hat_next_r[ 39: 0] <= o_y_hat_next_w[ 39: 0];

        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b11_1) o_y_hat_now_r[159:120] <= o_y_hat_now_w[159:120];
        if ({counter_in_i_r, counter_in_j_r} == 5'b00_000)  o_y_hat_now_r[119: 0] <= o_y_hat_now_w[119: 0];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b00_000)  o_y_hat_now_r[ 79: 40] <= o_y_hat_now_w[ 79: 40];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b00_000)  o_y_hat_now_r[ 39:  0] <= o_y_hat_now_w[ 39:  0];


        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b10_1) o_r_r[319:300] <= o_r_w[319:300];
        if ({counter_in_i_r, counter_in_j_r} == 5'b10_001)  o_r_r[299:260] <= o_r_w[299:260];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b10_001)  o_r_r[279:260] <= o_r_w[279:260];
        if ({counter_in_i_r, counter_in_j_r} == 5'b01_001)  o_r_r[259:220] <= o_r_w[259:220];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b01_001)  o_r_r[239:220] <= o_r_w[239:220];
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b11_1) o_r_r[219:180] <= o_r_w[219:180];
        // if ({counter_in_i_r, counter_in_j_r[2]} == 3'b11_1) o_r_r[199:180] <= o_r_w[199:180];
        if ({counter_in_i_r, counter_in_j_r} == 5'b10_000)  o_r_r[179:160] <= o_r_w[179:160];
        if ({counter_in_i_r, counter_in_j_r} == 5'b01_000)  o_r_r[159:120] <= o_r_w[159:120];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b01_000)  o_r_r[139:120] <= o_r_w[139:120];
        if ({counter_in_i_r, counter_in_j_r} == 5'b11_011)  o_r_r[119: 80] <= o_r_w[119: 80];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b11_011)  o_r_r[ 99: 80] <= o_r_w[ 99: 80];
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b00_1) o_r_r[ 79: 60] <= o_r_w[ 79: 60];
        if ({counter_in_i_r, counter_in_j_r} == 5'b11_010)  o_r_r[ 59:  0] <= o_r_w[ 59:  0];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b11_010)  o_r_r[ 39: 20] <= o_r_w[ 39: 20];
        // if ({counter_in_i_r, counter_in_j_r} == 5'b11_010)  o_r_r[ 19:  0] <= o_r_w[ 19:  0];


        counter_in_i_r <= counter_in_i_w;
        counter_in_j_r <= counter_in_j_w;
        if ({counter_in_i_r, counter_in_j_r[2]} == 3'b11_1) counter_re_r <= counter_re_w; 

        Q_computing_r <= Q_computing_previous_r;
        if (Q_computing_previous_r) R11_r <= R11_w;
        if (Q_computing_previous_r) inv_sqrt_r <= inv_sqrt;

        if ({counter_in_i_r, counter_in_j_r} == 5'b00_000) h_i0_r[1][1] <= h_i0_w[1][1];
        if ({counter_in_i_r, counter_in_j_r} == 5'b00_001) h_i0_r[1][2] <= h_i0_w[1][2];
        if ({counter_in_i_r, counter_in_j_r} == 5'b00_010) h_i0_r[1][3] <= h_i0_w[1][3];
        if ({counter_in_i_r, counter_in_j_r} == 5'b00_011) h_i0_r[1][4] <= h_i0_w[1][4];
        if (({counter_in_i_r, counter_in_j_r} == 5'b01_000) || ({counter_in_i_r, counter_in_j_r} == 5'b00_000)) h_i0_r[2][1] <= h_i0_w[2][1];
        if (({counter_in_i_r, counter_in_j_r} == 5'b00_000) || ({counter_in_i_r, counter_in_j_r} == 5'b01_001)) h_i0_r[2][2] <= h_i0_w[2][2];
        if ({counter_in_i_r, counter_in_j_r} == 5'b01_010) h_i0_r[2][3] <= h_i0_w[2][3];
        if ({counter_in_i_r, counter_in_j_r} == 5'b01_011) h_i0_r[2][4] <= h_i0_w[2][4];
        if (({counter_in_i_r, counter_in_j_r} == 5'b10_000) || ({counter_in_i_r, counter_in_j_r} == 5'b00_001) || ({counter_in_i_r, counter_in_j_r} == 5'b01_010)) h_i0_r[3][1] <= h_i0_w[3][1];
        if (({counter_in_i_r, counter_in_j_r} == 5'b10_001) || ({counter_in_i_r, counter_in_j_r} == 5'b00_001) || ({counter_in_i_r, counter_in_j_r} == 5'b01_010)) h_i0_r[3][2] <= h_i0_w[3][2];
        if (({counter_in_i_r, counter_in_j_r} == 5'b10_010) || ({counter_in_i_r, counter_in_j_r} == 5'b00_001) || ({counter_in_i_r, counter_in_j_r} == 5'b01_010)) h_i0_r[3][3] <= h_i0_w[3][3];
        if (({counter_in_i_r, counter_in_j_r} == 5'b10_011) || ({counter_in_i_r, counter_in_j_r} == 5'b00_010) || ({counter_in_i_r, counter_in_j_r} == 5'b01_011) || ({counter_in_i_r, counter_in_j_r} == 5'b10_010)) h_i0_r[3][4] <= h_i0_w[3][4];
        if (({counter_in_i_r, counter_in_j_r} == 5'b11_000) || ({counter_in_i_r, counter_in_j_r} == 5'b00_000) || ({counter_in_i_r, counter_in_j_r} == 5'b00_010) || ({counter_in_i_r, counter_in_j_r} == 5'b01_011) || ({counter_in_i_r, counter_in_j_r} == 5'b10_010)) h_i0_r[4][1] <= h_i0_w[4][1];
        if (({counter_in_i_r, counter_in_j_r} == 5'b11_001) || ({counter_in_i_r, counter_in_j_r} == 5'b00_000) || ({counter_in_i_r, counter_in_j_r} == 5'b00_010) || ({counter_in_i_r, counter_in_j_r} == 5'b01_011) || ({counter_in_i_r, counter_in_j_r} == 5'b10_010)) h_i0_r[4][2] <= h_i0_w[4][2];
        if (({counter_in_i_r, counter_in_j_r} == 5'b11_010) || ({counter_in_i_r, counter_in_j_r} == 5'b00_001) || ({counter_in_i_r, counter_in_j_r} == 5'b01_010)) h_i0_r[4][3] <= h_i0_w[4][3];
        if (({counter_in_i_r, counter_in_j_r} == 5'b11_011) || ({counter_in_i_r, counter_in_j_r} == 5'b00_010) || ({counter_in_i_r, counter_in_j_r} == 5'b01_011) || ({counter_in_i_r, counter_in_j_r} == 5'b10_010)) h_i0_r[4][4] <= h_i0_w[4][4];

        for (i=0;i<16;i=i+1) begin 
            mul_1_r[i] <= mul_1_w[i];
        end
        for (i=0;i<8;i=i+1) begin 
            if (Q_computing_r) mul_2_r[i] <= mul_2_w[i];
        end
    end
end

// Sequential (Input) 

always@(posedge i_clk or posedge i_rst) begin 
    if (i_rst) begin 
        i_trig_r <= 0;
        i_data_r <= 0;
    end
    else begin
        if (i_trig) i_trig_r <= 1;
        
        // if (i_trig) i_data_r <= i_data;

        if (i_trig) i_data_r[47 -: h_width] <= h_i_data[1];
        if (i_trig) i_data_r[23 -: h_width] <= h_i_data[0];
    end
end

endmodule