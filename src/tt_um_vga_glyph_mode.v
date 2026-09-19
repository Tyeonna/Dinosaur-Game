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

    // ------------------------------------------------------------
    // VGA
    // ------------------------------------------------------------

    wire hsync, vsync, display_on;
    wire [10:0] hpos;
    wire [9:0] vpos;

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

    assign uio_out = 0;
    assign uio_oe  = 0;

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

    // ------------------------------------------------------------
    // CONTROLS
    //
    // ui_in[0] = JUMP
    // ui_in[1] = RESET
    // ------------------------------------------------------------

    wire jump_button  = ui_in[0];
    wire reset_button = ui_in[1];

    // ------------------------------------------------------------
    // GAME CONSTANTS
    // ------------------------------------------------------------

    localparam GROUND = 10'd400;

    localparam DINO_X = 10'd80;
    localparam DINO_W = 10'd28;
    localparam DINO_H = 10'd36;

    localparam CACTUS_W = 10'd20;
    localparam CACTUS_H = 10'd40;

    // ------------------------------------------------------------
    // GAME VARIABLES
    // ------------------------------------------------------------

    reg [9:0] dino_y;
    reg [9:0] cactus_x;

    reg [5:0] jump_timer;

    reg game_over;

    // Score in BCD
    reg [3:0] score_hundreds;
    reg [3:0] score_tens;
    reg [3:0] score_ones;

    reg [2:0] score_timer;

    // ------------------------------------------------------------
    // FRAME TICK
    // ------------------------------------------------------------

    wire frame_tick =
        (hpos == 11'd0) &&
        (vpos == 10'd0);

    // ------------------------------------------------------------
    // GAME LOGIC
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin

            dino_y <= GROUND - DINO_H;
            cactus_x <= 10'd600;

            jump_timer <= 0;

            game_over <= 0;

            score_hundreds <= 0;
            score_tens <= 0;
            score_ones <= 0;

            score_timer <= 0;

        end

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        else if (reset_button) begin

            dino_y <= GROUND - DINO_H;
            cactus_x <= 10'd600;

            jump_timer <= 0;

            game_over <= 0;

            score_hundreds <= 0;
            score_tens <= 0;
            score_ones <= 0;

            score_timer <= 0;

        end

        // --------------------------------------------------------
        // GAME UPDATE
        // --------------------------------------------------------

        else if (frame_tick && !game_over) begin

            // ----------------------------------------------------
            // JUMP
            // ----------------------------------------------------

            if (jump_button &&
                jump_timer == 0 &&
                dino_y == GROUND - DINO_H) begin

                jump_timer <= 1;

            end

            // ----------------------------------------------------
            // JUMP MOVEMENT
            // ----------------------------------------------------

            if (jump_timer > 0) begin

                jump_timer <= jump_timer + 1;

                // Going UP
                if (jump_timer < 10) begin

                    dino_y <= dino_y - 10;

                end

                // Going DOWN
                else if (jump_timer < 20) begin

                    dino_y <= dino_y + 10;

                end

                // Back to ground
                else begin

                    dino_y <= GROUND - DINO_H;
                    jump_timer <= 0;

                end

            end

            // ----------------------------------------------------
            // MOVE CACTUS
            // ----------------------------------------------------

            if (cactus_x > 10)

                cactus_x <= cactus_x - 5;

            else

                cactus_x <= 640;

            // ----------------------------------------------------
            // SCORE
            // ----------------------------------------------------

            if (score_timer == 5) begin

                score_timer <= 0;

                if (score_ones == 9) begin

                    score_ones <= 0;

                    if (score_tens == 9) begin

                        score_tens <= 0;

                        if (score_hundreds < 9)
                            score_hundreds <= score_hundreds + 1;

                    end

                    else begin

                        score_tens <= score_tens + 1;

                    end

                end

                else begin

                    score_ones <= score_ones + 1;

                end

            end

            else begin

                score_timer <= score_timer + 1;

            end

            // ----------------------------------------------------
            // COLLISION
            // ----------------------------------------------------

            if (
                (DINO_X + DINO_W > cactus_x) &&
                (DINO_X < cactus_x + CACTUS_W) &&
                (dino_y + DINO_H > GROUND - CACTUS_H)
            ) begin

                game_over <= 1'b1;

            end

        end

    end

    // ------------------------------------------------------------
    // GROUND
    // ------------------------------------------------------------

    wire ground_pixel =
        (vpos >= GROUND) &&
        (vpos < GROUND + 4);

    // ------------------------------------------------------------
    // DINO
    // ------------------------------------------------------------

    wire dino_body =
        (hpos >= DINO_X) &&
        (hpos < DINO_X + DINO_W) &&
        (vpos >= dino_y) &&
        (vpos < dino_y + DINO_H);

    wire dino_cut =
        (hpos < DINO_X + 7) &&
        (vpos < dino_y + 7);

    wire dino_pixel =
        dino_body && !dino_cut;

    wire dino_eye =
        (hpos >= DINO_X + 19) &&
        (hpos < DINO_X + 23) &&
        (vpos >= dino_y + 7) &&
        (vpos < dino_y + 11);

    // ------------------------------------------------------------
    // CACTUS
    // ------------------------------------------------------------

    wire cactus_trunk =
        (hpos >= cactus_x) &&
        (hpos < cactus_x + 10) &&
        (vpos >= GROUND - CACTUS_H) &&
        (vpos < GROUND);

    wire cactus_left =
        (hpos >= cactus_x - 8) &&
        (hpos < cactus_x) &&
        (vpos >= GROUND - 25) &&
        (vpos < GROUND - 10);

    wire cactus_right =
        (hpos >= cactus_x + 10) &&
        (hpos < cactus_x + 18) &&
        (vpos >= GROUND - 30) &&
        (vpos < GROUND - 15);

    wire cactus_pixel =
        cactus_trunk |
        cactus_left |
        cactus_right;

    // ------------------------------------------------------------
    // SCORE DISPLAY
    //
    // SCORE 000
    // ------------------------------------------------------------

    reg [5:0] score_glyph;

    // FIXED WIDTHS:
    // hpos is 11 bits, so score_x is 11 bits.
    // vpos is 10 bits, so score_y is 10 bits.
    reg [10:0] score_x;
    reg [9:0] score_y;

    wire score_area =
        (hpos >= 450) &&
        (hpos < 540) &&
        (vpos >= 15) &&
        (vpos < 28);

    always @(*) begin

        score_glyph = 6'd26;
        score_x = 11'd0;
        score_y = 10'd0;

        if (score_area) begin

            // Y POSITION
            score_y = vpos - 10'd15;

            // ----------------------------------------------------
            // S
            // ----------------------------------------------------

            if (hpos >= 450 && hpos < 460) begin

                score_glyph = 6'd18;
                score_x = hpos - 11'd450;

            end

            // ----------------------------------------------------
            // C
            // ----------------------------------------------------

            else if (hpos >= 460 && hpos < 470) begin

                score_glyph = 6'd2;
                score_x = hpos - 11'd460;

            end

            // ----------------------------------------------------
            // O
            // ----------------------------------------------------

            else if (hpos >= 470 && hpos < 480) begin

                score_glyph = 6'd14;
                score_x = hpos - 11'd470;

            end

            // ----------------------------------------------------
            // R
            // ----------------------------------------------------

            else if (hpos >= 480 && hpos < 490) begin

                score_glyph = 6'd17;
                score_x = hpos - 11'd480;

            end

            // ----------------------------------------------------
            // E
            // ----------------------------------------------------

            else if (hpos >= 490 && hpos < 500) begin

                score_glyph = 6'd4;
                score_x = hpos - 11'd490;

            end

            // ----------------------------------------------------
            // SPACE
            // ----------------------------------------------------

            else if (hpos >= 500 && hpos < 510) begin

                score_glyph = 6'd26;
                score_x = hpos - 11'd500;

            end

            // ----------------------------------------------------
            // HUNDREDS
            // ----------------------------------------------------

            else if (hpos >= 510 && hpos < 520) begin

                case (score_hundreds)

                    0: score_glyph = 6'd36;
                    1: score_glyph = 6'd27;
                    2: score_glyph = 6'd28;
                    3: score_glyph = 6'd29;
                    4: score_glyph = 6'd30;
                    5: score_glyph = 6'd31;
                    6: score_glyph = 6'd32;
                    7: score_glyph = 6'd33;
                    8: score_glyph = 6'd34;
                    9: score_glyph = 6'd35;

                    default:
                        score_glyph = 6'd36;

                endcase

                score_x = hpos - 11'd510;

            end

            // ----------------------------------------------------
            // TENS
            // ----------------------------------------------------

            else if (hpos >= 520 && hpos < 530) begin

                case (score_tens)

                    0: score_glyph = 6'd36;
                    1: score_glyph = 6'd27;
                    2: score_glyph = 6'd28;
                    3: score_glyph = 6'd29;
                    4: score_glyph = 6'd30;
                    5: score_glyph = 6'd31;
                    6: score_glyph = 6'd32;
                    7: score_glyph = 6'd33;
                    8: score_glyph = 6'd34;
                    9: score_glyph = 6'd35;

                    default:
                        score_glyph = 6'd36;

                endcase

                score_x = hpos - 11'd520;

            end

            // ----------------------------------------------------
            // ONES
            // ----------------------------------------------------

            else if (hpos >= 530 && hpos < 540) begin

                case (score_ones)

                    0: score_glyph = 6'd36;
                    1: score_glyph = 6'd27;
                    2: score_glyph = 6'd28;
                    3: score_glyph = 6'd29;
                    4: score_glyph = 6'd30;
                    5: score_glyph = 6'd31;
                    6: score_glyph = 6'd32;
                    7: score_glyph = 6'd33;
                    8: score_glyph = 6'd34;
                    9: score_glyph = 6'd35;

                    default:
                        score_glyph = 6'd36;

                endcase

                score_x = hpos - 11'd530;

            end

        end

    end

    // ------------------------------------------------------------
    // SCORE PIXEL
    // ------------------------------------------------------------

    wire score_pixel;

    glyphs_rom score_rom(
        .c(score_glyph),
        .y(score_y[3:0]),
        .x(score_x[2:0]),
        .pixel(score_pixel)
    );

    // ------------------------------------------------------------
    // GAME OVER
    // ------------------------------------------------------------

    wire game_over_pixel =
        game_over &&
        (
            ((vpos >= 200) && (vpos < 210) &&
             (hpos >= 250) && (hpos < 390)) ||

            ((vpos >= 210) && (vpos < 260) &&
             (hpos >= 250) && (hpos < 260)) ||

            ((vpos >= 250) && (vpos < 260) &&
             (hpos >= 250) && (hpos < 390)) ||

            ((vpos >= 200) && (vpos < 260) &&
             (hpos >= 380) && (hpos < 390))
        );

    // ------------------------------------------------------------
    // VGA OUTPUT
    // ------------------------------------------------------------

    assign RGB =
        !display_on     ? 6'b000000 :
        game_over_pixel ? 6'b111111 :
        score_pixel     ? 6'b111111 :
        ground_pixel    ? 6'b111111 :
        dino_eye        ? 6'b000000 :
        dino_pixel      ? 6'b111111 :
        cactus_pixel    ? 6'b111111 :
                          6'b000000;

    wire _unused_ok =
        &{ena, uio_in, ui_in[7:2]};

endmodule
