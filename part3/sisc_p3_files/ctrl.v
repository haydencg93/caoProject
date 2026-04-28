`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load, dm_we, rb_sel, mm_sel);

  input clk, rst_f;
  input [3:0] opcode, mm, stat; // mm is the Condition Code (CC) from ir[27:24]
  
  // Updated outputs for Part 3
  output reg rf_we, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load;
  output reg dm_we, rb_sel, mm_sel; 
  output reg [3:0] alu_op;

  // States
  parameter start1 = 1, fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;
  
  // Opcodes (Added LOD and STR)
  parameter NOOP = 0, REG_OP = 1, REG_IM = 2, BRA = 4, BRR = 5, BNE = 6, BNR = 7, LOD = 10, STR = 11, HLT = 15;
  
  reg [2:0] present_state, next_state;

  // State Transition - Sequential
  always @(posedge clk or negedge rst_f) begin
    if (rst_f == 1'b0) 
      present_state <= start1;
    else 
      present_state <= next_state;
  end

  // Next State Logic - Combinational
  always @(*) begin
    case(present_state)
      start1:    next_state = fetch;
      fetch:     next_state = decode;
      decode:    begin
        // Branches finish here and loop back to fetch
        if (opcode == BRA || opcode == BRR || opcode == BNE || opcode == BNR)
          next_state = fetch;
        else if (opcode == HLT)
          next_state = decode;
        else if (opcode == NOOP)
          next_state = fetch;
        else
          next_state = execute;
      end
      execute:   next_state = mem;
      mem:       next_state = writeback;
      writeback: next_state = fetch;
      default:   next_state = fetch;
    endcase
  end

  // Output Logic
  always @(*) begin
    // Defaults to prevent latches
    rf_we = 0; wb_sel = 0; alu_op = 0;
    br_sel = 0; pc_sel = 0; pc_write = 0; ir_load = 0;
    
    // Part 3 Defaults
    dm_we = 0; 
    rb_sel = 0; 
    mm_sel = mm[3]; // mm[3] is ir[27]. 1 = Indexed (ALU Address), 0 = Absolute (Immediate Address)
    
    pc_rst = (rst_f == 1'b0);

    // Override rb_sel for stores: route Rd (ir[23:20]) to the Reg B read port
    if (opcode == STR) begin
      rb_sel = 1;
    end

    case(present_state)
      start1: begin
        pc_rst = 1;
      end

      fetch: begin
        ir_load = 1;
        pc_write = 1; // Increment PC (PC = PC + 1)
        pc_sel = 0;   // Select PC_inc mux path
      end

      decode: begin
        // BRA: absolute — taken if (CC & STAT) != 0
        if (opcode == BRA) begin
          if ((mm & stat) != 4'b0000) begin
            br_sel = 1;
            pc_sel = 1; pc_write = 1;
          end
        end
        // BRR: relative — taken if (CC & STAT) != 0
        else if (opcode == BRR) begin
          if ((mm & stat) != 4'b0000) begin
            br_sel = 0;
            pc_sel = 1; pc_write = 1;
          end
        end
        // BNE: absolute — taken if (CC & STAT) == 0;
        else if (opcode == BNE) begin
          if (mm == 4'b0000 || (mm & stat) == 4'b0000) begin
            br_sel = 1;
            pc_sel = 1; pc_write = 1;
          end
        end
        // BNR: relative — taken if (CC & STAT) == 0;
        else if (opcode == BNR) begin
          if (mm == 4'b0000 || (mm & stat) == 4'b0000) begin
            br_sel = 0;
            pc_sel = 1; pc_write = 1;
          end
        end
      end

      execute, mem, writeback: begin
        if (opcode == REG_OP) begin
          alu_op = 4'b0001;
          if (present_state == writeback) rf_we = 1;
        end
        else if (opcode == REG_IM) begin
          alu_op = 4'b0011;
          if (present_state == writeback) rf_we = 1;
        end
        
        // --- NEW: Load Instructions (LDA, LDX) ---
        else if (opcode == LOD) begin
          alu_op = 4'b0100; // Computes Rsa + imm_ext for LDX
          if (present_state == writeback) begin
            rf_we = 1;      // Enable register write
            wb_sel = 1;     // Select dm_out instead of alu_out
          end
        end
        
        // --- NEW: Store Instructions (STA, STX) ---
        else if (opcode == STR) begin
          alu_op = 4'b0100; // Computes Rsa + imm_ext for STX
          if (present_state == mem) begin
            dm_we = 1;      // Enable memory write
          end
        end
      end
    endcase
  end

  // Halt Logic
  always @(posedge clk) begin
    if (present_state == decode && opcode == HLT) begin
      $display("Halt instruction reached at time %t. Simulation finished.", $time);
      $finish;
    end
  end

endmodule