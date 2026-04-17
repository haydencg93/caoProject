`timescale 1ns/100ps

module sisc (clk, rst_f); 

  input clk, rst_f;

  // Address wires are 16-bit; Data wires are 32-bit
  wire [31:0] ir, im_out;          
  wire [15:0] pc_out, pc_br;
  wire ir_load, pc_write, pc_rst, pc_sel, br_sel;
  
  wire rf_we, wb_sel;
  wire [3:0] alu_op, alu_sts, stat, stat_en;
  wire [31:0] rega, regb, wr_dat, alu_out;

  // u9: Instruction Register (clk, ir_load, read_data, instr)
  ir u9 (clk, ir_load, im_out, ir);

  // u8: Instruction Memory (read_addr, read_data)
  im u8 (pc_out, im_out);

  // u7: Program Counter (clk, br_addr, pc_sel, pc_write, pc_rst, pc_out)
  pc u7 (clk, pc_br, pc_sel, pc_write, pc_rst, pc_out);

  // u4: Branch Unit (pc_out, imm, br_sel, br_addr)
  br u4 (pc_out, ir[15:0], br_sel, pc_br);

  // u1: Control Unit
  ctrl u1 (clk, rst_f, ir[31:28], ir[27:24], stat, rf_we, alu_op, wb_sel, 
           br_sel, pc_rst, pc_write, pc_sel, ir_load);

  // u2: Register File
  rf u2 (clk, ir[19:16], ir[15:12], ir[23:20], wr_dat, rf_we, rega, regb);

  // u3: ALU
  alu u3 (clk, rega, regb, ir[15:0], stat[3], alu_op, ir[27:24], alu_out, alu_sts, stat_en);

  // u5 & u6: Mux and Status Register
  mux32 u5 (alu_out, 32'h00000000, wb_sel, wr_dat);
  statreg u6(clk, alu_sts, stat_en, stat);

  initial
    $monitor($time, " IR=%h PC=%h R1=%h R2=%h R3=%h ALU_OP=%h BR_SEL=%b PC_WRITE=%b PC_SEL=%b",
             ir, pc_out, u2.ram_array[1], u2.ram_array[2], u2.ram_array[3], 
             alu_op, br_sel, pc_write, pc_sel);

endmodule