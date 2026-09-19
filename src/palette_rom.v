`default_nettype none

module palette_rom(
    input wire [2:0] cid,
    input wire [1:0] pid,
    output wire [5:0] color
);

    reg [5:0] palette [3:0][7:0];

    assign color = palette[pid][cid];

    initial begin

        // Default game palette
        palette[0][0] = 6'b000000;
        palette[0][1] = 6'b010101;
        palette[0][2] = 6'b101010;
        palette[0][3] = 6'b111111;
        palette[0][4] = 6'b111111;
        palette[0][5] = 6'b111111;
        palette[0][6] = 6'b111111;
        palette[0][7] = 6'b111111;

        // Red palette
        palette[1][0] = 6'b000000;
        palette[1][1] = 6'b010000;
        palette[1][2] = 6'b100000;
        palette[1][3] = 6'b111000;
        palette[1][4] = 6'b111100;
        palette[1][5] = 6'b111100;
        palette[1][6] = 6'b111100;
        palette[1][7] = 6'b111100;

        // Blue palette
        palette[2][0] = 6'b000000;
        palette[2][1] = 6'b000001;
        palette[2][2] = 6'b000010;
        palette[2][3] = 6'b000111;
        palette[2][4] = 6'b001111;
        palette[2][5] = 6'b011111;
        palette[2][6] = 6'b101111;
        palette[2][7] = 6'b111111;

        // Green palette
        palette[3][0] = 6'b000000;
        palette[3][1] = 6'b000100;
        palette[3][2] = 6'b001000;
        palette[3][3] = 6'b001100;
        palette[3][4] = 6'b011000;
        palette[3][5] = 6'b011100;
        palette[3][6] = 6'b101100;
        palette[3][7] = 6'b111100;

    end

endmodule
