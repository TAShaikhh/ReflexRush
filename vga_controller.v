// -----------------------------------------
// VGA Controller for 640x480 @ 60Hz, 25 MHz
// -----------------------------------------
module vga_controller (
    input        clk25,
    output reg [9:0] x,      // Horizontal pixel position (0–639)
    output reg [9:0] y,      // Vertical pixel position (0–479)
    output           hsync,
    output           vsync,
    output           valid   // High when (x, y) is within visible area
);
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    // Sync signal generation (standard VGA timing)
    assign hsync = ~((h_count >= 656) && (h_count < 752));
    assign vsync = ~((v_count >= 490) && (v_count < 492));
    assign valid = (h_count < 640 && v_count < 480);

    always @(posedge clk25) begin
        // Horizontal counter
        if (h_count == 799) begin
            h_count <= 0;

            // Vertical counter
            if (v_count == 524)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end else begin
            h_count <= h_count + 1;
        end

        // Output current pixel coordinates
        x <= h_count;
        y <= v_count;
    end
endmodule

// ---------------------------
// Clock Divider: 50MHz to 25MHz
// ---------------------------
module clock_div_50_to_25 (
    input        clk50,
    output reg   clk25 = 0
);
    always @(posedge clk50)
        clk25 <= ~clk25;
endmodule

// -----------------------------------------
// Image ROM for 3 Images (64x48, 8-bit)
// -----------------------------------------
module image_rom (
    input      [11:0] pixel_index,
    input      [1:0]  image_sel,
    output reg [7:0]  pixel_color
);

    reg [7:0] img1 [0:3071];
    reg [7:0] img2 [0:3071];

    initial $readmemh("mem/hold_image.mem",    img1);
    initial $readmemh("mem/go_image.mem",      img2);

    always @(*) begin
        case (image_sel)
            2'd1: pixel_color = img1[pixel_index];
            2'd2: pixel_color = img2[pixel_index];
            default: pixel_color = 8'h00;
        endcase
    end
endmodule



