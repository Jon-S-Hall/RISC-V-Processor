// Name: Joshua Bone, Jonathan Hall
// BU ID: U  ,U21798292
// EC413 Project: Top Level Module

module top #(
  parameter ADDRESS_BITS = 16
) (
  input clock,
  input reset,

  output [31:0] wb_data
);


/******************************************************************************
*                      Start Your Code Here
******************************************************************************/

// Fetch Wires
    // OUTPUT OF FETCH
wire [ADDRESS_BITS-1:0] PC;

// Decode Wires ----------------------------------------------------------------------------------------------------------
    //OUTPUT FROM DECODE
wire next_PC_Select; //TO FETCH
wire [ADDRESS_BITS-1:0] Target_PC; //TO FETCH
wire [1:0] op_A_sel; //TO ALU MUX
wire op_B_sel;
wire [31:0] imm32;
wire [5:0] ALU_Control;


//To Reg File
wire [4:0] read_Sel_1;
wire [4:0] read_Sel_2;
wire wEn;
wire write_Sel;
wire mem_wEn;
wire branch_OP;
// Reg File Wires -----------------------------------------------------------------
wire read_Data_1; //TO ALU A MUX
wire read_Data_2; //TO ALU B MUX
//mem write back wires
wire wb_Sel;
// Execute Wires
wire [ADDRESS_BITS-1:0] JALR_target; // Assigned outside of ALU
wire [31:0] ALU_Res;
wire branch;
//wire for writeback to REG
wire [31:0] reg_WB_Data;

//OP A WIRE
wire [31:0] OP_A_IN;
wire [31:0] OP_B_IN;

// Memory Wires
   //OUTPUT FROM RAM - INSTRUCTION
wire [31:0] Instruction;
wire [31:0] d_Read_Data;
// Writeback wires

//mux for OP A and OP B - ask if in the right place
//These values are input into ALU.
assign OP_A_IN = (op_A_sel === 2'b00) ? read_Data_1:
                 (op_A_sel === 2'b01) ? PC:
                 (op_A_sel === 2'b10) ? PC+4:
                 read_Data_1;
assign OP_B_IN = (op_B_sel === 1'b0) ? read_Data_2:
                 (op_B_sel === 1'b1) ? imm32:
                 imm32;
//assign mux to what is written back to REG
assign reg_WB_Data = (wb_Sel === 1'b0) ? ALU_Res:
                     (wb_Sel === 1'b1) ? d_Read_Data: //only from a load instruction.
                      ALU_Res;

//DONE but needs to be checked
fetch #(
  .ADDRESS_BITS(ADDRESS_BITS)
) fetch_inst (
  .clock(clock),
  .reset(reset),
  .next_PC_select(next_PC_Select),
  .target_PC(Target_PC),
  .PC(PC)
);


decode #(
  .ADDRESS_BITS(ADDRESS_BITS)
) decode_unit (

  // Inputs from Fetch
  .PC(PC),
  .instruction(Instruction),

  // Inputs from Execute/ALU
  .JALR_target(ALU_Res), // CHECK THIS
  .branch(branch),

  // Outputs to Fetch
  .next_PC_select(next_PC_Select),
  .target_PC(Target_PC),

  // Outputs to Reg File
  .read_sel1(read_Sel_1),
  .read_sel2(read_Sel_2),
  .write_sel(write_Sel),
  .wEn(wEn),

  // Outputs to Execute/ALU
  .branch_op(branch_OP),
  .imm32(imm32),
  .op_A_sel(op_A_sel),
  .op_B_sel(op_B_sel),
  .ALU_Control(ALU_Control),

  // Outputs to Memory
  .mem_wEn(mem_wEn),

  // Outputs to Writeback
  .wb_sel(wb_Sel)

);


//DONE but needs to be checked
regFile regFile_inst (
  .clock(clock),
  .reset(reset),
  .wEn(wEn), // Write Enable
  .write_data(reg_WB_data),
  .read_sel1(read_Sel_1),
  .read_sel2(read_Sel_2),
  .write_sel(write_Sel),
  .read_data1(read_Data_1),
  .read_data2(read_Data_2)
);



ALU alu_inst(
  .branch_op(branch_OP),
  .ALU_Control(ALU_Control),
  .operand_A(OP_A_IN),
  .operand_B(OP_B_IN),
  .ALU_result(ALU_Res),
  .ALU_branch(branch)
);


ram #(
  .ADDR_WIDTH(ADDRESS_BITS)
) main_memory (
  .clock(clock),

  // Instruction Port
  .i_address(PC),
  .i_read_data(Instruction),

  // Data Port
  .wEn(mem_wEn),
  .d_address(ALU_Res),
  .d_write_data(read_Data_2),
  .d_read_data(d_Read_Data)
);

endmodule
