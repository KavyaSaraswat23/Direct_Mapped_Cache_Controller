`timescale 1ns/1ps

module cache_tb;

    // Clock and reset
    reg clk;
    reg rst;

    // CPU interface
    reg cpu_req;
    reg cpu_write;
    reg [31:0] cpu_addr;
    reg [127:0] cpu_write_data;

    wire cpu_ready;
    wire [127:0] cpu_read_data;

    // Device Under Test
    top_module dut (

        .clk(clk),
        .rst(rst),

        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_write_data(cpu_write_data),

        .cpu_ready(cpu_ready),
        .cpu_read_data(cpu_read_data)
    );

    integer memory_request_count = 0;
    integer test_failures = 0;

    // Dump waveforms for simulation
    initial begin
        $dumpfile("simulation/cache_waveform.vcd");
        $dumpvars(0, cache_tb);
    end

    // Task to report test results and count failures
    task check_test;
        input [8*40-1:0] test_name;
        input condition;

        begin
            if (condition === 1'b1) begin
                $display("%0s: PASS", test_name);
            end
            else begin
                $display("%0s: FAIL", test_name);
                test_failures = test_failures + 1;
            end
        end
    endtask

    always @(posedge clk) begin
            if (rst) begin
                memory_request_count <= 0;
            end
            else if (dut.mem_req) begin
                memory_request_count <= memory_request_count + 1;
                $display("MEMORY REQUEST DETECTED at time %0t", $time);
            end
     end

    // Monitor CPU responses
    initial begin
        $monitor(
            "Time=%0t | Reset=%b | Request=%b | Write=%b | Ready=%b | Read Data=%h",
            $time, rst, cpu_req, cpu_write, cpu_ready, cpu_read_data
        );
    end

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Initialize testbench signals
    initial begin
        rst = 1'b1;

        cpu_req = 1'b0;
        cpu_write = 1'b0;
        cpu_addr = 32'b0;
        cpu_write_data = 128'b0;

        #20;
        rst = 1'b0;
    end
    // Test 1: Read Miss
    initial begin
        wait(rst == 1'b0);

        @(negedge clk);

        cpu_addr = 32'h00000010;
        cpu_write = 1'b0;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;
        $display("READ MISS COMPLETED");
        $display("Returned Data = %h", cpu_read_data);

        check_test(
            "TEST 1 - READ MISS",
            cpu_read_data === 128'h01010101010101010101010101010101
        );

        @(negedge clk);
        cpu_req = 1'b0;

        // Test 2: Read Hit
        @(negedge clk);

        cpu_addr = 32'h00000010;
        cpu_write = 1'b0;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        $display("READ HIT COMPLETED");
        $display("Returned Data = %h", cpu_read_data);

        check_test(
            "TEST 2 - READ HIT",
            cpu_read_data === 128'h01010101010101010101010101010101
        );

        @(negedge clk);
        cpu_req = 1'b0;

        // Test 3: Write Hit
        @(negedge clk);

        cpu_addr = 32'h00000010;
        cpu_write = 1'b1;
        cpu_write_data = 128'hAABBCCDDEEFF00112233445566778899;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        $display("WRITE HIT COMPLETED");

        check_test(
            "TEST 3 - WRITE HIT",
            (memory_request_count == 2) &&
            (dut.memory.memory[8'd1] ===
            128'hAABBCCDDEEFF00112233445566778899) &&
            (dut.data_ram.data_mem[6'd1] ===
            128'hAABBCCDDEEFF00112233445566778899)
        );

        @(negedge clk);
        cpu_req = 1'b0;

        // Test 4: Read After Write
        @(negedge clk);
        cpu_addr = 32'h00000010;
        cpu_write = 1'b0;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        $display("READ AFTER WRITE COMPLETED");
        $display("Returned Data = %h", cpu_read_data);

        check_test(
            "TEST 4 - READ AFTER WRITE",
            cpu_read_data ===
            128'hAABBCCDDEEFF00112233445566778899
        );

        @(negedge clk);
        cpu_req = 1'b0;


        // Test 5: Write Miss
        @(negedge clk);

        cpu_addr = 32'h00000020;
        cpu_write = 1'b1;
        cpu_write_data = 128'h11223344556677889900AABBCCDDEEFF;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        $display("WRITE MISS COMPLETED");

        check_test(
            "TEST 5 - WRITE MISS",
            (memory_request_count == 3) &&
            (dut.memory.memory[8'd2] ===
            128'h11223344556677889900AABBCCDDEEFF) &&
            (dut.valid_ram.valid_mem[6'd2] === 1'b0)
        );

        @(negedge clk);
        cpu_req = 1'b0;

        // Test 6: Read After Write Miss
        @(negedge clk);

        cpu_addr = 32'h00000020;
        cpu_write = 1'b0;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        $display("READ AFTER WRITE MISS COMPLETED");
        $display("Returned Data = %h", cpu_read_data);

        check_test(
            "TEST 6 - READ AFTER WRITE MISS",
            cpu_read_data ===
            128'h11223344556677889900AABBCCDDEEFF
        );

        check_test(
            "NO-WRITE-ALLOCATE",
            memory_request_count == 4
        );
        @(negedge clk);
        cpu_req = 1'b0;

        // Test 7A: Read first block (should be a hit) — part of conflict test below

        // --------------------------------------
        // TEST 7: CONFLICT / REPLACEMENT
        // --------------------------------------

        // Step 1: Read first block (0x10) - should be a hit
        @(negedge clk);

        $display("CONFLICT TEST - FIRST BLOCK");

        cpu_addr = 32'h00000010;
        cpu_write = 1'b0;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        if (cpu_read_data == 128'hAABBCCDDEEFF00112233445566778899)
            $display("FIRST BLOCK: PASS");
        else
            $display("FIRST BLOCK: FAIL");

        cpu_req = 1'b0;
        wait(cpu_ready == 1'b0);
        @(negedge clk);

        // Step 2: Read conflicting block (0x410)
        // Same index, different tag - should cause a miss
        $display("CONFLICT TEST - SECOND BLOCK");

        cpu_addr = 32'h00000410;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        if (cpu_read_data == 128'h41414141414141414141414141414141)
            $display("SECOND BLOCK: PASS");
        else
            $display("SECOND BLOCK: FAIL");

        cpu_req = 1'b0;
        wait(cpu_ready == 1'b0);
        @(negedge clk);

        // Step 3: Read first block again
        // It should have been evicted and must be fetched from memory
        $display("CONFLICT TEST - FIRST BLOCK AFTER REPLACEMENT");

        cpu_addr = 32'h00000010;
        cpu_req = 1'b1;

        wait(cpu_ready == 1'b1);
        #1;

        $display("Returned Data = %h", cpu_read_data);

        if (cpu_read_data == 128'hAABBCCDDEEFF00112233445566778899)
            $display("CONFLICT TEST: PASS");
        else
            $display("CONFLICT TEST: FAIL");

        cpu_req = 1'b0;
        wait(cpu_ready == 1'b0);
        @(negedge clk);

        $display("--------------------------------");
        $display("TOTAL MEMORY REQUESTS = %0d", memory_request_count);

        check_test(
            "MEMORY REQUEST COUNT",
            memory_request_count == 6
        );

        $display("--------------------------------");

        if (test_failures == 0) begin
            $display("OVERALL RESULT: PASS");
            $display("ALL TESTS PASSED SUCCESSFULLY");
            $finish;
        end
        else begin
            $display("OVERALL RESULT: FAIL");
            $display("FAILED TESTS = %0d", test_failures);
            $fatal(1, "TESTBENCH FAILED");
        end

    end

endmodule
