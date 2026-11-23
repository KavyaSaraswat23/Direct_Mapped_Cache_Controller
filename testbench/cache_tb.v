`timescale 1ns/1ps

module cache_tb;
    initial begin
        $dumpfile("simulation/cache_waveform.vcd");
        $dumpvars(0, cache_tb);
    end
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
