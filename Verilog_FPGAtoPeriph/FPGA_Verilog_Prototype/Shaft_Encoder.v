// Shaft_Encoder.v

module Shaft_Encoder (
    input wire i_Clk,
    input wire i_Reset,
    input wire Channel_A,
    input wire Channel_B,
    output reg [15:0] o_Pulse_Count,
    output reg o_Data_Ready
);

    // State definitions
    typedef enum logic [0:0] {
        COUNTING = 1'b0,
        STORED   = 1'b1
    } State_Type;

    State_Type Current_State = COUNTING, Next_State = COUNTING;

    reg [15:0] pulse_count = 16'd0;
    reg [15:0] output_buffer = 16'd0;
    integer clk_count = 0;
    reg prev_A = 1'b0;

    localparam CYCLE_LIMIT = 100000; // 2ms at 50 MHz

    // Sequential logic
    always @(posedge i_Clk) begin
        if (i_Reset) begin
            Current_State  <= COUNTING;
            pulse_count    <= 16'd0;
            clk_count      <= 0;
            prev_A         <= 1'b0;
            output_buffer  <= 16'd0;
            o_Data_Ready   <= 1'b0;
        end else begin
            Current_State <= Next_State;

            // Detect rising edge on Channel_A
            if (Channel_A && !prev_A) begin
                pulse_count <= pulse_count + 1;
            end
            prev_A <= Channel_A;

            if (Current_State == COUNTING) begin
                if (clk_count < CYCLE_LIMIT)
                    clk_count <= clk_count + 1;
                o_Data_Ready <= 1'b0;
            end else if (Current_State == STORED) begin
                output_buffer <= pulse_count;
                pulse_count   <= 16'd0;
                clk_count     <= 0;
                o_Data_Ready  <= 1'b1;
            end
        end
    end

    // FSM transition logic
    always @(*) begin
        case (Current_State)
            COUNTING: begin
                if (clk_count >= CYCLE_LIMIT)
                    Next_State = STORED;
                else
                    Next_State = COUNTING;
            end
            STORED: begin
                Next_State = COUNTING;
            end
        endcase
    end

    assign o_Pulse_Count = output_buffer;

endmodule
