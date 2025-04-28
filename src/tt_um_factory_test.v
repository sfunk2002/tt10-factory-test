`default_nettype none

module tt_um_factory_test(
    parameter MEM_DEPTH = 16,
    parameter MEM_ADDR_WIDTH = 4 // log2(MEM_DEPTH)
)(
    input  wire        clk,	
    input  wire        rst_n,
    input  wire        ena,
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,
    input  wire [7:0]  uio_in,
    output wire [7:0]  uio_out,
    output wire [7:0]  uio_oe
);

    // Internal signals
    reg [7:0] medications [0:MEM_DEPTH-1];
    reg [MEM_ADDR_WIDTH-1:0] med_pointer;

    reg [7:0] internal_clock;
    reg medication_due;

    reg [7:0] log_memory [0:MEM_DEPTH-1];
    reg [MEM_ADDR_WIDTH-1:0] log_pointer;
    reg log_ready;

    reg [7:0] lcd_reg;

    integer i;

    // Command decoding
    wire [3:0] cmd  = ui_in[7:4];
    wire [3:0] data = ui_in[3:0];

    reg [7:0] last_ui_in;
    wire cmd_valid = (ui_in != last_ui_in);

    // Medication database and command handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            med_pointer <= 0;
            for (i = 0; i < MEM_DEPTH; i = i + 1)
                medications[i] <= 8'h00;
            medication_due <= 0;
            internal_clock <= 0;
            log_pointer <= 0;
            log_ready <= 0;
            for (i = 0; i < MEM_DEPTH; i = i + 1)
                log_memory[i] <= 8'h00;
            lcd_reg <= 8'h00;
            last_ui_in <= 8'h00;
        end else if (ena) begin
            last_ui_in <= ui_in; // capture ui_in every cycle

            // Increment internal clock
            if (internal_clock == 8'hFF)
                internal_clock <= 8'h00;
            else
                internal_clock <= internal_clock + 1;

            // Scheduler: check if medication is due
            if (!medication_due && internal_clock == medications[0]) begin
                medication_due <= 1'b1;
            end

            // Execute command only when ui_in changes (cmd_valid)
            if (cmd_valid) begin
                case (cmd)
                    4'b0001: begin
                        // Add medication
                        medications[med_pointer] <= {4'b0000, data}; // Extend 4 bits to 8 bits
                        med_pointer <= (med_pointer == MEM_DEPTH-1) ? 0 : med_pointer + 1;
                    end
                    4'b0010: begin
                        // Acknowledge medication taken
                        medication_due <= 1'b0;
                    end
                    4'b0011: begin
                        // Clear log memory
                        for (i = 0; i < MEM_DEPTH; i = i + 1)
                            log_memory[i] <= 8'h00;
                        log_pointer <= 0;
                    end
                    4'b0100: begin
                        // Select which log entry to view
                        if (data < MEM_DEPTH)
                            lcd_reg <= log_memory[data];
                        else
                            lcd_reg <= 8'hFF; // Error display
                    end
                    default: begin
                        // No operation
                    end
                endcase
            end

            // Logger: record medication due event
            if (medication_due && !log_ready) begin
                log_memory[log_pointer] <= internal_clock;
                log_pointer <= (log_pointer == MEM_DEPTH-1) ? 0 : log_pointer + 1;
                log_ready <= 1'b1;
            end else if (!medication_due) begin
                log_ready <= 1'b0;
            end
        end
    end

    // Output assignments
    assign uo_out = lcd_reg; // LCD output
    assign uio_out = 8'h00;  // No UIO output (reserved for future use)
    assign uio_oe  = 8'h00;  // No UIO output enable

endmodule
