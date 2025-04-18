// CONTROLLER.v (Verilog version converted from VHDL)

module CONTROLLER (
    input  wire        i_Clk,
    input  wire        i_Reset,
    input  wire        i_Send_Trigger,

    // SPI ADC Inputs
    input  wire        i_BUSY,
    input  wire        i_DOUTA_1,
    input  wire        i_DOUTA_2,

    // Encoder Inputs
    input  wire        i_EncoderA,
    input  wire        i_EncoderB,

    // SPI Outputs
    output wire        o_CONVST,
    output wire [1:0]  o_CS,
    output wire        o_SCLK,

    // UART Serial Output
    output wire        o_Tx_Serial,

    // Debug
    output reg  [2:0]  o_Debug_State
);

// Internal signals
reg        adc_start       = 0;
wire       adc_done;
wire [127:0] adc_data1;
wire [127:0] adc_data2;
wire [15:0]  encoder_data;
reg  [271:0] buffer_34B;

reg  [5:0]   byte_index      = 0;
reg  [2:0]   uart_bit_index  = 0;
reg  [15:0]  uart_clk_count  = 0;

reg  [7:0]   tx_byte;
reg          r_Tx_Serial     = 1;

reg          prev_trigger    = 0;
reg          rising_edge_trig = 0;

parameter c_CLKS_PER_BIT = 10;

// FSM states
localparam IDLE         = 3'd0,
           DATA_CAPTURE = 3'd1,
           LOAD_BYTE    = 3'd2,
           START_BIT    = 3'd3,
           DATA_BITS    = 3'd4,
           STOP_BIT1    = 3'd5,
           STOP_BIT2    = 3'd6,
           NEXT_BYTE    = 3'd7;

reg [2:0] state = IDLE;

// SPI_Control component
SPI_Control spi_ctrl_inst (
    .i_Clk(i_Clk),
    .i_Reset(i_Reset),
    .i_START(adc_start),
    .i_BUSY(i_BUSY),
    .i_DOUTA_1(i_DOUTA_1),
    .i_DOUTA_2(i_DOUTA_2),
    .o_SCLK(o_SCLK),
    .o_CONVST(o_CONVST),
    .o_CS(o_CS),
    .o_Data1(adc_data1),
    .o_Data2(adc_data2),
    .o_Done(adc_done)
);

// Shaft_Encoder component
Shaft_Encoder shaft_enc_inst (
    .i_Clk(i_Clk),
    .i_Reset(i_Reset),
    .Channel_A(i_EncoderA),
    .Channel_B(i_EncoderB),
    .o_Pulse_Count(encoder_data)
);

// Rising edge detection
always @(posedge i_Clk) begin
    prev_trigger <= i_Send_Trigger;
    rising_edge_trig <= i_Send_Trigger & ~prev_trigger;
end

// FSM
always @(posedge i_Clk) begin
    if (i_Reset) begin
        state <= IDLE;
        byte_index <= 0;
        uart_bit_index <= 0;
        uart_clk_count <= 0;
        r_Tx_Serial <= 1;
        adc_start <= 0;
    end else begin
        case (state)
            IDLE: begin
                r_Tx_Serial <= 1;
                byte_index <= 0;
                if (rising_edge_trig) begin
                    adc_start <= 1;
                    state <= DATA_CAPTURE;
                end
            end

            DATA_CAPTURE: begin
                adc_start <= 0;
                if (adc_done) begin
                    buffer_34B <= {adc_data1, adc_data2, encoder_data};
                    state <= LOAD_BYTE;
                end
            end

            LOAD_BYTE: begin
                tx_byte <= buffer_34B[271 - byte_index*8 -: 8];
                uart_clk_count <= 0;
                uart_bit_index <= 0;
                state <= START_BIT;
            end

            START_BIT: begin
                r_Tx_Serial <= 0;
                if (uart_clk_count == c_CLKS_PER_BIT - 1) begin
                    uart_clk_count <= 0;
                    state <= DATA_BITS;
                end else begin
                    uart_clk_count <= uart_clk_count + 1;
                end
            end

            DATA_BITS: begin
                r_Tx_Serial <= tx_byte[uart_bit_index];
                if (uart_clk_count == c_CLKS_PER_BIT - 1) begin
                    uart_clk_count <= 0;
                    if (uart_bit_index < 7)
                        uart_bit_index <= uart_bit_index + 1;
                    else
                        state <= STOP_BIT1;
                end else begin
                    uart_clk_count <= uart_clk_count + 1;
                end
            end

            STOP_BIT1: begin
                r_Tx_Serial <= 1;
                if (uart_clk_count == c_CLKS_PER_BIT - 1) begin
                    uart_clk_count <= 0;
                    state <= STOP_BIT2;
                end else begin
                    uart_clk_count <= uart_clk_count + 1;
                end
            end

            STOP_BIT2: begin
                r_Tx_Serial <= 1;
                if (uart_clk_count == c_CLKS_PER_BIT - 1) begin
                    uart_clk_count <= 0;
                    state <= NEXT_BYTE;
                end else begin
                    uart_clk_count <= uart_clk_count + 1;
                end
            end

            NEXT_BYTE: begin
                if (byte_index < 33) begin
                    byte_index <= byte_index + 1;
                    state <= LOAD_BYTE;
                end else begin
                    state <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

assign o_Tx_Serial = r_Tx_Serial;

// FSM debug output
always @(*) begin
    case (state)
        IDLE:         o_Debug_State = 3'b000;
        DATA_CAPTURE: o_Debug_State = 3'b001;
        LOAD_BYTE:    o_Debug_State = 3'b010;
        START_BIT:    o_Debug_State = 3'b011;
        DATA_BITS:    o_Debug_State = 3'b100;
        STOP_BIT1:    o_Debug_State = 3'b101;
        STOP_BIT2:    o_Debug_State = 3'b110;
        NEXT_BYTE:    o_Debug_State = 3'b111;
        default:      o_Debug_State = 3'b000;
    endcase
end

endmodule
