`default_nettype none

module tt_um_vga_glyph_mode(
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // VGA
    // ============================================================

    wire hsync;
    wire vsync;
    wire display_on;

    wire [10:0] hpos;
    wire [9:0]  vpos;

    wire [5:0] RGB;

    assign uo_out = {
        hsync,
        RGB[0],
        RGB[2],
        RGB[4],
        vsync,
        RGB[1],
        RGB[3],
        RGB[5]
    };

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .mode(2'd0),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(display_on),
        .hpos(hpos),
        .vpos(vpos)
    );

    // ============================================================
    // CONTROLS
    //
    // ui_in[0] = JUMP
    // ui_in[1] = RESET
    // ============================================================

    wire jump_button  = ui_in[0];
    wire reset_button = ui_in[1];

    // Button handling
    reg jump_armed;
    reg jump_request;

    always @(posedge clk) begin

        if (!rst_n) begin
            jump_armed   <= 1'b1;
            jump_request <= 1'b0;
        end

        else if (!jump_button) begin

            // Button released.
            // Arm it for the next press.
            jump_armed <= 1'b1;

        end

        else if (jump_button && jump_armed) begin

            // New button press.
            jump_request <= 1'b1;
            jump_armed   <= 1'b0;

        end

    end

    // ============================================================
    // GAME CONSTANTS
    // ============================================================

    localparam [9:0] GROUND = 10'd400;

    localparam [9:0] DINO_X = 10'd80;
    localparam [9:0] DINO_W = 10'd28;
    localparam [9:0] DINO_H = 10'd36;

    localparam [9:0] CACTUS_W = 10'd20;
    localparam [9:0] CACTUS_H = 10'd40;

    // ============================================================
    // GAME VARIABLES
    // ============================================================

    reg [9:0] dino_y;
    reg [9:0] cactus_x;

    reg [5:0] jump_timer;

    reg game_over;

    // ============================================================
    // SCORE
    // ============================================================

    reg [3:0] score_hundreds;
    reg [3:0] score_tens;
    reg [3:0] score_ones;

    reg [2:0] score_timer;

    // ============================================================
    // FRAME TICK
    // ============================================================

    wire frame_tick =
        (hpos == 11'd0) &&
        (vpos == 10'd0);

    // ============================================================
    // GAME LOGIC
    // ============================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            dino_y <= GROUND - DINO_H;
            cactus_x <= 10'd600;

            jump_timer <= 6'd0;

            game_over <= 1'b0;

            score_hundreds <= 4'd0;
            score_tens <= 4'd0;
            score_ones <= 4'd0;

            score_timer <= 3'd0;

        end

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        else if (reset_button) begin

            dino_y <= GROUND - DINO_H;
            cactus_x <= 10'd600;

            jump_timer <= 6'd0;

            game_over <= 1'b0;

            score_hundreds <= 4'd0;
            score_tens <= 4'd0;
            score_ones <= 4'd0;

            score_timer <= 3'd0;

            jump_request <= 1'b0;

        end

        // --------------------------------------------------------
        // GAME
        // --------------------------------------------------------

        else if (frame_tick && !game_over) begin

            // ----------------------------------------------------
            // START JUMP
            // ----------------------------------------------------

            if (jump_request &&
                jump_timer == 6'd0 &&
                dino_y == GROUND - DINO_H) begin

                jump_timer <= 6'd1;
                jump_request <= 1'b0;

            end

            // ----------------------------------------------------
            // JUMP MOVEMENT
            // ----------------------------------------------------

            if (jump_timer > 6'd0) begin

                jump_timer <= jump_timer + 6'd1;

                // UP
                if (jump_timer < 6'd10) begin

                    dino_y <= dino_y - 10'd10;

                end

                // DOWN
                else if (jump_timer < 6'd20) begin

                    dino_y <= dino_y + 10'd10;

                end

                // LAND
                else begin

                    dino_y <= GROUND - DINO_H;
                    jump_timer <= 6'd0;

                end

            end

            // ----------------------------------------------------
            // CACTUS MOVEMENT
            // ----------------------------------------------------

            if (cactus_x > 10'd5) begin

                cactus_x <= cactus_x - 10'd5;

            end

            else begin

                cactus_x <= 10'd640;

            end

            // ----------------------------------------------------
            // SCORE
            // ----------------------------------------------------

            if (score_timer == 3'd5) begin

                score_timer <= 3'd0;

                if (score_ones == 4'd9) begin

                    score_ones <= 4'd0;

                    if (score_tens == 4'd9) begin

                        score_tens <= 4'd0;

                        if (score_hundreds < 4'd9)
                            score_hundreds <= score_hundreds + 4'd1;

                    end

                    else begin

                        score_tens <= score_tens + 4'd1;

                    end

                end

                else begin

                    score_ones <= score_ones + 4'd1;

                end

            end

            else begin

                score_timer <= score_timer + 3'd1;

            end

            // ----------------------------------------------------
            // COLLISION
            // ----------------------------------------------------

            if (
                ((DINO_X + DINO_W) > cactus_x) &&
                (DINO_X < (cactus_x + CACTUS_W)) &&
                ((dino_y + DINO_H) > (GROUND - CACTUS_H))
            ) begin

                game_over <= 1'b1;

            end

        end

    end

    // ============================================================
    // GROUND
    // ============================================================

    wire ground_pixel =
        (vpos >= GROUND) &&
        (vpos < (GROUND + 10'd4));

    // ============================================================
    // DINO
    // ============================================================

    wire dino_body =
        (hpos >= {1'b0, DINO_X}) &&
        (hpos < {1'b0, DINO_X + DINO_W}) &&
        (vpos >= dino_y) &&
        (vpos < (dino_y + DINO_H));

    wire dino_cut =
        (hpos < {1'b0, DINO_X + 10'd7}) &&
        (vpos < (dino_y + 10'd7));

    wire dino_pixel =
        dino_body && !dino_cut;

    wire dino_eye =
        (hpos >= {1'b0, DINO_X + 10'd19}) &&
        (hpos < {1'b0, DINO_X + 10'd23}) &&
        (vpos >= (dino_y + 10'd7)) &&
        (vpos < (dino_y + 10'd11));

    // ============================================================
    // CACTUS
    // ============================================================

    wire cactus_trunk =
        (hpos >= {1'b0, cactus_x}) &&
        (hpos < {1'b0, cactus_x + 10'd10}) &&
        (vpos >= (GROUND - CACTUS_H)) &&
        (vpos < GROUND);

    wire cactus_left =
        (hpos >= {1'b0, cactus_x - 10'd8}) &&
        (hpos < {1'b0, cactus_x}) &&
        (vpos >= (GROUND - 10'd25)) &&
        (vpos < (GROUND - 10'd10));

    wire cactus_right =
        (hpos >= {1'b0, cactus_x + 10'd10}) &&
        (hpos < {1'b0, cactus_x + 10'd18}) &&
        (vpos >= (GROUND - 10'd30)) &&
        (vpos < (GROUND - 10'd15));

    wire cactus_pixel =
        cactus_trunk |
        cactus_left |
        cactus_right;

    // ============================================================
    // SIMPLE 5x7 DIGIT FONT
    //
    // Used only for the score.
    // ============================================================

    reg [4:0] digit_bits;
    reg [3:0] digit_value;

    reg [2:0] digit_x;
    reg [2:0] digit_y;

    reg digit_pixel;

    always @(*) begin

        digit_value = 4'd0;
        digit_x = 3'd0;
        digit_y = 3'd0;
        digit_bits = 5'b00000;
        digit_pixel = 1'b0;

        // SCORE AREA
        //
        // Three digits at:
        // x = 560, 570, 580
        // y = 20 to 34

        if ((hpos >= 11'd555) &&
            (hpos < 11'd590) &&
            (vpos >= 10'd20) &&
            (vpos < 10'd35)) begin

            // Select digit

            if (hpos < 11'd566) begin

                digit_value = score_hundreds;
                digit_x = hpos - 11'd555;

            end

            else if (hpos < 11'd577) begin

                digit_value = score_tens;
                digit_x = hpos - 11'd566;

            end

            else begin

                digit_value = score_ones;
                digit_x = hpos - 11'd577;

            end

            digit_y = vpos - 10'd20;

            // 5x7 FONT

            case (digit_value)

                4'd0: begin
                    case (digit_y)
                        0: digit_bits = 5'b01110;
                        1: digit_bits = 5'b10001;
                        2: digit_bits = 5'b10011;
                        3: digit_bits = 5'b10101;
                        4: digit_bits = 5'b11001;
                        5: digit_bits = 5'b10001;
                        6: digit_bits = 5'b01110;
                        default: digit_bits = 0;
                    endcase
                end

                4'd1: begin
                    case (digit_y)
                        0: digit_bits = 5'b00100;
                        1: digit_bits = 5'b01100;
                        2: digit_bits = 5'b00100;
                        3: digit_bits = 5'b00100;
                        4: digit_bits = 5'b00100;
                        5: digit_bits = 5'b00100;
                        6: digit_bits = 5'b01110;
                        default: digit_bits = 0;
                    endcase
                end

                4'd2: begin
                    case (digit_y)
                        0: digit_bits = 5'b01110;
                        1: digit_bits = 5'b10001;
                        2: digit_bits = 5'b00001;
                        3: digit_bits = 5'b00010;
                        4: digit_bits = 5'b00100;
                        5: digit_bits = 5'b01000;
                        6: digit_bits = 5'b11111;
                        default: digit_bits = 0;
                    endcase
                end

                4'd3: begin
                    case (digit_y)
                        0: digit_bits = 5'b01110;
                        1: digit_bits = 5'b10001;
                        2: digit_bits = 5'b00001;
                        3: digit_bits = 5'b00110;
                        4: digit_bits = 5'b00001;
                        5: digit_bits = 5'b10001;
                        6: digit_bits = 5'b01110;
                        default: digit_bits = 0;
                    endcase
                end

                4'd4: begin
                    case (digit_y)
                        0: digit_bits = 5'b00010;
                        1: digit_bits = 5'b00110;
                        2: digit_bits = 5'b01010;
                        3: digit_bits = 5'b10010;
                        4: digit_bits = 5'b11111;
                        5: digit_bits = 5'b00010;
                        6: digit_bits = 5'b00010;
                        default: digit_bits = 0;
                    endcase
                end

                4'd5: begin
                    case (digit_y)
                        0: digit_bits = 5'b11111;
                        1: digit_bits = 5'b10000;
                        2: digit_bits = 5'b10000;
                        3: digit_bits = 5'b11110;
                        4: digit_bits = 5'b00001;
                        5: digit_bits = 5'b10001;
                        6: digit_bits = 5'b01110;
                        default: digit_bits = 0;
                    endcase
                end

                4'd6: begin
                    case (digit_y)
                        0: digit_bits = 5'b01110;
                        1: digit_bits = 5'b10000;
                        2: digit_bits = 5'b10000;
                        3: digit_bits = 5'b11110;
                        4: digit_bits = 5'b10001;
                        5: digit_bits = 5'b10001;
                        6: digit_bits = 5'b01110;
                        default: digit_bits = 0;
                    endcase
                end

                4'd7: begin
                    case (digit_y)
                        0: digit_bits = 5'b11111;
                        1: digit_bits = 5'b00001;
                        2: digit_bits = 5'b00010;
                        3: digit_bits = 5'b00100;
                        4: digit_bits = 5'b01000;
                        5: digit_bits = 5'b01000;
                        6: digit_bits = 5'b01000;
                        default: digit_bits = 0;
                    endcase
                end

                4'd8: begin
                    case (digit_y)
                        0: digit_bits = 5'b01110;
                        1: digit_bits = 5'b10001;
                        2: digit_bits = 5'b10001;
                        3: digit_bits = 5'b01110;
                        4: digit_bits = 5'b10001;
                        5: digit_bits = 5'b10001;
                        6: digit_bits = 5'b01110;
                        default: digit_bits = 0;
                    endcase
                end

                4'd9: begin
                    case (digit_y)
                        0: digit_bits = 5'b01110;
                        1: digit_bits = 5'b10001;
                        2: digit_bits = 5'b10001;
                        3: digit_bits = 5'b01111;
                        4: digit_bits = 5'b00001;
                        5: digit_bits = 5'b00001;
                        6: digit_bits = 5'b01110;
                        default: digit_bits = 0;
                    endcase
                end

                default:
                    digit_bits = 5'b00000;

            endcase

            if (digit_x < 5)
                digit_pixel = digit_bits[4-digit_x];

        end

    end

    // ============================================================
    // GAME OVER
    // ============================================================

    wire game_over_pixel =
        game_over &&
        (
            ((vpos >= 10'd200) &&
             (vpos < 10'd210) &&
             (hpos >= 11'd250) &&
             (hpos < 11'd390))

            ||

            ((vpos >= 10'd210) &&
             (vpos < 10'd260) &&
             (hpos >= 11'd250) &&
             (hpos < 11'd260))

            ||

            ((vpos >= 10'd250) &&
             (vpos < 10'd260) &&
             (hpos >= 11'd250) &&
             (hpos < 11'd390))

            ||

            ((vpos >= 10'd200) &&
             (vpos < 10'd260) &&
             (hpos >= 11'd380) &&
             (hpos < 11'd390))
        );

    // ============================================================
    // FINAL VGA OUTPUT
    // ============================================================

    assign RGB =
        !display_on     ? 6'b000000 :
        game_over_pixel ? 6'b111111 :
        digit_pixel     ? 6'b111111 :
        ground_pixel    ? 6'b111111 :
        dino_eye        ? 6'b000000 :
        dino_pixel      ? 6'b111111 :
        cactus_pixel     ? 6'b111111 :
                           6'b000000;

    // Prevent unused warnings
    wire _unused_ok =
        &{ena, uio_in, ui_in[7:2]};

endmodule
