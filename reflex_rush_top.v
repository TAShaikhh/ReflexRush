// -------------------------------------------------------------
// Module: lfsr_gen
// Description: A 12-bit Linear Feedback Shift Register (LFSR)
//              generating a pseudo-random sequence. It uses a fixed seed.
// random number generator
// -------------------------------------------------------------
module lfsr_gen (
    // Clock input driving the LFSR updates.
    input clk,
    // 12-bit registered output that holds the pseudo-random number.
    output reg [11:0] rnd
);
    // Initialize the LFSR with a nonzero seed value to start the sequence.
    initial rnd = 12'b101001101011;
    
    // At each positive edge of the clock, update the LFSR value.
    always @(posedge clk)
        // If the current random value is 0, reinitialize it with the seed;
        // otherwise, shift left by one bit and insert the XOR of bit6 and bit7.
        rnd <= (rnd == 0) ? 12'b101001101011 : {rnd[10:0], rnd[6] ^ rnd[7]};
endmodule

// -------------------------------------------------------------
// Module: down_counter
// Description: A synchronous down counter that loads a value, 
//              decrements every clock cycle, and signals when done.
// -------------------------------------------------------------
module down_counter (
    // 12-bit value to be loaded into the counter.
    input [11:0] load_val,
    // Load control signal to load the counter with load_val.
    input load,
    // Clock input driving the counting process.
    input clk,
    // Output flag indicating when the counter reaches zero.
    output reg done
);
    // Internal 12-bit register holding the current counter value.
    reg [11:0] cnt;
    
    // On each rising edge of clk or load signal,
    always @(posedge clk or posedge load) begin
        // When load is asserted, load the counter with load_val and clear done.
        if (load) begin
            cnt <= load_val;
            done <= 0;
        end 
        // If counter has reached zero, set the done flag.
        else if (cnt == 0) begin
            done <= 1;
        end 
        // Otherwise, decrement the counter and keep done low.
        else begin
            cnt <= cnt - 1;
            done <= 0;
        end
    end
endmodule

// -------------------------------------------------------------
// Module: high_score
// Description: Tracks and updates a high score (lowest nonzero score)
//              whenever a latch signal triggers (on its negative edge).
// -------------------------------------------------------------
module high_score (
    // Latch input: a falling edge indicates it’s time to check/update the score.
    input latch,
    // 24-bit current score value that is being compared.
    input [23:0] current,
    // 24-bit register holding the best (lowest) score.
    output reg [23:0] score
);
    // On the falling edge of the latch signal,
    always @(negedge latch)
        // If score is 0 or the new current score is lower (and nonzero),
        // update the score to the current value.
        if ((score == 0 || current < score) && current != 0)
            score <= current;
endmodule

// -------------------------------------------------------------
// Module: sw_led_match
// Description: Compares an 8-bit switch value with an 8-bit LED value
//              to determine if they match, updating at each clock edge.
// -------------------------------------------------------------
module sw_led_match (
    // Clock input.
    input clk,
    // 8-bit input representing switch values.
    input [7:0] sw_val,
    // 8-bit input representing LED values.
    input [7:0] led_val,
    // Output flag that is set if sw_val equals led_val (unless led_val is zero).
    output reg match
);
    // On every rising edge of the clock, update the match signal.
    always @(posedge clk)
        // If led_val is zero then no valid match, else compare the two.
        match <= (led_val == 0) ? 0 : (sw_val == led_val);
endmodule

// -------------------------------------------------------------
// Module: hex_decoder
// Description: Converts a 4-bit binary input to a 7-segment display pattern.
// -------------------------------------------------------------
module hex_decoder (
    // 4-bit input number.
    input [3:0] in,
    // 7-bit output for driving a 7-segment display.
    output reg [6:0] seg
);
    // Combinational logic: continuously determine the segment output.
    always @* begin
        // Use a case statement to assign segment patterns based on the input value.
        case (in)
            0: seg = 7'b1000000; // Display 0.
            1: seg = 7'b1111001; // Display 1.
            2: seg = 7'b0100100; // Display 2.
            3: seg = 7'b0110000; // Display 3.
            4: seg = 7'b0011001; // Display 4.
            5: seg = 7'b0010010; // Display 5.
            6: seg = 7'b0000010; // Display 6.
            7: seg = 7'b1111000; // Display 7.
            8: seg = 7'b0000000; // Display 8.
            9: seg = 7'b0010000; // Display 9.
            // For any other input, turn all segments off (or display error).
            default: seg = 7'b1111111;
        endcase
    end
