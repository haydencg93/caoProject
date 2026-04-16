// ============================================================================
// ECE:3350 SISC Processor - Part 2 Checkpoint Self-Test
// ============================================================================
//
// Checks register values at three intermediate points:
//   Checkpoint 1: After Part 1 Section 1 (addr 0x0B)
//   Checkpoint 2: After Part 1 Section 2 (addr 0x11)
//   Checkpoint 3: After Part 2 branches  (HLT at 0x1E)
//
// This helps you identify whether Part 1 still works after your Part 2
// modifications, and whether branches are executing correctly.
//
// SETUP: Copy imem_p2_test.data to imem.data before running.
//
// ============================================================================

`timescale 1ns/100ps

module sisc_p2_checkpoint_tb;

  parameter TCLK = 10.0;
  reg clk, rst_f;
  integer total_pass, total_fail;
  integer pass_count, fail_count;

  sisc uut (.clk(clk), .rst_f(rst_f));

  initial clk = 0;
  always #(TCLK/2.0) clk = ~clk;

  initial begin
    rst_f = 0;
    #20;
    rst_f = 1;
  end

  initial begin
    #100000;
    $display("  TIMEOUT: Simulation exceeded 100us.");
    $finish;
  end

  initial begin
    total_pass = 0;
    total_fail = 0;
  end

  task check_val;
    input [255:0] name;
    input [31:0]  actual;
    input [31:0]  expected;
    begin
      if (actual === expected) begin
        $display("    [PASS]  %-8s = %h", name, actual);
        pass_count = pass_count + 1;
        total_pass = total_pass + 1;
      end else begin
        $display("    [FAIL]  %-8s = %h  (expected %h)", name, actual, expected);
        fail_count = fail_count + 1;
        total_fail = total_fail + 1;
      end
    end
  endtask

  // ---- Track checkpoints ----
  reg cp1_done, cp2_done;
  initial begin
    cp1_done = 0;
    cp2_done = 0;
  end

  // ---- Monitor for checkpoint instructions ----
  always @(posedge clk) begin

    // Checkpoint 1: After Part 1 Section 1
    // The NOP at 0x0B finishes, and 0x0C (ADI R1,R0,#1 = 0x21100001) is fetched.
    // When IR has 0x21100001 and PC has advanced to 0x000D, Section 1 is complete.
    if (!cp1_done && uut.u9.instr == 32'h21100001 && uut.u10.pc_out == 16'h000D) begin
      cp1_done = 1;
      pass_count = 0;
      fail_count = 0;
      $display("");
      $display("  ---- CHECKPOINT 1: Part 1 Section 1 (after addr 0x0B) ----");
      $display("    If these fail, your Part 1 arithmetic is broken.");
      check_val("R1", uut.u2.ram_array[1],  32'h00000001);
      check_val("R2", uut.u2.ram_array[2],  32'hFF000008);
      check_val("R3", uut.u2.ram_array[3],  32'hFE000000);
      check_val("R4", uut.u2.ram_array[4],  32'hFE000011);
      check_val("R5", uut.u2.ram_array[5],  32'hFF000019);
      $display("    Section 1 result: %0d/%0d", pass_count, pass_count + fail_count);
    end

    // Checkpoint 2: After Part 1 Section 2
    // The NOP at 0x11 finishes, and 0x12 (ADD R4,R0,R0 = 0x11400000) is fetched.
    // When IR has 0x11400000 and PC = 0x0013, Section 2 is complete.
    if (!cp2_done && uut.u9.instr == 32'h11400000 && uut.u10.pc_out == 16'h0013) begin
      cp2_done = 1;
      pass_count = 0;
      fail_count = 0;
      $display("");
      $display("  ---- CHECKPOINT 2: Part 1 Section 2 (after addr 0x11) ----");
      $display("    If these fail, check status flag handling (SUB, RTR, ADD).");
      check_val("R1", uut.u2.ram_array[1],  32'h00000001);
      check_val("R2", uut.u2.ram_array[2],  32'hFFFFFFFF);
      check_val("R3", uut.u2.ram_array[3],  32'h80000000);
      check_val("R4", uut.u2.ram_array[4],  32'h7FFFFFFF);
      check_val("R5", uut.u2.ram_array[5],  32'hFF000019);
      $display("    Section 2 result: %0d/%0d", pass_count, pass_count + fail_count);
    end
  end

  // ---- Checkpoint 3: HLT = final Part 2 state ----
  reg hlt_done;
  initial hlt_done = 0;

  always @(uut.u9.instr) begin
    if (!hlt_done && uut.u9.instr[31:28] == 4'hF && $time > 100) begin
      hlt_done = 1;
      #1;
      pass_count = 0;
      fail_count = 0;
      $display("");
      $display("  ---- CHECKPOINT 3: Part 2 Branches (HLT reached) ----");
      $display("    These test BRA, BRR, BNE, and BNR execution.");
      check_val("R1", uut.u2.ram_array[1],  32'h00000001);
      check_val("R2", uut.u2.ram_array[2],  32'h00000000);
      check_val("R3", uut.u2.ram_array[3],  32'h00000000);
      check_val("R4", uut.u2.ram_array[4],  32'h00000006);
      check_val("R5", uut.u2.ram_array[5],  32'hFF000019);
      $display("    Branches result: %0d/%0d", pass_count, pass_count + fail_count);

      // Branch-specific diagnostics
      if (uut.u2.ram_array[4] === 32'h00000000) begin
        $display("");
        $display("    HINT: R4=0 means the nested loops never ran.");
        $display("      The BRA N at 0x13 should NOT be taken (N flag is 0 after");
        $display("      ADD R4,R0,R0 sets Z=1). If it branches, check your BRA logic:");
        $display("      BRA takes the branch when (CC & STAT) != 0.");
      end

      if (uut.u2.ram_array[4] === 32'h7FFFFFFF) begin
        $display("");
        $display("    HINT: R4 still has its Part 1 value. None of the Part 2");
        $display("      instructions executed. Is your PC advancing past 0x11?");
      end

      if (uut.u2.ram_array[4] === 32'h00000003) begin
        $display("");
        $display("    HINT: R4=3 means only the first outer loop iteration ran.");
        $display("      The unconditional BNE at 0x1C may not be branching back to L1.");
        $display("      BNE with CC=0000 should ALWAYS branch (condition is always true).");
      end

      if (uut.u2.ram_array[2] === 32'h00000003) begin
        $display("");
        $display("    HINT: R2=3 means the outer loop ran once but didn't decrement again.");
        $display("      Check BNE #0,L1 at 0x1C and the loop back to ADI R2,R2,#-1 at 0x16.");
      end

      $display("");
      $display("============================================================");
      $display("  OVERALL: %0d / %0d checks passed", total_pass, total_pass + total_fail);
      if (total_fail == 0)
        $display("  STATUS: ALL CHECKPOINTS PASSED");
      else begin
        $display("  STATUS: %0d CHECKS FAILED", total_fail);
        if (total_pass >= 10)
          $display("  Part 1 is likely working. Focus on branch logic in ctrl.v decode state.");
      end
      $display("============================================================");
      $display("");
    end
  end

endmodule
