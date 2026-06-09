`timescale 1ns / 1ps

module fifo #(
    parameter DATA_WIDTH = 8,   // Each data slot is 8 bits (1 byte)
    parameter ADDR_WIDTH = 4    // 4-bit address means 2^4 = 16 slots deep
)(
    input clk,
    input rst,
    input wr_en,                // Write Enable
    input rd_en,                // Read Enable
    input [DATA_WIDTH-1:0] w_data, // Data to write into FIFO
    output [DATA_WIDTH-1:0] r_data, // Data read out of FIFO
    output full,
    output empty
);

    // 1. Define the internal Register Array (Dual-Port Memory)
    localparam DEPTH = 1 << ADDR_WIDTH; // 2^4 = 16
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // 2. Define Pointers and Status Registers
    reg [ADDR_WIDTH-1:0] w_ptr_reg, w_ptr_next;
    reg [ADDR_WIDTH-1:0] r_ptr_reg, r_ptr_next;
    reg full_reg, full_next;
    reg empty_reg, empty_next;

    // 3. Sequential Logic: Memory Write and Pointer Updates
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1; // Starts out empty
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
            
            // Write data into memory if enabled and not full
            if (wr_en && !full_reg)
                mem[w_ptr_reg] <= w_data;
        end
    end

    // 4. Combinational Logic: Next-State Logic for Pointers and Flags
    always @* begin
        // Default assignments to keep current values if nothing happens
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case ({wr_en, rd_en})
            2'b10: begin // WRITE ONLY
                if (!full_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0; // Definitely not empty anymore
                    if (w_ptr_next == r_ptr_reg) // Wrapped around to read pointer
                        full_next = 1'b1;
                end
            end
            
            2'b01: begin // READ ONLY
                if (!empty_reg) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 1'b0; // Definitely not full anymore
                    if (r_ptr_next == w_ptr_reg) // Caught up to write pointer
                        empty_next = 1'b1;
                end
            end
            
            2'b11: begin // BOTH WRITE AND READ SIMULTANEOUSLY
                if (!empty_reg && !full_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                    // Flags don't change because data size stays identical
                end else if (empty_reg) begin
                    // If empty, we can only write
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg) begin
                    // If full, we can only read
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 1'b0;
                end
            end
            
            default: ; // 2'b00: Do nothing
        endcase
    end

    // 5. Assign Continuous Outputs
    assign r_data = mem[r_ptr_reg];
    assign full   = full_reg;
    assign empty  = empty_reg;

endmodule