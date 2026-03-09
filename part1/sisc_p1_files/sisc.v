// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps  

module sisc (clk, rst_f, ir);

  input clk, rst_f;
  input [31:0] ir;

// declare all internal wires here
  wire [3:0]  alu_op_w;
  wire        rf_we_w;
  wire        wb_sel_w;
  wire [31:0] rsa_w, rsb_w;
  wire [31:0] alu_result_w;
  wire [31:0] write_data_w;
  wire [3:0]  stat_w, stat_en_w, stat_out_w;

  wire [3:0]  opcode = ir[31:28];
  wire [3:0]  mm     = ir[27:24];
  wire [3:0]  rs     = ir[19:16];
  wire [3:0]  rt     = ir[15:12];
  wire [3:0]  rd     = ir[23:20];
  wire [15:0] imm    = ir[15:0];

// component instantiation goes here
  ctrl my_ctrl (
    .clk(clk), 
    .rst_f(rst_f), 
    .opcode(ir[31:28]), 
    .mm(ir[27:24]), 
    .stat(stat_out_w), 
    .rf_we(rf_we_w), 
    .alu_op(alu_op_w), 
    .wb_sel(wb_sel_w)
  );

  rf my_rf (
    .clk(clk), 
    .read_rega(ir[19:16]), 
    .read_regb(ir[15:12]), 
    .write_reg(ir[23:20]), 
    .write_data(write_data_w), 
    .rf_we(rf_we_w), 
    .rsa(rsa_w), 
    .rsb(rsb_w)
  );

  alu my_alu (
    .clk(clk), 
    .rsa(rsa_w), 
    .rsb(rsb_w), 
    .imm(ir[15:0]), 
    .c_in(stat_out_w[3]), 
    .alu_op(alu_op_w), 
    .funct(ir[27:24]), 
    .alu_result(alu_result_w), 
    .stat(stat_w), 
    .stat_en(stat_en_w)
  );

  mux32 my_mux (
    .in_a(alu_result_w), 
    .in_b(32'h00000000), 
    .sel(wb_sel_w), 
    .out(write_data_w)
  );

  statreg my_statreg (
    .clk(clk), 
    .in(stat_w), 
    .enable(stat_en_w), 
    .out(stat_out_w)
  );

  initial
  
// put a $monitor statement here.  
  initial begin
    $monitor("Time=%d IR=%h R1=%h R2=%h R3=%h R4=%h R5=%h ALU_OP=%b WB_SEL=%b RF_WE=%b W_DATA=%h",
             $time, ir, 
             my_rf.ram_array[1], my_rf.ram_array[2], 
             my_rf.ram_array[3], my_rf.ram_array[4], 
             my_rf.ram_array[5], 
             alu_op_w, wb_sel_w, rf_we_w, write_data_w);
  end


endmodule