endmodule

// -------------------------------------------------------------
// Module: clock_div_50_to_1k
// Description: Divides a 50 MHz clock to produce a 1 kHz clock signal.
// -------------------------------------------------------------
module clock_div_50_to_1k (
    // 50 MHz input clock.
    input clk50,
    // Generated 1 kHz output clock (toggled at divided rate).
    output reg clk1k
);
    // 15-bit counter to count the clock cycles.
    reg [14:0] count;
    
    // On every rising edge of the 50 MHz clock,
    always @(posedge clk50) begin
        // Increment the counter by 1.
        count <= count + 15'd1;
        // When the counter reaches 24999 (half period for a 1kHz signal),
        if (count == 15'd24999) begin
            // Toggle the clk1k signal.
            clk1k <= ~clk1k;
            // Reset the counter to 0.
            count <= 15'd0;
        end
    end
endmodule

// -------------------------------------------------------------
// Module: rising_edge_detect
// Description: Detects a rising edge in the input 'signal'.
// -------------------------------------------------------------
module rising_edge_detect (
    // Input signal to monitor.
    input signal,
    // Clock input for sampling the signal.
    input clk,
    // Output flag that is high for one clock cycle when a rising edge is detected.
    output reg edge_detected
);
    // Register to store the previous value of 'signal'.
    reg prev;
    
    // On each rising edge of the clock, sample the signal.
    always @(posedge clk) begin
        // Save the current signal value to prev.
        prev <= signal;
        // Detect a rising edge: current signal is high and previous was low.
        edge_detected <= signal & ~prev;
    end
endmodule

// -------------------------------------------------------------
// Module: fsm_z_control
// Description: A simple FSM updating 'z' based on inputs 'w' and 'match'.
// -------------------------------------------------------------
module fsm_z_control (
    // Input control signal 'w'.
    input w,
    // Clock input for FSM updates.
    input clk,
    // Input signal from match comparator.
    input match,
    // Registered output 'z' representing the FSM state.
    output reg z
);
    // On every positive clock edge, update state z based on a combinational logic function.
    always @(posedge clk)
        // New state is given by: (w AND NOT z) OR (NOT match AND z).
        z <= (w & ~z) | (~match & z);
endmodule

// -------------------------------------------------------------
// Module: mux_4
// Description: A 2-to-1 multiplexer for 4-bit inputs.
// mux4 switches between modes (4 states: sp, mp, sp hs, mp hs)
// -------------------------------------------------------------
module mux_4 (
    // 4-bit input a.
    input [3:0] a,
    // 4-bit input b.
    input [3:0] b,
    // Select signal; if high, output b; if low, output a.
    input sel,
    // 4-bit output.
    output [3:0] out
);
    // Combinational assignment for the multiplexer.
    assign out = sel ? b : a;
endmodule

// -------------------------------------------------------------
// Module: mux_24
// Description: A 2-to-1 multiplexer for 24-bit inputs.
// High score tracker
// hs1 - single player hs
// hs2 - multiplayer hs
// based on mode select using SW9
// -------------------------------------------------------------
module mux_24 (
    // 24-bit input a.
    input [23:0] a,
    // 24-bit input b.
    input [23:0] b,
    // Select signal; chooses between a and b.
    input sel,
    // 24-bit output.
    output [23:0] out
);
    // Combinational assignment for the multiplexer.
    assign out = sel ? b : a;
endmodule

// -------------------------------------------------------------
// Module: counter_mod
// Description: A modulo counter with reset and enable signals that 
//              produces a pulse output (clk_out) when the count resets.
// -------------------------------------------------------------
module counter_mod (
    // Asynchronous reset input.
    input rst,
    // Enable signal to allow counting.
    input en,
    // Clock input driving the counter.
    input clk,
    // Output pulse signal generated upon count wrap-around.
    output reg clk_out,
    // 4-bit counter value output.
    output reg [3:0] val
);
    // On the rising edge of the clock or asynchronous reset,
    always @(posedge clk or posedge rst) begin
        // When reset is asserted, initialize count and output.
        if (rst) begin
            val <= 0;
            clk_out <= 0;
        end 
        // If enable is high, perform counting.
        else if (en) begin
            // Increment the counter.
            val <= val + 1;
            // When count reaches 4, clear the output pulse.
            if (val == 4)
                clk_out <= 0;
            // When count reaches 9, reset the counter and set the output pulse.
            if (val == 9) begin
                val <= 0;
                clk_out <= 1;
            end
        end
    end
endmodule

// -------------------------------------------------------------
// Module: reaction_mode_1
// Description: Implements reaction game mode 1, managing game logic,
//              score tracking, LED outputs, and toggle behavior.
// -------------------------------------------------------------
module reaction_mode_1 (
    // Active signal: game mode enabled when high.
    input active,
    // Trigger input for game reaction.
    input trigger,
    // 24-bit counter value used to measure reaction time.
    input [23:0] counter_val,
    // 50 MHz clock input.
    input clk50,
    // 1 kHz clock input.
    input clk1k,
    // Toggle output that changes state with valid triggers.
    output reg toggle_out,
    // Flag output indicating completion of timing (reaction done).
    output reg done_flag,
    // 10-bit LED output to display game status.
    output reg [9:0] leds,
    // 24-bit output holding the best (high) score.
    output [23:0] score
);
    // Internal wire to hold random value from LFSR generator.
    wire [11:0] rand_val;
    // Wire for the done signal from the down counter.
    wire done;
    // Register to hold previous trigger state for edge detection.
    reg prev_trigger;

    // Instantiate LFSR generator using clk50.
    lfsr_gen rand_gen(clk50, rand_val);
    // Instantiate a down counter that loads the random value; it counts down on clk1k.
    // Notice the load is driven by the inverse of the trigger signal.
    down_counter dcnt(rand_val, ~trigger, clk1k, done);
    // Instantiate the high score module to capture the best reaction time.
    high_score hs(toggle_out, counter_val, score);

    // On each rising edge of the 50 MHz clock,
    always @(posedge clk50) begin
        // Store the current trigger state in prev_trigger for edge detection.
        prev_trigger <= trigger;
        // If the game is not active, reset toggle_out.
        if (!active)
            toggle_out <= 0;
        // If a rising edge of the trigger is detected (trigger high now, was low),
        // toggle the toggle_out signal.
        else if (trigger && !prev_trigger)
            toggle_out <= ~toggle_out;
    end

    // On every rising edge of clk50, update the done_flag and LED outputs.
    always @(posedge clk50)
        if (active) begin
            // Set done_flag if toggle_out is active and the counter has completed.
            done_flag <= toggle_out & done;
            // Drive all 10 LEDs with the same value (all on if done_flag is true).
            leds <= {10{toggle_out & done}};
        end else begin
            // When inactive, clear done_flag and turn off LEDs.
            done_flag <= 0;
            leds <= 0;
        end
endmodule

// -------------------------------------------------------------
// Module: reaction_mode_2
// Description: Implements reaction game mode 2 for multiplayer mode.
//              It uses random LED selection, switch-to-LED matching,
//              FSM control, and score tracking for each player.
// -------------------------------------------------------------
module reaction_mode_2 (
    // Active signal: game mode enabled when high.
    input active,
    // Trigger input for reaction.
    input trigger,
    // 24-bit counter value used for reaction timing.
    input [23:0] counter_val,
    // 8-bit switch input, representing player inputs.
    input [7:0] sw_in,
    // 50 MHz clock input.
    input clk50,
    // 1 kHz clock input.
    input clk1k,
    // 24-bit output for the best score.
    output [23:0] score,
    // 10-bit LED output for game indication.
    output [9:0] leds,
    // Flag indicating the game mode is done.
    output reg done_flag,
    // 7-segment display output for the left hex digit.
    output reg [6:0] hex5_seg,
    // 7-segment display output for the right hex digit.
    output reg [6:0] hex4_seg,
    // Output indicating which player was best.
    output reg best_player_out,
    // Last recorded score for player 1.
    output reg [23:0] last_p1_score,
    // Last recorded score for player 2.
    output reg [23:0] last_p2_score,
    // Best score overall in multiplayer mode.
    output reg [23:0] best_multiplayer_score,
    // Indicates which player achieved the best multiplayer score.
    output reg best_multiplayer_player
);
    // Internal wire for result of switch-to-LED match.
    wire match_sig;
    // Internal wire from FSM output.
    wire z_out;
    // Internal wire from the down counter indicating timer done.
    wire done_timer;
    // 12-bit wire holding random bits from the LFSR.
    wire [11:0] rand_bits;
    // Register for the LED pattern selected for the game.
    reg [7:0] selected_led;
    // Buffer registers for trigger and match signals.
    reg trig_buf, match_buf;
    // Register to hold previous trigger state for edge detection.
    reg prev_trigger;
    // Register to toggle between players.
    reg player_toggle;

    // Generate random bits from the LFSR using the 50 MHz clock.
    lfsr_gen rand_gen(clk50, rand_bits);
    // Instantiate a down counter with a constant load value (1500) for a timer.
    // The load control is provided by trig_buf.
    down_counter dcnt(12'd1500, trig_buf, clk1k, done_timer);
    // Compare the switch input directly to the selected LED pattern.
    sw_led_match cmp(clk50, sw_in, selected_led, match_sig);
    // FSM to update z_out based on the trigger buffer and match buffer.
    fsm_z_control fsm(trig_buf, clk50, match_buf, z_out);

    // Generate a guaranteed valid LED index (0–6)
    wire [2:0] safe_rand_index = rand_bits[2:0] % 7;

    // One-hot encoded LED output based on safe_rand_index using case block
    reg [7:0] safe_selected_led;
    always @(*) begin
        case (safe_rand_index)
            3'd0: safe_selected_led = 8'b00000001;
            3'd1: safe_selected_led = 8'b00000010;
            3'd2: safe_selected_led = 8'b00000100;
            3'd3: safe_selected_led = 8'b00001000;
            3'd4: safe_selected_led = 8'b00010000;
            3'd5: safe_selected_led = 8'b00100000;
            3'd6: safe_selected_led = 8'b01000000;
            default: safe_selected_led = 8'b00000001; // Fallback to valid LED
        endcase
    end

    // At each clk50 rising edge, update the selected LED pattern if the game is not done.
    always @(posedge clk50)
        if (!done_flag)
            selected_led <= safe_selected_led;

    // On each clk50 rising edge, detect rising edges on trigger and toggle player selection.
    always @(posedge clk50) begin
        prev_trigger <= trigger;
        // If active and a new trigger edge is detected, toggle the player.
        if (active && trigger && !prev_trigger)
            player_toggle <= ~player_toggle;
    end

    // Synchronize trigger and match signals and update done_flag.
    always @(posedge clk50) begin
        if (active) begin
            // Buffer the trigger signal.
            trig_buf <= trigger;
            // Buffer the match result.
            match_buf <= match_sig;
            // Set done_flag when both the timer is done and FSM output is asserted.
            done_flag <= done_timer && z_out;
        end else begin
            // When inactive, reset buffers and clear done_flag.
            trig_buf <= 0;
            match_buf <= 1;
            done_flag <= 0;
        end
    end

    // Capture the high score using the high_score module.
    high_score hs(done_flag, counter_val, score);

    // On the falling edge of done_flag, record scores for the players.
    always @(negedge done_flag) begin
        // Only record if the counter value is nonzero.
        if (counter_val != 0) begin
            // Record score for the active player based on player_toggle.
            if (player_toggle == 0)
                last_p1_score <= counter_val;
            else
                last_p2_score <= counter_val;

            // If the new score is better (lower) than the stored high score, update best_player_out.
            if ((score == 0 || counter_val < score))
                best_player_out <= player_toggle;

            // Update the best multiplayer score if the new score is better.
            if ((best_multiplayer_score == 0 || counter_val < best_multiplayer_score)) begin
                best_multiplayer_score <= counter_val;
                best_multiplayer_player <= player_toggle;
            end
        end
    end

    // Drive the 10-bit LED output: upper 2 bits are zeros; lower 8 bits show selected_led if done_flag is high.
    assign leds = {2'b00, done_flag ? selected_led : 8'b0};

    // Combinational logic for 7-segment display outputs.
    always @(*) begin
        if (active) begin
            // Display a fixed pattern 'P' on the left digit.
            hex5_seg = 7'b0001100; // Represents letter 'P'.
            // Display 1 or 2 on the right digit based on player_toggle.
            hex4_seg = (player_toggle == 0) ? 7'b1111001 : 7'b0100100; // 1 or 2.
        end else begin
            // When inactive, turn off both 7-segment displays.
            hex5_seg = 7'b1111111;
            hex4_seg = 7'b1111111;
        end
    end
endmodule

// -------------------------------------------------------------
// Module: reflex_rush_top
// Description: Top-level module integrating all components to build the
//              Reflex Rush game. It selects game modes, handles inputs,
//              clocks, score displays, and LED outputs.
// -------------------------------------------------------------
module reflex_rush_top (
    // Two-bit key input (e.g., push buttons).
    input [1:0] key,
    // 10-bit switch input (e.g., DIP switches).
    input [9:0] sw,
    // 50 MHz system clock.
    input clk50M,
    // 42-bit output for seven-segment displays (multiple digits combined).
    output [41:0] ss,
    // Output d, likely a dedicated display control signal.
    output d,
    // 10-bit LED output.
    output [9:0] led,
	 
	 // VGA Outputs (12-bit color)
    output [3:0] vga_red,
    output [3:0] vga_green,
    output [3:0] vga_blue,
    output vga_hsync,
    output vga_vsync
);
    // Wires for internal clock and counter signals.
    wire clk1k, clk25, c0, c1, c2, c3, c4, c5;
    // Wires for flags from the two reaction modes.
    wire a1_flag, a2_flag, a_combined, b_toggle;
    // Wires for high scores from the two reaction modes and final score.
    wire [23:0] hs1, hs2, hs_final, count_out, muxed_count;
    // Wires for storing last scores for player 1 and player 2.
    wire [23:0] last_p1_score, last_p2_score;
    // Wire for the best multiplayer score.
    wire [23:0] best_multiplayer_score;
    // Wire to indicate which player achieved the best score.
    wire best_multiplayer_player;
    // Wires for individual LED outputs from each mode.
    wire [9:0] led1, led2;
    // Wires for rising edge detection.
    wire edge1, edge2;
    // Wires for 7-segment display outputs from reaction mode 2.
    wire [6:0] hex5, hex4;
    // Wire for selecting best player (unused directly in further logic).
    wire best_player_mux;
    // Registers for final 7-segment display digits.
    reg [6:0] hex5_final, hex4_final;
    // Register for final reset signal.
    reg rst_final;
	 
	 reg hold_active; // State tracker for hold screen

    // Instantiate clock divider: divide 50 MHz clock down to 1 kHz.
    clock_div_50_to_1k div(clk50M, clk1k);
	 
	 // Clock divider for 50 input
	 clock_div_50_to_25 div25(clk50M, clk25);
	 
	 // ---------------------------------------------------------
    // VGA Display Setup
    // ---------------------------------------------------------
    wire [9:0] x, y;              // Current VGA pixel position
    wire hsync, vsync, valid;     // VGA sync and valid signals
    reg [1:0] image_sel;          // Image select: 1 = hold, 2 = go
    wire [11:0] pixel_index;      // Index into image ROM
    wire [7:0] pixel_color;       // Pixel color from image ROM
    reg [7:0] safe_pixel_color;   // Black if not in image area

    // Display image in 64x48 pixels, scaled by 5x → 320x240
    parameter X_OFFSET = 160;  // Centered horizontally
    parameter Y_OFFSET = 120;  // Centered vertically

    wire in_image_area = (x >= X_OFFSET && x < X_OFFSET + 320) &&
                         (y >= Y_OFFSET && y < Y_OFFSET + 240);

    wire [5:0] img_x = (x - X_OFFSET) / 5;
    wire [5:0] img_y = (y - Y_OFFSET) / 5;
    assign pixel_index = img_y * 64 + img_x;

    // VGA timing generator
    vga_controller vga_inst(
        .clk25(clk25),
        .x(x),
        .y(y),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid)
    );

    // Image ROM for VGA
    image_rom images (
        .pixel_index(pixel_index),
        .image_sel(image_sel),
        .pixel_color(pixel_color)
    );

    // Assign black color if outside image area
    always @(*) begin
        safe_pixel_color = in_image_area ? pixel_color : 8'h00;
    end

    // VGA output assignments
    assign vga_red   = valid ? {safe_pixel_color[7:6], safe_pixel_color[7:6]}   : 4'b0000;
    assign vga_green = valid ? {safe_pixel_color[4:3], safe_pixel_color[4:3]}   : 4'b0000;
    assign vga_blue  = valid ? {safe_pixel_color[1:0], safe_pixel_color[1:0]}   : 4'b0000;
    assign vga_hsync = hsync;
    assign vga_vsync = vsync;

    // Instantiate Reaction Mode 1:
    //   - Active when sw[9] is low (using inversion ~sw[9]).
    //   - Trigger from key[0].
    //   - Uses count_out for reaction timing.
    //   - Provides toggle output, done flag, LED display, and high score hs1.
    reaction_mode_1 mode1(
        ~sw[9], key[0], count_out,
        clk50M, clk1k,
        b_toggle, a1_flag, led1, hs1
    );

    // Instantiate Reaction Mode 2:
    //   - Active when sw[9] is high.
    //   - Trigger from inverted key[1].
    //   - Uses count_out for reaction timing and sw[7:0] for switch input.
    //   - Provides high score hs2, LED display, done flag, hex display outputs,
    //     best player outputs, and last scores.
    reaction_mode_2 mode2(
        sw[9], ~key[1], count_out, sw[7:0],
        clk50M, clk1k,
        hs2, led2, a2_flag,
        hex5, hex4,
        best_player_mux,
        last_p1_score, last_p2_score,
        best_multiplayer_score,
        best_multiplayer_player
    );

    // Instantiate rising edge detectors for sw[9] and its inversion.
    rising_edge_detect redge1(sw[9], clk1k, edge1);
    rising_edge_detect redge2(~sw[9], clk1k, edge2);

    // Instantiate six modulo counters (ctr0 to ctr5) in series to build a 24-bit counter.
    // Each counter drives the next stage, and the outputs combine to form count_out.
    counter_mod ctr0(rst_final, a_combined, clk1k, c0, count_out[3:0]);
    counter_mod ctr1(rst_final, a_combined, c0, c1, count_out[7:4]);
    counter_mod ctr2(rst_final, a_combined, c1, c2, count_out[11:8]);
    counter_mod ctr3(rst_final, a_combined, c2, c3, count_out[15:12]);
    counter_mod ctr4(rst_final, a_combined, c3, c4, count_out[19:16]);
    counter_mod ctr5(rst_final, a_combined, c4, c5, count_out[23:20]);

    // Use a 24-bit multiplexer to choose between the two high scores based on sw[9].
    mux_24 mux_final(hs1, hs2, sw[9], hs_final);

    // Determine which score to display:
    //   - If sw[7] and sw[9] are high: show best multiplayer score.
    //   - Else if sw[8] is high and sw[9] is low: show Reaction Mode 1 high score.
    //   - Otherwise, show the current count.
    wire [23:0] shown_score =
        (sw[7] && sw[9])     ? best_multiplayer_score :
        (sw[8] && ~sw[9])    ? hs1 :
                               count_out;

    // Create wires to indicate if the display should show best multiplayer or single scores.
    wire show_multiplayer_best = sw[7] && sw[9];
    wire show_single_best      = sw[8] && ~sw[9];

    // Use six 4-bit multiplexers to choose between the raw counter output and the shown_score.
    mux_4 m0(count_out[3:0], shown_score[3:0], sw[7] | sw[8], muxed_count[3:0]);
    mux_4 m1(count_out[7:4], shown_score[7:4], sw[7] | sw[8], muxed_count[7:4]);
    mux_4 m2(count_out[11:8], shown_score[11:8], sw[7] | sw[8], muxed_count[11:8]);
    mux_4 m3(count_out[15:12], shown_score[15:12], sw[7] | sw[8], muxed_count[15:12]);
    mux_4 m4(count_out[19:16], shown_score[19:16], sw[7] | sw[8], muxed_count[19:16]);
    mux_4 m5(count_out[23:20], shown_score[23:20], sw[7] | sw[8], muxed_count[23:20]);

    // Instantiate 7-segment decoders to drive four digit displays using muxed_count.
    hex_decoder hd0(muxed_count[3:0], ss[6:0]);
    hex_decoder hd1(muxed_count[7:4], ss[13:7]);
    hex_decoder hd2(muxed_count[11:8], ss[20:14]);
    hex_decoder hd3(muxed_count[15:12], ss[27:21]);

    // Combinational logic to select final 7-segment digits based on score display mode.
    always @(*) begin
        if (show_multiplayer_best) begin
            // When showing multiplayer best, display a 'P' on the left and player number on the right.
            hex5_final = 7'b0001100; // Represents 'P'.
            hex4_final = best_multiplayer_player ? 7'b0100100 : 7'b1111001; // Display 2 if true, else 1.
        end else if (show_single_best) begin
            // When showing single best, blank both digits.
            hex5_final = 7'b1111111;
            hex4_final = 7'b1111111;
        end else begin
            // Otherwise, pass through the hex display outputs from Reaction Mode 2.
            hex5_final = hex5;
            hex4_final = hex4;
        end
    end

    // Assign the final 7-segment display outputs into the combined output bus.
    assign ss[34:28] = hex4_final;
    assign ss[41:35] = hex5_final;
    // Combine the done flags from both reaction modes.
    assign a_combined = a1_flag | a2_flag;
    // Combine the LED outputs from both modes.
    assign led = led1 | led2;
    // Drive the dedicated display control output to 0.
    assign d = 0;

    // Update the final reset signal based on several conditions:
    //   - When b_toggle is low, key[0] is not pressed, and sw[9] is low,
    //   - OR when a2_flag is low, key[1] is not pressed, and sw[9] is high,
    //   - OR when a rising edge is detected on sw[9] (edge1 or edge2).
    always @(posedge clk50M)
        rst_final <= (~b_toggle & ~key[0] & ~sw[9]) |
                     (~a2_flag & ~key[1] & sw[9]) |
                     edge1 | edge2;
							
	// ---------------------------------------------------------
    // Single Player HOLD Logic (controls VGA hold screen)
    // ---------------------------------------------------------
    always @(posedge clk50M) begin
        if (~sw[9]) begin
            if (~key[0] && !b_toggle && !a1_flag)
                hold_active <= 1;
            else if (a1_flag)
                hold_active <= 0;
        end else begin
            hold_active <= 0;
        end
    end

    // ---------------------------------------------------------
    // Image Select Control for VGA
    // ---------------------------------------------------------
    always @(*) begin
        if (hold_active || (!a2_flag && sw[9]))
            image_sel = 2'd1; // Show hold image
        else
            image_sel = 2'd2; // Show go image
    end
endmodule
