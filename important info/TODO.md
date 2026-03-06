This is a significant hardware design project! You are essentially building the "brain" and "skeleton" of a **Simple Instruction Set Computer (SISC)**.

To get this right, we have to bridge the gap between the high-level schematic you see in the image  and the low-level Verilog code.

---

## 📋 The Mini TODO List

Here is the high-level flight plan for Part 1:

1. 
**Define Internal Wiring (`sisc.v`):** Create the "nerve system" to connect all modules based on the diagram.


2. 
**Instantiate Components (`sisc.v`):** Plug in the ALU, Register File, Mux, Status Register, and Control Unit.


3. 
**Implement Control Logic (`ctrl.v`):** Program the "brain" to set `alu_op`, `rf_we`, and `wb_sel` for each instruction.


4. 
**Add Monitoring (`sisc.v`):** Set up the `$monitor` task to track registers and signals for grading.


5. 
**Verify & Debug:** Run the provided testbench (`sisc_tb_p1.v`) and check the output against expected values.



---

## 🛠 Step 1: Define Internal Wiring in `sisc.v`

In your `sisc.v` file, you currently have a module with inputs but no internals. Think of this step as laying down the copper traces on a circuit board. You need to declare `wire` signals for every line you see in the diagram that isn't a top-level input.

### How to do it:

Look at the diagram  and the provided module headers to name your wires. You will need:

* **Instruction Breaks:** The 32-bit `ir` input needs to be split.
* 
`ir[31:28]` → Opcode (goes to CTRL).


* 
`ir[27:24]` → ALU "mm" or Function bits (goes to CTRL).


* 
`ir[23:20]` → Write Register address (goes to RF).


* 
`ir[19:16]` → Read Reg A address (goes to RF).


* 
`ir[15:12]` → Read Reg B address (goes to RF).


* 
`ir[15:0]` → Immediate value (goes to ALU).




* **Control Signals (The "Orange" Lines):**
* 
`wire [3:0] alu_op_wire;` (From CTRL to ALU).


* 
`wire rf_we_wire;` (From CTRL to RF).


* 
`wire wb_sel_wire;` (From CTRL to MUX32).




* **Data Paths:**
* 
`wire [31:0] rsa_wire, rsb_wire;` (From RF to ALU).


* 
`wire [31:0] alu_result_wire;` (From ALU to MUX32).


* 
`wire [31:0] write_data_wire;` (From MUX32 back to RF).


* 
`wire [3:0] stat_wire, stat_en_wire, stat_out_wire;` (Between ALU, STATREG, and CTRL).


<!-- -------------------------------------------------------- -->
## Step 2: Instantiate the Components in `sisc.v`

Now that the "wires" are ready, you need to plug in the physical modules. Think of this like placing components on a motherboard and soldering those wires to the correct pins.

You will use the **Module Name** followed by an **Instance Name** (a name you make up, like `my_alu`), and then map the ports. Referencing the provided files and the diagram, here is how you connect them:

### 1. The Register File (`rf`)

This is the storage unit.

* **Connections:**
* 
`clk` connects to the system `clk`.


* 
`read_rega` connects to `ir[19:16]`.


* 
`read_regb` connects to `ir[15:12]`.


* 
`write_reg` connects to `ir[23:20]`.


* 
`write_data` connects to the output of your MUX.


* 
`rf_we` connects to the `rf_we` control signal from the CTRL unit.


* 
`rsa` and `rsb` connect to the 32-bit wires leading to the ALU.





### 2. The Arithmetic Logic Unit (`alu`)

This performs the math.

* **Connections:**
* 
`rsa` and `rsb` come from the RF.


* 
`imm` connects to the immediate value `ir[15:0]`.


* 
`alu_op` comes from the CTRL unit.


* 
`funct` comes from `ir[27:24]` (the "mm" or function bits).


* 
`c_in` comes from the Status Register (specifically the Carry bit, `stat_out[3]`).


