`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load);
  input clk, rst_f;
  input [3:0] opcode, mm, stat;
  output reg rf_we, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load;
  output reg [3:0] alu_op;
  
  // State Definitions
  parameter fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;
  
  // Opcode Definitions
  parameter NO_OP = 0, REG_OP = 1, REG_IM = 2, BNE = 6, BRR = 5, BNR = 7, HLT = 15;
  
  reg [2:0] present_state, next_state;

  // State Register
  always @(posedge clk or negedge rst_f) begin
    if (rst_f == 1'b0) 
      present_state <= fetch;
    else 
      present_state <= next_state;
  end
  
  // Next State Logic
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

  // Control Signal Logic
  always @(*) begin
    // Default values to avoid latches
    rf_we = 0; wb_sel = 0; alu_op = 0; 
    br_sel = 0; pc_rst = 0; pc_write = 0; pc_sel = 0; ir_load = 0;

    // Reset logic
    if (rst_f == 1'b0) begin
        pc_rst = 1;
    end

    case(present_state)
      fetch: begin
        ir_load = 1;    // Load instruction from IM to IR
        pc_write = 1;   // Prepare to increment PC
        pc_sel = 0;     // Select PC + 1
      end

      decode: begin
        // Branch Logic implemented in Decode per requirements
        case (opcode)
          BNE: begin // Absolute Branch if Not Equal (Z=0)
            if (stat[0] == 1'b0) begin
              br_sel = 1;   // Absolute address
              pc_sel = 1;   // Select branch address
              pc_write = 1; // Load it into PC
            end
          end
          BRR: begin // Relative Branch (Unconditional/Always)
              br_sel = 0;   // Relative address (PC + offset)
              pc_sel = 1;   // Select branch address
              pc_write = 1; // Load it into PC
          end
          BNR: begin // Relative Branch if Not Equal (Z=0)
            if (stat[0] == 1'b0) begin
              br_sel = 0;   // Relative address
              pc_sel = 1;   // Select branch address
              pc_write = 1; // Load it into PC
            end
          end
        endcase
      end

      execute, mem, writeback: begin 
        // Part 1 ALU Operations
        if (opcode == REG_OP) alu_op = 4'b0001;
        else if (opcode == REG_IM) alu_op = 4'b0011;
        else if (opcode == HLT) begin
           $display("HALT encountered at %0t", $time);
           $finish;
        end
        
        // Writeback logic
        if (present_state == writeback) begin
          if (opcode == REG_OP || opcode == REG_IM) rf_we = 1;
        end
      end
    endcase
  end
endmodule