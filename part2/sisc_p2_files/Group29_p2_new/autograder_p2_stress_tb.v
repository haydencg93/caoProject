// ECE:3350 SISC processor project
// test bench for sisc processor, parts 2 - 4

`timescale 1ns/100ps  

// This testbench is intentionally written to "hard bind" to the same
// internal hierarchy paths used by the course autograder stress checks.
// If your design's instance/signal names differ, compilation will fail
// with "Unable to bind wire/reg/memory ..." just like the autograder.
module sisc_p2_stress_tb;

  parameter    tclk = 10.0;    
  reg          clk;
  reg          rst_f;

  // component instantiation
  // "uut" stands for "Unit Under Test"
  // sisc uut (.clk   (clk),
  //          .rst_f (rst_f),
  //          .ir    (ir));
 
  sisc uut ( clk, rst_f);

  // clock driver
  initial
  begin
    clk = 0;    
  end
	
  always
  begin
    #(tclk/2.0);
    clk = ~clk;
  end
 
  // reset control
  initial 
  begin
    rst_f = 0;
    // wait for 20 ns;
    #20; 
    rst_f = 1;
  end

  // --- Stress-check probes (autograder-style) ---
  task automatic run_stress_checks;
    reg [31:0] r1, r2, r3;
    reg [3:0]  opcode;
    begin
      // These hierarchical references must match the supplemental naming:
      // - Register file instance is uut.u2 and storage is ram_array[]
      // - Instruction register instance is uut.u9 and register is instr
      r1 = uut.u2.ram_array[1];
      r2 = uut.u2.ram_array[2];
      r3 = uut.u2.ram_array[3];
      opcode = uut.u9.instr[31:28];

      // Lightweight sanity: ensure we can see non-X values after reset
      if (^opcode === 1'bx) $display("StressCheck: opcode is X at %0t", $time);
      if (^r1 === 1'bx)     $display("StressCheck: r1 is X at %0t", $time);
      if (^r2 === 1'bx)     $display("StressCheck: r2 is X at %0t", $time);
      if (^r3 === 1'bx)     $display("StressCheck: r3 is X at %0t", $time);
    end
  endtask

  initial begin
    // Wait for reset release and a few cycles, then run checks repeatedly.
    @(posedge rst_f);
    repeat (5) @(posedge clk);
    run_stress_checks();
    repeat (25) begin
      @(posedge clk);
      run_stress_checks();
    end
  end

endmodule