* 
`alu_result` connects to the wire going to the MUX.


* 
`stat` and `stat_en` go to the Status Register.





### 3. The Control Unit (`ctrl`)

This is the "brain" that decides what happens in each state.

* **Connections:**
* 
`opcode` connects to `ir[31:28]`.


* 
`mm` connects to `ir[27:24]`.


* 
`stat` connects to the output of the Status Register.


* Outputs `rf_we`, `alu_op`, and `wb_sel` connect to their respective components.





### 4. The 32-bit Multiplexer (`mux32`)

This decides what gets written back to the registers.

* **Connections:**
* 
`in_a` (sel=0) connects to the `alu_result`.


* 
`in_b` (sel=1) connects to the value `0` (for now, based on the diagram).


* 
`sel` connects to the `wb_sel` signal from CTRL.


* 
`out` goes back to the `write_data` port of the RF.





### 5. The Status Register (`statreg`)

This remembers the results of the last math operation (like if it was zero or negative).

* **Connections:**
* 
`in` connects to the `stat` output of the ALU.


* 
`enable` connects to the `stat_en` output of the ALU.


* 
`out` provides the status bits to the CTRL unit and ALU.





---

**Does this connection logic make sense, or would you like to review the specific Verilog syntax for one of these instantiations before we move to Step 3 (The Control FSM)?**
<!-- -------------------------------------------------------- -->
## Step 3: Implement the Control FSM (`ctrl.v`)

This is the most critical part of the project. The Control Unit acts as the brain, orchestrating how data moves through the processor based on the current **state** and the **instruction** it sees.

Since the `ctrl.v` file already has the state transition logic (moving from `fetch` to `decode` to `execute`, etc.) , your job is to define what the **orange control signals** (`alu_op`, `rf_we`, and `wb_sel`) should be during those states.

### 1. Understanding the Signal "Jobs"

* **`alu_op` (4 bits):** This tells the ALU what math to do. Bit 0 enables status updates, while Bits 3:1 select the operation (e.g., `000` for register-to-register, `001` for register-to-immediate).


* **`rf_we` (1 bit):** Register File Write Enable. If this is `1`, the value at the MUX output is saved into the destination register.


* **`wb_sel` (1 bit):** Write-Back Select. This tells the `MUX32` whether to send the `alu_result` (0) or a constant `0` (1) back to the register file.



---

### 2. How to Map the Instructions

You need to handle instructions like `ADD`, `ADI` (Add Immediate), and `SUB`. Here is the logic you will implement in the `always @(present_state, opcode)` block:

| Instruction | Opcode 

 | <br>`alu_op` (3:1) Logic 

 | `wb_sel` | `rf_we` |
| --- | --- | --- | --- | --- |
| **ADD / SUB / etc.** | `REG_OP` (1) | `3'b000` (Use `funct` bits) | `0` | `1` (at Writeback) |
| **ADI** | `REG_IM` (2) | `3'b001` (Use Immediate) | `0` | `1` (at Writeback) |
| **NOP** | `NOOP` (0) | `3'b110` (Pass RSA) | `0` | `0` (No write) |

---

### 3. State-Specific Timing

Control signals shouldn't be "on" all the time. For Part 1, follow this pattern:

1. **FETCH / DECODE:** Keep `rf_we` at `0`. The CPU is just figuring out what to do.
2. **EXECUTE:** Set the `alu_op` so the ALU can calculate the result.
3. **WRITEBACK:** This is when you set `rf_we = 1`. If you set it too early, you might save the wrong data before the ALU is finished.



> 
> **Important Note:** For `alu_op`, remember that bit 0 is the "Status Update" bit. If you want the `statreg` to save the results of a calculation (like a carry or zero flag), `alu_op[0]` must be `1`.
> 
> 

**Do you understand how to assign these signals based on the state and opcode, or should we look at a specific example like the `ADI` instruction?**
<!-- -------------------------------------------------------- -->