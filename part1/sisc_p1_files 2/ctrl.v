`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel);
  input clk, rst_f;
  input [3:0] opcode, mm, stat;
  output reg rf_we, wb_sel;
  output reg [3:0] alu_op;
  
  parameter fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;
  parameter REG_OP = 1, REG_IM = 2, HLT = 15;
  
  reg [2:0] present_state, next_state;

  initial present_state = 2; // FETCH

  always @(posedge clk or negedge rst_f) begin
    if (rst_f == 1'b0) present_state <= 2;
    else present_state <= next_state;
  end
  
  always @(*) begin
    case(present_state)
      fetch:     next_state = decode;
      decode:    next_state = execute;
      execute:   next_state = mem;
      mem:       next_state = writeback;
      writeback: next_state = fetch;
      default:   next_state = fetch;
    endcase
  end

  always @(*) begin
    rf_we = 0; wb_sel = 0; alu_op = 0;
    case(present_state)
      execute, mem, writeback: begin 
        // Hold signals steady so ALU and RF can latch correctly
        if (opcode == REG_OP) alu_op = 4'b0001;
        else if (opcode == REG_IM) alu_op = 4'b0011;
        else if (opcode == HLT) begin
           $display("HALT encountered at %0t", $time);
           $finish;
        end
        
        if (present_state == writeback) begin
          if (opcode == REG_OP || opcode == REG_IM) rf_we = 1;
        end
      end
    endcase
  end
endmodule