module inv_sqrt(
    input [10:0] inv_sqrt_in, //3.8
    output reg [6:0] inv_sqrt_out //2.5
);
    

    always@(*) begin
        casez(inv_sqrt_in)

            default : inv_sqrt_out = 7'b1111111;

            // 13'b1zzzzzzzzzzzz : inv_sqrt_out = 7'b0001000;
            
            // 13'b01zzzzzzzzzzz : inv_sqrt_out = 7'b0001011;
            
            11'b10000zzzzzz : inv_sqrt_out = 7'b0010000;
            11'b10001zzzzzz : inv_sqrt_out = 7'b0010000;
            11'b10010zzzzzz : inv_sqrt_out = 7'b0001111;
            11'b10011zzzzzz : inv_sqrt_out = 7'b0001111;
            11'b10100zzzzzz : inv_sqrt_out = 7'b0001110;
            11'b10101zzzzzz : inv_sqrt_out = 7'b0001110;
            11'b10110zzzzzz : inv_sqrt_out = 7'b0001110;
            11'b10111zzzzzz : inv_sqrt_out = 7'b0001101;
            11'b11000zzzzzz : inv_sqrt_out = 7'b0001101;
            11'b11001zzzzzz : inv_sqrt_out = 7'b0001101;
            11'b11010zzzzzz : inv_sqrt_out = 7'b0001101;
            11'b11011zzzzzz : inv_sqrt_out = 7'b0001100;
            11'b11100zzzzzz : inv_sqrt_out = 7'b0001100;
            11'b11101zzzzzz : inv_sqrt_out = 7'b0001100;
            11'b11110zzzzzz : inv_sqrt_out = 7'b0001100;
            11'b11111zzzzzz : inv_sqrt_out = 7'b0001011;
            11'b010000zzzzz : inv_sqrt_out = 7'b0010111;
            11'b010001zzzzz : inv_sqrt_out = 7'b0010110;
            11'b010010zzzzz : inv_sqrt_out = 7'b0010101;
            11'b010011zzzzz : inv_sqrt_out = 7'b0010101;
            11'b010100zzzzz : inv_sqrt_out = 7'b0010100;
            11'b010101zzzzz : inv_sqrt_out = 7'b0010100;
            11'b010110zzzzz : inv_sqrt_out = 7'b0010011;
            11'b010111zzzzz : inv_sqrt_out = 7'b0010011;
            11'b011000zzzzz : inv_sqrt_out = 7'b0010010;
            11'b011001zzzzz : inv_sqrt_out = 7'b0010010;
            11'b011010zzzzz : inv_sqrt_out = 7'b0010010;
            11'b011011zzzzz : inv_sqrt_out = 7'b0010001;
            11'b011100zzzzz : inv_sqrt_out = 7'b0010001;
            11'b011101zzzzz : inv_sqrt_out = 7'b0010001;
            11'b011110zzzzz : inv_sqrt_out = 7'b0010001;
            11'b011111zzzzz : inv_sqrt_out = 7'b0010000;
            11'b0010000zzzz : inv_sqrt_out = 7'b0100000;
            11'b0010001zzzz : inv_sqrt_out = 7'b0011111;
            11'b0010010zzzz : inv_sqrt_out = 7'b0011110;
            11'b0010011zzzz : inv_sqrt_out = 7'b0011101;
            11'b0010100zzzz : inv_sqrt_out = 7'b0011101;
            11'b0010101zzzz : inv_sqrt_out = 7'b0011100;
            11'b0010110zzzz : inv_sqrt_out = 7'b0011011;
            11'b0010111zzzz : inv_sqrt_out = 7'b0011011;
            11'b0011000zzzz : inv_sqrt_out = 7'b0011010;
            11'b0011001zzzz : inv_sqrt_out = 7'b0011010;
            11'b0011010zzzz : inv_sqrt_out = 7'b0011001;
            11'b0011011zzzz : inv_sqrt_out = 7'b0011001;
            11'b0011100zzzz : inv_sqrt_out = 7'b0011000;
            11'b0011101zzzz : inv_sqrt_out = 7'b0011000;
            11'b0011110zzzz : inv_sqrt_out = 7'b0010111;
            11'b0011111zzzz : inv_sqrt_out = 7'b0010111;
            11'b00010000zzz : inv_sqrt_out = 7'b0101101;

            // 11'b00010001zzz : inv_sqrt_out = 7'b0101100;
            11'b000100010zz : inv_sqrt_out = 7'b0101100;
            11'b000100011zz : inv_sqrt_out = 7'b0101011;

            11'b00010010zzz : inv_sqrt_out = 7'b0101011;
            11'b00010011zzz : inv_sqrt_out = 7'b0101010;
            11'b00010100zzz : inv_sqrt_out = 7'b0101000;
            11'b00010101zzz : inv_sqrt_out = 7'b0101000;
            11'b00010110zzz : inv_sqrt_out = 7'b0100111;
            11'b00010111zzz : inv_sqrt_out = 7'b0100110;
            11'b00011000zzz : inv_sqrt_out = 7'b0100101;
            11'b00011001zzz : inv_sqrt_out = 7'b0100100;
            11'b00011010zzz : inv_sqrt_out = 7'b0100100;
            11'b00011011zzz : inv_sqrt_out = 7'b0100011;
            11'b00011100zzz : inv_sqrt_out = 7'b0100010;
            11'b00011101zzz : inv_sqrt_out = 7'b0100010;
            11'b00011110zzz : inv_sqrt_out = 7'b0100001;
            11'b00011111zzz : inv_sqrt_out = 7'b0100001;

            11'b0000100000z : inv_sqrt_out = 7'b1000000;
            11'b0000100001z : inv_sqrt_out = 7'b0111111;
            11'b0000100010z : inv_sqrt_out = 7'b0111110;
            11'b0000100011z : inv_sqrt_out = 7'b0111101;
            11'b0000100100z : inv_sqrt_out = 7'b0111100;
            11'b0000100101z : inv_sqrt_out = 7'b0111100;
            11'b0000100110z : inv_sqrt_out = 7'b0111011;
            11'b0000100111z : inv_sqrt_out = 7'b0111010;
            11'b0000101000z : inv_sqrt_out = 7'b0111001;
            11'b0000101001z : inv_sqrt_out = 7'b0111001;
            11'b0000101010z : inv_sqrt_out = 7'b0111000;
            11'b0000101011z : inv_sqrt_out = 7'b0110111;
            11'b0000101100z : inv_sqrt_out = 7'b0110111;
            11'b0000101101z : inv_sqrt_out = 7'b0110110;
            11'b0000101110z : inv_sqrt_out = 7'b0110101;
            11'b0000101111z : inv_sqrt_out = 7'b0110101;
            11'b0000110000z : inv_sqrt_out = 7'b0110100;
            11'b0000110001z : inv_sqrt_out = 7'b0110100;
            11'b0000110010z : inv_sqrt_out = 7'b0110011;
            11'b0000110011z : inv_sqrt_out = 7'b0110011;
            11'b0000110100z : inv_sqrt_out = 7'b0110010;
            11'b0000110101z : inv_sqrt_out = 7'b0110010;
            11'b0000110110z : inv_sqrt_out = 7'b0110001;
            11'b0000110111z : inv_sqrt_out = 7'b0110001;
            11'b0000111000z : inv_sqrt_out = 7'b0110000;
            11'b0000111001z : inv_sqrt_out = 7'b0110000;
            11'b0000111010z : inv_sqrt_out = 7'b0110000;
            11'b0000111011z : inv_sqrt_out = 7'b0101111;
            11'b0000111100z : inv_sqrt_out = 7'b0101111;
            11'b0000111101z : inv_sqrt_out = 7'b0101110;
            11'b0000111110z : inv_sqrt_out = 7'b0101110;
            11'b0000111111z : inv_sqrt_out = 7'b0101110;
            11'b00000100000 : inv_sqrt_out = 7'b1011011;
            11'b00000100001 : inv_sqrt_out = 7'b1011001;
            11'b00000100010 : inv_sqrt_out = 7'b1011000;
            11'b00000100011 : inv_sqrt_out = 7'b1010111;
            11'b00000100100 : inv_sqrt_out = 7'b1010101;
            11'b00000100101 : inv_sqrt_out = 7'b1010100;
            11'b00000100110 : inv_sqrt_out = 7'b1010011;
            11'b00000100111 : inv_sqrt_out = 7'b1010010;
            11'b00000101000 : inv_sqrt_out = 7'b1010001;
            11'b00000101001 : inv_sqrt_out = 7'b1010000;
            11'b00000101010 : inv_sqrt_out = 7'b1001111;
            11'b00000101011 : inv_sqrt_out = 7'b1001110;
            11'b00000101100 : inv_sqrt_out = 7'b1001101;
            11'b00000101101 : inv_sqrt_out = 7'b1001100;
            11'b00000101110 : inv_sqrt_out = 7'b1001011;
            11'b00000101111 : inv_sqrt_out = 7'b1001011;
            11'b00000110000 : inv_sqrt_out = 7'b1001010;
            11'b00000110001 : inv_sqrt_out = 7'b1001001;
            11'b00000110010 : inv_sqrt_out = 7'b1001000;
            11'b00000110011 : inv_sqrt_out = 7'b1001000;
            11'b00000110100 : inv_sqrt_out = 7'b1000111;
            11'b00000110101 : inv_sqrt_out = 7'b1000110;
            11'b00000110110 : inv_sqrt_out = 7'b1000110;
            11'b00000110111 : inv_sqrt_out = 7'b1000101;
            11'b00000111000 : inv_sqrt_out = 7'b1000100;
            11'b00000111001 : inv_sqrt_out = 7'b1000100;
            11'b00000111010 : inv_sqrt_out = 7'b1000011;
            11'b00000111011 : inv_sqrt_out = 7'b1000011;
            11'b00000111100 : inv_sqrt_out = 7'b1000010;
            11'b00000111101 : inv_sqrt_out = 7'b1000010;
            11'b00000111110 : inv_sqrt_out = 7'b1000001;
            11'b00000111111 : inv_sqrt_out = 7'b1000001;

            11'b00000010000 : inv_sqrt_out = 7'b1111111;
            
            11'b00000010001 : inv_sqrt_out = 7'b1111100;
            
            11'b00000010010 : inv_sqrt_out = 7'b1111001;
            
            11'b00000010011 : inv_sqrt_out = 7'b1110101;
            
            11'b00000010100 : inv_sqrt_out = 7'b1110010;
            
            11'b00000010101 : inv_sqrt_out = 7'b1110000;
            
            11'b00000010110 : inv_sqrt_out = 7'b1101101;
            
            11'b00000010111 : inv_sqrt_out = 7'b1101011;
            
            11'b00000011000 : inv_sqrt_out = 7'b1101001;
            
            11'b00000011001 : inv_sqrt_out = 7'b1100110;
            
            11'b00000011010 : inv_sqrt_out = 7'b1100100;
            
            11'b00000011011 : inv_sqrt_out = 7'b1100011;
            
            11'b00000011100 : inv_sqrt_out = 7'b1100001;
            
            11'b00000011101 : inv_sqrt_out = 7'b1011111;
            
            11'b00000011110 : inv_sqrt_out = 7'b1011101;
            
            11'b00000011111 : inv_sqrt_out = 7'b1011100;
            



            
        endcase
    end
endmodule