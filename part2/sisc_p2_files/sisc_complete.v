// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps  

module sisc (clk, rst_f, ir);

  input clk, rst_f;
  input [31:0] ir;

  wire rf_we, wb_sel, c_in;
  wire [3:0] alu_op;
  wire [3:0] alu_sts, stat, stat_en;
  wire [31:0] rega, regb, wr_dat, alu_out;
  

// component instantiation

  ctrl u1 (clk, rst_f, ir[31:28], ir[27:24], stat, rf_we, alu_op, wb_sel);

  rf u2 (clk, ir[19:16], ir[15:12], ir[23:20], wr_dat, rf_we, rega, regb);

  alu u3 (clk, rega, regb, ir[15:0], stat[3], alu_op, ir[27:24], alu_out, alu_sts, stat_en);

  mux32 u5 (alu_out, 32'h00000000, wb_sel, wr_dat);

  statreg u6(clk, alu_sts, stat_en, stat);

  initial
  $monitor($time,,"%h  %h  %h  %h  %h  %h  %h  %b  %b  %h",ir,u2.ram_array[1],u2.ram_array[2],u2.ram_array[3],u2.ram_array[4],u2.ram_array[5],alu_op,wb_sel,rf_we,wr_dat);


endmodule


