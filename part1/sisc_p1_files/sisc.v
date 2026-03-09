// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps  

module sisc (clk, rst_f, ir);

  input clk, rst_f;
  input [31:0] ir;

// declare all internal wires here
  wire [3:0]  alu_op;      
  wire        rf_we;      
  wire        wb_sel;      
  
  wire [31:0] rsa;        
  wire [31:0] rsb;        
  wire [31:0] alu_result; 
  wire [31:0] write_data; 
  
  wire [3:0]  stat_out;     
  wire [3:0]  alu_stat_out; 
  wire [3:0]  alu_stat_enable; // FIXED: Changed from single wire to [3:0]

// component instantiation goes here

//control unit
  ctrl ctrl_unit (
    .clk(clk),
    .rst_f(rst_f),
    .opcode(ir[31:28]),
    .mm(ir[27:24]),
    .stat(stat_out),
    .rf_we(rf_we),
    .alu_op(alu_op),
    .wb_sel(wb_sel)
);

//rf
rf rf_unit (
    .clk(clk),
    .read_rega(ir[19:16]),
    .read_regb(ir[15:12]),
    .write_reg(ir[23:20]),
    .write_data(write_data),
    .rf_we(rf_we),
    .rsa(rsa),
    .rsb(rsb)
);

//alu
alu alu_unit (
    .clk(clk),
    .rsa(rsa),
    .rsb(rsb),
    .imm(ir[15:0]),
    .alu_op(alu_op),
    .funct(ir[27:24]),
    .c_in(stat_out[3]), 
    .alu_result(alu_result),
    .stat(alu_stat_out),
    .stat_en(alu_stat_enable)
);

//mux
mux32 wb_mux (
    .in_a(alu_result),
    .in_b(32'h0),       
    .sel(wb_sel),
    .out(write_data)
);

//stat
statreg stat_unit (
    .clk(clk),
    .in(alu_stat_out),
    .enable(alu_stat_enable),
    .out(stat_out)
);
  
// put a $monitor statement here.  
  initial begin
    $display("Time | IR | R1 | R2 | R3 | R4 | R5 | ALU_OP | WB | WE | WriteData");
    $monitor("%dns | %h | %h | %h | %h | %h | %h | %b | %b | %b | %h", 
              $time, ir, 
              rf_unit.ram_array[1], rf_unit.ram_array[2], 
              rf_unit.ram_array[3], rf_unit.ram_array[4], 
              rf_unit.ram_array[5], 
              alu_op, wb_sel, rf_we, write_data);
end

endmodule