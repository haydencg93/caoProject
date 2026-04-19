`timescale 1ns/100ps

module sisc (clk, rst_f);

  input clk, rst_f;

  // Signal Wires
  wire [31:0] ir, im_out;
  wire [15:0] pc_out, pc_br;
  wire ir_load, pc_write, pc_rst, pc_sel, br_sel;
  
  wire rf_we, wb_sel;
  wire [3:0] alu_op, alu_sts, stat, stat_en;
  wire [31:0] rega, regb, wr_dat, alu_out;

  // Module Instantiations
  ir u9 (clk, ir_load, im_out, ir);

  im u8 (pc_out, im_out);

  pc u7 (clk, pc_br, pc_sel, pc_write, pc_rst, pc_out);

  br u4 (pc_out, ir[15:0], br_sel, pc_br);

  // Use named port mapping to avoid order errors
  ctrl u1 (
    .clk(clk), 
    .rst_f(rst_f), 
    .opcode(ir[31:28]), 
    .mm(ir[27:24]), 
    .stat(stat), 
    .rf_we(rf_we), 
    .alu_op(alu_op), 
    .wb_sel(wb_sel), 
    .br_sel(br_sel), 
    .pc_rst(pc_rst), 
    .pc_write(pc_write), 
    .pc_sel(pc_sel), 
    .ir_load(ir_load)
  );

  rf u2 (clk, ir[19:16], ir[15:12], ir[23:20], wr_dat, rf_we, rega, regb);

  alu u3 (clk, rega, regb, ir[15:0], stat[3], alu_op, ir[27:24], alu_out, alu_sts, stat_en);

  mux32 u5 (alu_out, 32'h00000000, wb_sel, wr_dat);

  statreg u6 (clk, alu_sts, stat_en, stat);

  // Monitor as required by Part 2 instructions
  initial begin
    $display("Time | IR | PC | R1 | R2 | R3 | OP | BS | PW | PS | WE");
    $monitor("%t | %h | %h | %h | %h | %h | %h | %b | %b | %b | %b", 
             $time, ir, pc_out, u2.ram_array[1], u2.ram_array[2], u2.ram_array[3], 
             alu_op, br_sel, pc_write, pc_sel, rf_we);
  end

endmodule