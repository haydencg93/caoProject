`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel, 
             br_sel, pc_rst, pc_write, pc_sel, ir_load);

  input clk, rst_f;
  input [3:0] opcode, mm, stat;
  output reg rf_we, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load;
  output reg [3:0] alu_op;

  parameter start0=0, start1=1, fetch=2, decode=3, execute=4, mem=5, writeback=6;
  parameter REG_OP=1, REG_IM=2, BRA=4, BNE=6, HLT=15;

  reg [2:0] present_state, next_state;

  always @(posedge clk, negedge rst_f) begin
    if (rst_f == 1'b0) present_state <= start1;
    else present_state <= next_state;
  end

  always @(*) begin
    case(present_state)
      start0:    next_state = start1;
      start1:    next_state = (rst_f == 1'b0) ? start1 : fetch;
      fetch:     next_state = decode;
      decode:    next_state = execute;
      execute:   next_state = mem;
      mem:       next_state = writeback;
      writeback: next_state = fetch;
      default:   next_state = start1;
    endcase
  end

  always @(*) begin
    rf_we = 0; wb_sel = 0; alu_op = 0;
    br_sel = 0; pc_sel = 0; pc_write = 0; ir_load = 0;
    pc_rst = (rst_f == 1'b0); 

    case(present_state)
      start1:    pc_rst = 1;
      fetch:     begin ir_load = 1; pc_write = 1; end
      decode:    begin
        if (opcode == BRA) begin br_sel = 1; pc_write = 1; pc_sel = 1; end
        else if (opcode == BNE && stat[2] == 0) begin br_sel = 1; pc_write = 1; pc_sel = 1; end
      end
      execute:   begin
        if (opcode == REG_OP) alu_op = 4'b0001; 
        if (opcode == REG_IM) alu_op = 4'b0011; 
      end
      writeback: if (opcode == REG_OP || opcode == REG_IM) rf_we = 1;
    endcase
  end

  always @(opcode) if (opcode == HLT) begin #5 $display("Halt."); $stop; end

endmodule