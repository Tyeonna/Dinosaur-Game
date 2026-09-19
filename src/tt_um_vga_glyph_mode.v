`default_nettype none

module tt_um_vga_glyph_mode(
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire ena,
    input  wire clk,
    input  wire rst_n
);

    wire hsync, vsync, display_on;
    wire [10:0] hpos;
    wire [9:0] vpos;

    // TinyVGA PMOD output
    wire [5:0] rgb;
    assign uo_out = {hsync, rgb[0], rgb[2], rgb[4],
                     vsync, rgb[1], rgb[3], rgb[5]};

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

    // ------------------------------------------------------------
    // Simple Chrome-Dino-style game
    // ui_in[0] = JUMP
    // ui_in[1] = RESET GAME
    // ------------------------------------------------------------

    reg [9:0] dino_y;
    reg signed [8:0] velocity;
    reg [9:0] cactus_x;
    reg [15:0] frame_count;
    reg game_over;

    localparam GROUND = 10'd400;
    localparam DINO_X = 10'd80;
    localparam DINO_W = 10'd28;
    localparam DINO_H = 10'd36;
    localparam CACTUS_W = 10'd18;
    localparam CACTUS_H = 10'd38;

    wire frame_tick = (hpos == 11'd0) && (vpos == 10'd0);

    // Game update: once per VGA frame.
    always @(posedge clk) begin
        if (!rst_n) begin
            dino_y     <= GROUND - DINO_H;
            velocity   <= 0;
            cactus_x   <= 10'd600;
            frame_count <= 0;
            game_over  <= 0;
        end
        else if (frame_tick) begin
            if (ui_in[1]) begin
                dino_y      <= GROUND - DINO_H;
                velocity    <= 0;
                cactus_x    <= 10'd600;
                frame_count <= 0;
                game_over   <= 0;
            end
            else if (!game_over) begin
                frame_count <= frame_count + 1'b1;

                // Jump only when standing on the ground.
                if (ui_in[0] && (dino_y == GROUND - DINO_H))
                    velocity <= -10'sd115;

                // Very simple gravity.
                if (dino_y < GROUND - DINO_H || velocity < 0) begin
                    dino_y <= dino_y + velocity;
                    velocity <= velocity + 10'sd8;

                    if (dino_y + velocity >= GROUND - DINO_H) begin
                        dino_y <= GROUND - DINO_H;
                        velocity <= 0;
                    end
                end

                // Move cactus.
                if (cactus_x > 10'd0)
                    cactus_x <= cactus_x - 10'd6;
                else
                    cactus_x <= 10'd640;

                // Simple collision box.
                if ((DINO_X + DINO_W > cactus_x) &&
                    (DINO_X < cactus_x + CACTUS_W) &&
                    (dino_y + DINO_H > GROUND - CACTUS_H)) begin
                    game_over <= 1;
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Draw pixels
    // ------------------------------------------------------------

    wire ground_pixel =
        (vpos >= GROUND) && (vpos < GROUND + 4);

    // Dino body
    wire dino_body =
        (hpos >= DINO_X) && (hpos < DINO_X + DINO_W) &&
        (vpos >= dino_y) && (vpos < dino_y + DINO_H);

    // Remove a little area to make the square look more dinosaur-like.
    wire dino_cut =
        (hpos < DINO_X + 8 && vpos < dino_y + 8) ||
        (hpos >= DINO_X + 22 && vpos >= dino_y + 30);

    wire dino_pixel = dino_body && !dino_cut;

    // Dino eye
    wire dino_eye =
        (hpos >= DINO_X + 19) && (hpos < DINO_X + 23) &&
        (vpos >= dino_y + 7) && (vpos < dino_y + 11);

    // Cactus
    wire cactus_trunk =
        (hpos >= cactus_x) && (hpos < cactus_x + 10) &&
        (vpos >= GROUND - CACTUS_H) && (vpos < GROUND);

    wire cactus_left =
        (hpos >= cactus_x - 8) && (hpos < cactus_x) &&
        (vpos >= GROUND - 25) && (vpos < GROUND - 10);

    wire cactus_right =
        (hpos >= cactus_x + 10) && (hpos < cactus_x + 18) &&
        (vpos >= GROUND - 31) && (vpos < GROUND - 16);

    wire cactus_pixel = cactus_trunk | cactus_left | cactus_right;

    // "GAME OVER" is intentionally very basic:
    // a large bar and two small bars are shown when the player loses.
    wire game_over_pixel =
        game_over &&
        (
            ((vpos >= 180) && (vpos < 190) && (hpos >= 250) && (hpos < 390)) ||
            ((vpos >= 190) && (vpos < 250) && (hpos >= 250) && (hpos < 260)) ||
            ((vpos >= 240) && (vpos < 250) && (hpos >= 250) && (hpos < 390)) ||
            ((vpos >= 180) && (vpos < 250) && (hpos >= 380) && (hpos < 390))
        );

    // Black background, white objects.
    assign rgb = !display_on ? 6'b0 :
                 game_over_pixel ? 6'b111111 :
                 ground_pixel ? 6'b111111 :
                 dino_eye ? 6'b000000 :
                 dino_pixel ? 6'b111111 :
                 cactus_pixel ? 6'b111111 :
                 6'b000000;

    wire _unused_ok = &{ena, uio_in, ui_in[7:2], frame_count[15:8]};

endmodule
