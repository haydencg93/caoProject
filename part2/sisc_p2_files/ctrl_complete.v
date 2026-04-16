// ECE:3350 SISC computer project
// finite state machine

`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel);

  /* TODO: Declare the ports listed above as inputs or outputs */
  
  input clk, rst_f;
  input [3:0] opcode, mm, stat;
  output reg rf_we, wb_sel;
  output reg [3:0] alu_op;
  
  // states
  parameter start0 = 0, start1 = 1, fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;
   
  // opcodes
  parameter NOOP = 0, REG_OP = 1, REG_IM = 2, SWAP = 3, BRA = 4, BRR = 5, BNE = 6, BNR = 7;
  parameter JPA = 8, JPR = 9, LOD = 10, STR = 11, CALL = 12, RET = 13, HLT = 15;
	
  // addressing modes
  // parameter AM_IMM = 8;

  // state registers
  reg [2:0]  present_state, next_state;

  /* TODO: Write a clock process that progresses the fsm to the next state on the
       positive edge of the clock, OR resets the state to 'start0' on the negative edge
       of rst_f. Notice that the computer is reset when rst_f is low, not high. */

  initial
    present_state = start0;

  always @(posedge clk, negedge rst_f)
  begin
    if (rst_f == 1'b0)
      present_state <= start1;
    else
      present_state <= next_state;
  end

  
  /* TODO: Write a process that determines the next state of the fsm. */

  always @(present_state, rst_f)
  begin
    case(present_state)
      start0:
        next_state = start1;
      start1:
	  if (rst_f == 1'b0) 
        next_state = start1;
	 else
         next_state = fetch;
      fetch:
        next_state = decode;
      decode:
        next_state = execute;
      execute:
        next_state = mem;
      mem:
        next_state = writeback;
      writeback:
        next_state = fetch;
      default:
        next_state = start1;
    endcase
  end

  // Halt on HLT instruction
  always @ (opcode)
  begin
    if (opcode == HLT)
    begin 
      #5 $display ("Halt."); //Delay 5 ns so $monitor will print the halt instruction
      $stop;
    end
  end
    
  /* TODO: Generate outputs based on the FSM states and inputs. For Parts 2 and 3, you will
       add the new control signals here. */

  always @(present_state, opcode)
  begin

    rf_we  = 1'b0;
    wb_sel = 1'b0;
    alu_op = 4'b0000;
        
    case(present_state)

      execute:
      begin
        if (opcode == REG_OP)
          alu_op = 4'b0001;
        if (opcode == REG_IM)
          alu_op = 4'b0011;
      end

      mem:
      begin
        if (opcode == REG_OP)
          alu_op = 4'b0000;
        if (opcode == REG_IM)
          alu_op = 4'b0010;
      end

      writeback:
      begin
        if (opcode == REG_OP || opcode == REG_IM)
          rf_we  = 1'b1;
      end

      default:
      begin
        rf_we  = 1'b0;
        wb_sel = 1'b0;
        alu_op = 4'b0000;
      end
      
    endcase
  end

endmodule
