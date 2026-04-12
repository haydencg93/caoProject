`timescale 1ns/100ps  

module sisc (clk, rst_f);
  input clk, rst_f;

  // Control Signals
  wire [3:0] alu_op;
  wire rf_we, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load;

  // Datapath Wires
  wire [31:0] instr;
  wire [31:0] read_data;
  wire [15:0] pc_out, br_addr;
  wire [31:0] rsa, rsb, alu_result, write_data;
  wire [3:0] stat_out, alu_stat_out, alu_stat_enable;

  // --- MODULE INSTANTIATIONS ---

  alu u1 (
    .clk(clk),
    .rsa(rsa),
    .rsb(rsb),
    .imm(instr[15:0]),
    .alu_op(alu_op),
    .funct(instr[27:24]),
    .c_in(stat_out[3]),
    .alu_result(alu_result),
    .stat(alu_stat_out),
    .stat_en(alu_stat_enable)
  );

  rf u2 (
    .clk(clk),
    .read_rega(instr[19:16]),
    .read_regb(instr[15:12]),
    .write_reg(instr[23:20]),
    .write_data(write_data),
    .rf_we(rf_we),
    .rsa(rsa),
    .rsb(rsb)
  );

  statreg u3 (
    .clk(clk),
    .in(alu_stat_out),
    .enable(alu_stat_enable),
    .out(stat_out)
  );

  mux32 u4 (
    .in_a(alu_result),
    .in_b(32'h0),
    .sel(wb_sel),
    .out(write_data)
  );

  ctrl u5 (
    .clk(clk),
    .rst_f(rst_f),
    .opcode(instr[31:28]),
    .mm(instr[27:24]),
    .stat(stat_out),
    .rf_we(rf_we),
    .alu_op(alu_op),
    .wb_sel(wb_sel),
    .br_sel(br_sel),
    .pc_rst(pc_rst),
    .pc_write(pc_write),
    .pc_sel(pc_sel),
    .ir_load(ir_load)
  );

  br u7 (
    .pc_out(pc_out),
    .imm(instr[15:0]),
    .br_sel(br_sel),
    .br_addr(br_addr)
  );

  pc u8 (
    .clk(clk),
    .br_addr(br_addr),
    .pc_sel(pc_sel),
    .pc_write(pc_write),
    .pc_rst(pc_rst),
    .pc_out(pc_out)
  );

  ir u9 (
    .clk(clk),
    .ir_load(ir_load),
    .read_data(read_data),
    .instr(instr)
  );

  im u10 (
    .read_addr(pc_out),
    .read_data(read_data)
  );

  initial begin
    $display("Time | IR | PC | R1 | R2 | R3 | ALU_OP | BR_SEL | PC_WRITE | PC_SEL");
    $monitor("%dns | %h | %h | %h | %h | %h | %b | %b | %b | %b", 
              $time, instr, pc_out, 
              u2.ram_array[1], u2.ram_array[2], u2.ram_array[3], 
              alu_op, br_sel, pc_write, pc_sel);
  end
endmodule