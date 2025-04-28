

`default_nettype none

module tt_um_factory_test (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    reg rst_n_i;
    reg [7:0] cnt;
    reg [7:0] medications [0:15];  // Example medication storage (8-bit values)
    reg [3:0] med_pointer;         // Medication pointer
    reg medication_due;            // Flag for medication due
    reg [7:0] log_memory [0:15];   // Log memory for medication events
    reg [3:0] log_pointer;         // Log pointer

    // Reset synchronization
    always @(posedge clk or negedge rst_n)
        if (~rst_n) rst_n_i <= 1'b0;
        else rst_n_i <= 1'b1;

    // Counter logic
    always @(posedge clk or negedge rst_n_i)
        if (~rst_n_i) cnt <= 0;
        else cnt <= cnt + 1;

    // Medication scheduler and logger
    always @(posedge clk or negedge rst_n_i) begin
        if (~rst_n_i) begin
            med_pointer <= 0;
            medication_due <= 0;
            log_pointer <= 0;
        end else if (ena) begin
            if (!medication_due && cnt == medications[med_pointer]) begin
                medication_due <= 1'b1;
            end

            // Handle adding medication
            if (ui_in[7:4] == 4'b0001) begin
                medications[med_pointer] <= {4'b0000, ui_in[3:0]}; // Add new medication
                med_pointer <= (med_pointer == 15) ? 0 : med_pointer + 1;
            end

            // Handle medication taken acknowledgement
            if (ui_in[7:4] == 4'b0010) begin
                medication_due <= 1'b0;
            end

            // Log the medication due event
            if (medication_due) begin
                log_memory[log_pointer] <= cnt;
                log_pointer <= (log_pointer == 15) ? 0 : log_pointer + 1;
            end
        end
    end

    // Output assignments
    assign uo_out  = (~rst_n) ? ui_in : (ui_in[0] ? cnt : uio_in);
    assign uio_out = (ui_in[0] ? cnt : 8'h00);
    assign uio_oe  = rst_n && ui_in[0] ? 8'hFF : 8'h00;

    // Avoid linter warning about unused pins
    wire _unused_pins = ena;

endmodule  // tt_um_factory_test
