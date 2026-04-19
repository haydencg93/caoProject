// ============================================================================
// ECE:3350 SISC Processor - Part 2 Self-Test
// ============================================================================
//
// Tests Parts 1 + 2 (arithmetic/logic + branches) using imem_p2_test.data.
// Does NOT reference data memory — safe for Part 2 designs that haven't
// added dm, mux4, or mux16 yet.
//
// SETUP:
//   Copy imem_p2_test.data to imem.data before running:
//     cp imem_p2_test.data imem.data
//
// RUNNING (ModelSim):
//   source run_selftest_p2.tcl
//   run_main_test
//
// RUNNING (Icarus Verilog):
//   iverilog -g2005 -o test autograder_p2_tb.v sisc.v ctrl.v rf.v alu.v \
//            mux32.v statreg.v br.v im.v ir.v pc.v
//   vvp test
//
// ============================================================================

`timescale 1ns/100ps

module sisc_p2_autograder_tb;

  parameter TCLK = 10.0;
  reg clk, rst_f;
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
    $display("");
    $display("============================================================");
    $display("  TIMEOUT: Simulation exceeded 100us without reaching HLT.");
    $display("  Your processor is likely stuck. Common causes:");
    $display("    - pc_write or ir_load not asserted in fetch state");
    $display("    - FSM not transitioning correctly");
    $display("    - Branch logic creating an infinite loop");
    $display("============================================================");
    $finish;
  end

  reg checking_done;
  initial checking_done = 0;

  always @(uut.u9.instr) begin
    if (!checking_done && uut.u9.instr[31:28] == 4'hF && $time > 100) begin
      checking_done = 1;
      #1;
      run_all_checks;
    end
  end

  task check_val;
    input [255:0] name;
    input [31:0]  actual;
    input [31:0]  expected;
    begin
      if (actual === expected) begin
        $display("  [PASS]  %-12s = %h", name, actual);
        pass_count = pass_count + 1;
      end else begin
        $display("  [FAIL]  %-12s = %h  (expected %h)", name, actual, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  task run_all_checks;
    begin
      pass_count = 0;
      fail_count = 0;

      $display("");
      $display("============================================================");
      $display("  ECE:3350 SISC Part 2 Self-Test Results");
      $display("============================================================");
      $display("  Simulation time: %0t", $time);
      $display("");

      // Expected final register state after Parts 1+2:
      //   R1: 00000001    R4: 00000006
      //   R2: 00000000    R5: FF000019
      //   R3: 00000000    R6-R15: 00000000

      $display("  --- Register File ---");
      check_val("R0",  uut.u2.ram_array[0],  32'h00000000);
      check_val("R1",  uut.u2.ram_array[1],  32'h00000001);
      check_val("R2",  uut.u2.ram_array[2],  32'h00000000);
      check_val("R3",  uut.u2.ram_array[3],  32'h00000000);
      check_val("R4",  uut.u2.ram_array[4],  32'h00000006);
      check_val("R5",  uut.u2.ram_array[5],  32'hFF000019);
      check_val("R6",  uut.u2.ram_array[6],  32'h00000000);
      check_val("R7",  uut.u2.ram_array[7],  32'h00000000);
      check_val("R8",  uut.u2.ram_array[8],  32'h00000000);
      check_val("R9",  uut.u2.ram_array[9],  32'h00000000);
      check_val("R10", uut.u2.ram_array[10], 32'h00000000);
      check_val("R11", uut.u2.ram_array[11], 32'h00000000);
      check_val("R12", uut.u2.ram_array[12], 32'h00000000);
      check_val("R13", uut.u2.ram_array[13], 32'h00000000);
      check_val("R14", uut.u2.ram_array[14], 32'h00000000);
      check_val("R15", uut.u2.ram_array[15], 32'h00000000);

      $display("");
      $display("============================================================");
      $display("  SCORE: %0d / %0d checks passed", pass_count, pass_count + fail_count);
      if (fail_count == 0)
        $display("  STATUS: ALL TESTS PASSED");
      else
        $display("  STATUS: %0d CHECKS FAILED - review output above", fail_count);
      $display("============================================================");

      // Diagnostics
      $display("");
      $display("  --- Diagnostic Hints ---");

      if (uut.u2.ram_array[4] === 32'h7FFFFFFF && uut.u2.ram_array[2] === 32'hFFFFFFFF) begin
        $display("  WARNING: R2/R4 still have Part 1 Section 2 values.");
        $display("    Part 1 works but branches (Part 2) are not executing.");
        $display("    Check: Does your PC advance past address 0x11?");
        $display("    Check: Are ir_load and pc_write set in the fetch state?");
      end

      if (uut.u2.ram_array[4] === 32'h00000000 && uut.u2.ram_array[1] === 32'h00000001) begin
        $display("  WARNING: R4=0 after branch section. The inner loop");
        $display("    (L2 at 0x19-0x1B) may not be executing.");
        $display("    Check: BNR logic — branch taken when (CC & STAT) == 0.");
      end

      if (uut.u2.ram_array[2] !== 32'h00000000 && uut.u2.ram_array[2] !== 32'hFFFFFFFF) begin
        $display("  NOTE: R2 = %h (not 0 or FFFFFFFF).", uut.u2.ram_array[2]);
        $display("    The outer loop (L1 at 0x16) may not be completing all iterations.");
        $display("    Check: BRR Z,+5 at 0x17 — should branch when Z=1 (R2 reached 0).");
      end

      if (uut.u2.ram_array[4] > 32'h00000006) begin
        $display("  WARNING: R4 > 6. The inner loop may be running too many times.");
        $display("    Check: BNE #0,L1 at 0x1C — unconditional branch to 0x16.");
        $display("    If BNE isn't working, the outer loop falls through to L3 early.");
      end

      $display("");
    end
  endtask

endmodule
