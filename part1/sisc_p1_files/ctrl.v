// ECE:3350 SISC computer project
// finite state machine

`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel);

  /* Declare the ports listed above as inputs or outputs.  Note that this is
     only the signals for part 1.  You will be adding signals for parts 2,
     2, and 4. */
  
  input clk, rst_f;
  input [3:0] opcode, mm, stat;
  output reg rf_we, wb_sel;
  output reg [3:0] alu_op;
  
  // state parameter declarations
  
  parameter start0 = 0, start1 = 1, fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;
   
  // opcode parameter declarations
  
  parameter NOOP = 0, REG_OP = 1, REG_IM = 2, SWAP = 3, BRA = 4, BRR = 5, BNE = 6, BNR = 7;
  parameter JPA = 8, JPR = 9, LOD = 10, STR = 11, CALL = 12, RET = 13, HLT = 15;
	
  // addressing modes
  
  parameter AM_IMM = 8;

  // state register and next state signal
  
  reg [2:0]  present_state, next_state;

  // initial procedure to initialize the present state to 'start0'.

  initial
    present_state = start0;

  /* Procedure that progresses the fsm to the next state on the positive edge of 
     the clock, OR resets the state to 'start1' on the negative edge of rst_f. 
     Notice that the computer is reset when rst_f is low, not high. */

  always @(posedge clk, negedge rst_f)
  begin
    if (rst_f == 1'b0)
      present_state <= start1;
    else
      present_state <= next_state;
  end
  
  /* The following combinational procedure determines the next state of the fsm. */

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

  always @(present_state, opcode)
  begin
    // 1. SET DEFAULT VALUES
    // This ensures no accidental writes or "latches" occur
    rf_we = 1'b0;      
    wb_sel = 1'b0;     
    alu_op = 4'b0000;  

    case(present_state)
      // During EXECUTE, tell the ALU which operation to perform
      execute: begin
        case(opcode)
          REG_OP:  alu_op = 4'b0001; // bits 3:1=000 (Rsa <fc> Rsb), bit 0=1 (update stat)
          REG_IM:  alu_op = 4'b0011; // bits 3:1=001 (Rsa <fc> imm), bit 0=1 (update stat)
          NOOP:    alu_op = 4'b1100; // bits 3:1=110 (Rsa), bit 0=0 (no update) 

          HLT: begin
            $display("HALT instruction encountered at time %d", $time); [cite: 393]
            $stop; // This stops the simulation 
          end
          
          default: alu_op = 4'b0000; 
        endcase
      end

      // During WRITEBACK, enable saving the data to the register file.
      writeback: begin
        case(opcode)
          REG_OP, REG_IM: begin
            rf_we = 1'b1;   // Set Write Enable to 1
            wb_sel = 1'b0;  // Select ALU result (0) to go back to RF
          end
          // NOOP and HLT do not write back [cite: 363]
        endcase
      end
      
      // Other states (fetch, decode, mem) maintain default values
    endcase
  end
    
  
endmodule
