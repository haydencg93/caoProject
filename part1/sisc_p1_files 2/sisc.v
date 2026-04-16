`timescale 1ns/100ps  

module sisc_p1 (clk, rst_f, ir);
  input clk, rst_f;
  input [31:0] ir;

  wire [3:0] alu_op, stat_out, alu_stat_out, alu_stat_enable;
  wire rf_we, wb_sel;      
  wire [31:0] rsa, rsb, alu_result, write_data; 

  ctrl_p1 ctrl_unit (.clk(clk), .rst_f(rst_f), .opcode(ir[31:28]), .mm(ir[27:24]), 
                  .stat(stat_out), .rf_we(rf_we), .alu_op(alu_op), .wb_sel(wb_sel));

  rf_p1 rf_unit (.clk(clk), .read_rega(ir[19:16]), .read_regb(ir[15:12]), 
              .write_reg(ir[23:20]), .write_data(write_data), .rf_we(rf_we), 
              .rsa(rsa), .rsb(rsb));

  alu_p1 alu_unit (.clk(clk), .rsa(rsa), .rsb(rsb), .imm(ir[15:0]), .alu_op(alu_op), 
                .funct(ir[27:24]), .c_in(stat_out[3]), .alu_result(alu_result), 
                .stat(alu_stat_out), .stat_en(alu_stat_enable));

  mux32_p1 wb_mux (.in_a(alu_result), .in_b(32'h0), .sel(wb_sel), .out(write_data));

  statreg_p1 stat_unit (.clk(clk), .in(alu_stat_out), .enable(alu_stat_enable), .out(stat_out));
  
  initial begin
    $display("Time | IR | R1 | R2 | R3 | R4 | R5 | OP | WB | WE | WriteData");
    $monitor("%dns | %h | %h | %h | %h | %h | %h | %b | %b | %b | %h", 
              $time, ir, 
              rf_unit.ram_array[1], rf_unit.ram_array[2], 
              rf_unit.ram_array[3], rf_unit.ram_array[4], 
              rf_unit.ram_array[5], 
              alu_op, wb_sel, rf_we, write_data);
  end
endmodule