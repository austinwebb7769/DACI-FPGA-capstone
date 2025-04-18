// SPI_Control.v (translated from VHDL to Verilog)

module SPI_Control (
    input wire        i_Clk,
    input wire        i_Reset,
    input wire        i_START,

    input wire        i_BUSY,
    input wire        i_DOUTA_1,
    input wire        i_DOUTA_2,

    output reg        o_SCLK,
    output reg        o_CONVST,
    output reg [1:0]  o_CS,

    output reg [127:0] o_Data1,
    output reg [127:0] o_Data2,
    output reg        o_Done
);

    typedef enum logic [2:0] {
        IDLE,
        CONVERT_START,
        WAIT_BUSY_HIGH,
        WAIT_BUSY_LOW,
        READ_ADC1,
        READ_ADC2,
        DONE
    } t_State;

    t_State r_State = IDLE;

    reg r_SCLK_prev = 0;
    reg [2:0] clk_div = 0;
    parameter CLK_DIV_MAX = 4;
    reg [6:0] bit_index = 0; // 0 to 127
    reg sclk_enable = 0;

    always @(posedge i_Clk) begin
        if (sclk_enable) begin
            if (clk_div == CLK_DIV_MAX) begin
                o_SCLK <= ~o_SCLK;
                clk_div <= 0;
            end else begin
                clk_div <= clk_div + 1;
            end
        end else begin
            o_SCLK <= 0;
            clk_div <= 0;
        end
    end

    always @(posedge i_Clk) begin
        r_SCLK_prev <= o_SCLK;

        if (i_Reset) begin
            r_State     <= IDLE;
            o_CONVST    <= 1;
            o_CS        <= 2'b11;
            o_Done      <= 0;
            sclk_enable <= 0;
            bit_index   <= 0;
            o_Data1     <= 0;
            o_Data2     <= 0;
            r_SCLK_prev <= 0;
        end else begin
            case (r_State)
                IDLE: begin
                    o_Done <= 0;
                    if (i_START) begin
                        o_CONVST <= 0;
                        r_State <= CONVERT_START;
                    end
                end

                CONVERT_START: begin
                    o_CONVST <= 1;
                    if (i_BUSY)
                        r_State <= WAIT_BUSY_LOW;
                    else
                        r_State <= WAIT_BUSY_HIGH;
                end

                WAIT_BUSY_HIGH: begin
                    if (i_BUSY)
                        r_State <= WAIT_BUSY_LOW;
                end

                WAIT_BUSY_LOW: begin
                    if (!i_BUSY) begin
                        o_CS <= 2'b10; // ADC1 selected
                        bit_index <= 0;
                        sclk_enable <= 1;
                        r_State <= READ_ADC1;
                    end
                end

                READ_ADC1: begin
                    if (o_SCLK && !r_SCLK_prev) begin
                        o_Data1[127 - bit_index] <= i_DOUTA_1;
                        if (bit_index == 127) begin
                            o_CS <= 2'b01; // ADC2 selected
                            bit_index <= 0;
                            r_State <= READ_ADC2;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end

                READ_ADC2: begin
                    if (o_SCLK && !r_SCLK_prev) begin
                        o_Data2[127 - bit_index] <= i_DOUTA_2;
                        if (bit_index == 127) begin
                            sclk_enable <= 0;
                            o_CS <= 2'b11;
                            r_State <= DONE;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end

                DONE: begin
                    o_Done <= 1;
                    r_State <= IDLE;
                end

                default: begin
                    r_State <= IDLE;
                end
            endcase
        end
    end

endmodule
