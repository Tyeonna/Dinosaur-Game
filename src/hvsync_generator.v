// Video sync generator
// 640x480 VGA mode

`default_nettype none

parameter integer NM = 4;

parameter [11*NM-1:0] H_ACTIVE_PIXELS = {11'd1024, 11'd800, 11'd768, 11'd640};
parameter [10*NM-1:0] H_FRONT_PORCH   = {10'd24, 10'd40, 10'd24, 10'd16};
parameter [10*NM-1:0] H_SYNC_WIDTH    = {10'd136, 10'd128, 10'd80, 10'd96};
parameter [10*NM-1:0] H_BACK_PORCH    = {10'd160, 10'd88, 10'd104, 10'd48};
parameter [NM-1:0]    H_SYNC          = {1'b0, 1'b1, 1'b0, 1'b0};

parameter [10*NM-1:0] V_ACTIVE_LINES  = {10'd768, 10'd600, 10'd576, 10'd480};
parameter [10*NM-1:0] V_FRONT_PORCH   = {10'd3, 10'd1, 10'd1, 10'd10};
parameter [10*NM-1:0] V_SYNC_HEIGHT   = {10'd6, 10'd4, 10'd3, 10'd2};
parameter [10*NM-1:0] V_BACK_PORCH    = {10'd29, 10'd23, 10'd17, 10'd33};
parameter [NM-1:0]    V_SYNC          = {1'b0, 1'b1, 1'b1, 1'b0};

module hvsync_generator(
    clk,
    reset,
    mode,
    hsync,
    vsync,
    display_on,
    hpos,
    vpos
);

    input wire clk;
    input wire reset;
    input wire [1:0] mode;

    output reg hsync;
    output reg vsync;

    output wire display_on;

    output reg [10:0] hpos;
    output reg [9:0] vpos;

    wire [10:0] h_sync_start =
        H_ACTIVE_PIXELS[11*mode+:11] +
        H_FRONT_PORCH[10*mode+:10];

    wire [10:0] h_sync_end =
        h_sync_start +
        H_SYNC_WIDTH[10*mode+:10] - 11'd1;

    wire [10:0] h_max =
        h_sync_end +
        H_BACK_PORCH[10*mode+:10];

    wire [9:0] v_sync_start =
        V_ACTIVE_LINES[10*mode+:10] +
        V_FRONT_PORCH[10*mode+:10];

    wire [9:0] v_sync_end =
        v_sync_start +
        V_SYNC_HEIGHT[10*mode+:10] - 10'd1;

    wire [9:0] v_max =
        v_sync_end +
        V_BACK_PORCH[10*mode+:10];

    wire hmaxxed =
        (hpos == h_max) || reset;

    wire vmaxxed =
        (vpos == v_max) || reset;

    wire hactive =
        (hpos >= h_sync_start) &&
        (hpos <= h_sync_end);

    wire vactive =
        (vpos >= v_sync_start) &&
        (vpos <= v_sync_end);

    always @(posedge clk) begin

        hsync <= hactive ^ ~H_SYNC[mode];

        hpos <= hmaxxed ?
                11'd0 :
                hpos + 11'd1;

        vsync <= vactive ^ ~V_SYNC[mode];

        vpos <= hmaxxed ?
                (vmaxxed ? 10'd0 : vpos + 10'd1) :
                vpos;

    end

    assign display_on =
        (hpos < H_ACTIVE_PIXELS[11*mode+:11]) &&
        (vpos < V_ACTIVE_LINES[10*mode+:10]);

endmodule
