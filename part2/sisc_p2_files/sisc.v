`timescale 1ns/100ps  
module sisc (clk, rst_f); 
  input clk, rst_f;
  
  // Control Signals 
  wire [3:0] alu_op;
  wire rf_we, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load;

  // Datapath Wires
  wire [31:0] instr;      
  wire [31:0] read_data;  
  wire [15:0] pc_out;     
  wire [15:0] br_addr;   
  
  wire [31:0] rsa, rsb, alu_result, write_data; 
  wire [3:0] stat_out, alu_stat_out, alu_stat_enable;

  // Program Counter:
  pc pc_unit (
    .clk(clk), 
    .br_addr(br_addr), 
    .pc_sel(pc_sel), 
    .pc_write(pc_write), 
    .pc_rst(pc_rst), 
    .pc_out(pc_out)
  );

  // Instruction Memory: 
  im im_unit (
    .read_addr(pc_out), 
    .read_data(read_data)
  );

  // Instruction Register: 
  ir ir_unit (
    .clk(clk), 
    .ir_load(ir_load), 
    .read_data(read_data), 
    .instr(instr)
  );

  // Branch Unit: 
  br br_unit (
    .pc_out(pc_out), 
    .imm(instr[15:0]), 
    .br_sel(br_sel), 
    .br_addr(br_addr)
  );

  // Control Unit: 
  ctrl ctrl_unit (
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

  // Register File: 
  rf rf_unit (
    .clk(clk), 
    .read_rega(instr[19:16]), 
    .read_regb(instr[15:12]), 
    .write_reg(instr[23:20]), 
    .write_data(write_data), 
    .rf_we(rf_we), 
    .rsa(rsa), 
    .rsb(rsb)
  );

  // ALU 
  alu alu_unit (
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

  // Mux and Status Register
  mux32 wb_mux (.in_a(alu_result), .in_b(32'h0), .sel(wb_sel), .out(write_data));
  statreg stat_unit (.clk(clk), .in(alu_stat_out), .enable(alu_stat_enable), .out(stat_out));
    
  initial begin
    $display("Time | IR | PC | R1 | R2 | R3 | OP | BS | PW | PS");
    $monitor("%dns | %h | %h | %h | %h | %h | %b | %b | %b | %b", 
              $time, instr, pc_out, 
              rf_unit.ram_array[1], rf_unit.ram_array[2], rf_unit.ram_array[3], 
              alu_op, br_sel, pc_write, pc_sel);
  end
endmodule