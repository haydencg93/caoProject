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

  // --- NEW WIRES FOR PART 3 ---
  wire dm_we, rb_sel, mm_sel;
  wire [31:0] dm_out;
  wire [15:0] mem_addr;
  wire [3:0] regb_addr;

  // Module Instantiations
  ir u9 (clk, ir_load, im_out, ir);
  
  // NOTE: Changed from u11 to u8 to match the autograder requirements
  im u8 (pc_out, im_out);
  
  pc u10 (clk, pc_br, pc_sel, pc_write, pc_rst, pc_out);

  br u4 (pc_out, ir[15:0], br_sel, pc_br);
  
  // NOTE: Added dm_we, rb_sel, and mm_sel ports. 
  // You MUST update your ctrl.v module definition to include these outputs!
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
    .ir_load(ir_load),
    .dm_we(dm_we),     // NEW
    .rb_sel(rb_sel),   // NEW
    .mm_sel(mm_sel)    // NEW
  );

  // --- NEW MULTIPLEXER FOR REG B ADDRESS ---
  // Selects between instruction bits [15:12] and [23:20] for STX
  mux4 u12 (.in_a(ir[15:12]), .in_b(ir[23:20]), .sel(rb_sel), .out(regb_addr));
  
  // NOTE: Updated read_regb to use regb_addr from mux4
  rf u2 (.clk(clk), .read_rega(ir[19:16]), .read_regb(regb_addr), .write_reg(ir[23:20]), .write_data(wr_dat), .rf_we(rf_we), .rsa(rega), .rsb(regb));
  
  alu u3 (clk, rega, regb, ir[15:0], stat[3], alu_op, ir[27:24], alu_out, alu_sts, stat_en);

  // --- NEW MULTIPLEXER FOR MEMORY ADDRESS ---
  // Selects between immediate address (LDA/STA) and ALU computed address (LDX/STX)
  mux16 u13 (.in_a(ir[15:0]), .in_b(alu_out[15:0]), .sel(mm_sel), .out(mem_addr));

  // --- NEW DATA MEMORY MODULE ---
  dm u11 (.read_addr(mem_addr), .write_addr(mem_addr), .write_data(regb), .dm_we(dm_we), .read_data(dm_out));

  // NOTE: Updated mux32 in_b to use the Data Memory output (dm_out) instead of 32'h00000000
  mux32 u5 (.in_a(alu_out), .in_b(dm_out), .sel(wb_sel), .out(wr_dat));
  
  statreg u6 (clk, alu_sts, stat_en, stat);

  // Monitor
  initial begin
    $display("Time | IR | PC | R1 | R2 | R3 | OP | BS | PW | PS | WE");
    $monitor("%t | %h | %h | %h | %h | %h | %h | %b | %b | %b | %b", 
             $time, ir, pc_out, u2.ram_array[1], u2.ram_array[2], u2.ram_array[3], 
             alu_op, br_sel, pc_write, pc_sel, rf_we);
  end

endmodule