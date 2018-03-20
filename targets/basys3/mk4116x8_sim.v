`timescale 1ns / 1ps

module mk4116x8_sim();
    reg clk = 1'b0;
    reg [7:0] D;
    reg Wn;
    reg RASn;
    reg CASn;
    reg [7:0] A;
    wire [7:0] Q;
    MK4116x8 dut(
        .clk(clk),
        .D(D),
        .Wn(Wn),
        .RASn(RASn),
        .CASn(CASn),
        .A(A),
        .Q(Q));

    /*
    Memory runs at 2 MHz
    Clock runs at 100 MHz think
    Lets do 10 MHz for now => 100 ns period, 50 ns delays
    */
    always begin
        #50 clk = ~clk;
    end

    task delay;
        input wire xxx;
    begin
        @(posedge clk); #25;
        @(posedge clk); #25;
        @(posedge clk); #25;
    end
    endtask

    task idle;
        input wire xxx;
    begin
        D =     8'bx;
        Wn =    1'bx;
        RASn =  1'b1;
        CASn =  1'b1;
        A =     8'bx;
        delay(1'bx);
        delay(1'bx);
        delay(1'bx);
    end
    endtask

    task bus_w;
        input [15:0] A_val;
        input [7:0] D_val;
    begin
        idle(1'bx);

        A =     A_val[15:8];
        delay(1'bx);
        RASn =  1'b0;
        delay(1'bx);

        Wn =    1'b0;
        A =     A_val[7:0];
        D =     D_val;
        delay(1'bx);
        CASn =  1'b0;
        delay(1'bx);

        $display("%g W Mem[%h] <= %h", $time, A_val, D);

        //De-assert
        CASn =  1'b1;
        delay(1'bx);
        RASn =  1'b1;
        delay(1'bx);
        A =     8'hx;
        Wn =    1'bx;
    end
    endtask

    //Basically Pulse CAS w/o changing RAS
    task page_w3;
        input [7:0] R_val;

        input [7:0] C_val1;
        input [7:0] D_val1;
        input [7:0] C_val2;
        input [7:0] D_val2;
        input [7:0] C_val3;
        input [7:0] D_val3;
    begin
        idle(1'bx);

        A =     R_val;
        delay(1'bx);
        RASn =  1'b0;
        delay(1'bx);

        //Write val
        Wn =    1'b0;
        A =     C_val1;
        D =     D_val1;
        delay(1'bx);
        CASn =  1'b0;
        delay(1'bx);
        $display("%g W Mem[%h] <= %h 1/3", $time, {R_val, C_val1}, D);
        //De-assert
        CASn =  1'b1;
        delay(1'bx);

        //Write val
        Wn =    1'b0;
        A =     C_val2;
        D =     D_val2;
        delay(1'bx);
        CASn =  1'b0;
        delay(1'bx);
        $display("%g W Mem[%h] <= %h 2/3", $time, {R_val, C_val2}, D);
        //De-assert
        CASn =  1'b1;
        delay(1'bx);

        //Write val
        Wn =    1'b0;
        A =     C_val3;
        D =     D_val3;
        delay(1'bx);
        CASn =  1'b0;
        delay(1'bx);
        $display("%g W Mem[%h] <= %h 3/3", $time, {R_val, C_val3}, D);
        //De-assert
        CASn =  1'b1;
        delay(1'bx);

        //De-assert
        RASn =  1'b1;
        delay(1'bx);
        A =     8'hx;
        Wn =    1'bx;
    end
    endtask

    task bus_r;
        input [15:0] A_val;
    begin
        idle(1'bx);

        A =     A_val[15:8];
        delay(1'bx);
        RASn =  1'b0;
        delay(1'bx);

        Wn =    1'b1;
        A =     A_val[7:0];
        delay(1'bx);
        CASn =  1'b0;
        delay(1'bx);
        //FIFO cycles
        delay(1'bx);
        delay(1'bx);

        //Check value (Q)
        $display("%g R Mem[%h] => %h", $time, A_val, Q);

        //De-assert
        CASn =  1'b1;
        delay(1'bx);
        RASn =  1'b1;
        delay(1'bx);
        A =     8'hx;
        Wn =    1'bx;
    end
    endtask

    //Very basic read/write
    task test_wr;
    begin
        idle(1'bx);

        bus_w(16'hAACC, 8'h77);
        bus_r(16'hAACC);
    end
    endtask

    //Read and write two unrelated memory locations
    task test_wr2;
    begin
        idle(1'bx);

        bus_w(16'hAACC, 8'h77);
        bus_w(16'h1234, 8'h56);
        bus_r(16'hAACC);
        bus_r(16'h1234);
    end
    endtask

    //Demonstrate page write by not releasing RASn
    task test_page;
    begin
        idle(1'bx);

        /*
        bus_w(16'hAA00, 8'hFF);
        bus_w(16'hAA01, 8'hFE);
        bus_w(16'hAA02, 8'hFD);
        bus_r(16'hAA00);
        bus_r(16'hAA01);
        bus_r(16'hAA02);
        $display("");
        */

        page_w3(8'hBB,  8'h20, 8'h10,  8'h21, 8'h09,  8'h22, 8'h08);
        bus_r(16'hBB20);
        bus_r(16'hBB21);
        bus_r(16'hBB22);
    end
    endtask

    initial begin
        $display("Running");

        $display("");
        test_wr();
        $display("");
        test_wr2();
        $display("");
        test_page();
        $display("");

        $display("Done");
        $finish;
    end
endmodule

