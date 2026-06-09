`timescale 1ns / 1ps

module tb_fifo();

    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [7:0] w_data;
    wire [7:0] r_data;
    wire full;
    wire empty;

    // Instantiate Unit Under Test (UUT)
    fifo #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(3) // 2^3 = 8 slots deep for quick testing
    ) uut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .w_data(w_data),
        .r_data(r_data),
        .full(full),
        .empty(empty)
    );

    // 100 MHz Clock Generator (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        w_data = 0;

        #50;
        rst = 0; // Release Reset
        #20;

        // --- TEST 1: Write 3 items into FIFO ---
        $display("[TB] Writing data: 8'hAA, 8'hBB, 8'hCC...");
        write_fifo(8'hAA);
        write_fifo(8'hBB);
        write_fifo(8'hCC);
        
        #40;

        // --- TEST 2: Read 3 items back out (Should match order!) ---
        $display("[TB] Reading data back out...");
        read_fifo();
        read_fifo();
        read_fifo();

        #50;
        
        // --- TEST 3: Fill the FIFO completely to trigger 'full' flag ---
        $display("[TB] Filling FIFO to max capacity...");
        write_fifo(8'h01);
        write_fifo(8'h02);
        write_fifo(8'h03);
        write_fifo(8'h04);
        write_fifo(8'h05);
        write_fifo(8'h06);
        write_fifo(8'h07);
        write_fifo(8'h08); // 8th element should toggle full high
        
        #40;
        if (full) $display("[SUCCESS] FIFO successfully flagged FULL!");
        
        $finish;
    end

    // Custom Tasks for clean stimulus generation
    task write_fifo(input [7:0] data);
        begin
            @(posedge clk);
            w_data = data;
            wr_en = 1;
            @(posedge clk);
            wr_en = 0;
        end
    endtask

    task read_fifo();
        begin
            @(posedge clk);
            rd_en = 1;
            @(posedge clk);
            $display("[READ OUT] Extracted Data: %h", r_data);
            rd_en = 0;
        end
    endtask

endmodule