`timescale 1ns/10ps
// modified from single cycle cpu
module controlLogic (Reg2Loc, RegWrite_n, MemWrite, BrTaken, UnCondBr_n, setFlag_n, ALUSrc, MemToReg, ALUOp, memRead, Rd, Rn, Rm, Imm12,
                    Imm9, Imm26, Imm19, SHAMT, operation, zero, negative, overflow, carryout, zero_new, negative_new, overflow_new, carry_out_new,
						  branch, forwardRd1, forwardRd2, forwardRegWrite1, forwardRegWrite2, zeroAccelerate, ifshift, rst, clk);
	input logic [31:0] operation;
	input logic zero, negative, overflow, carryout, zero_new, negative_new, overflow_new, carry_out_new, zeroAccelerate;

	output logic Reg2Loc, RegWrite_n, MemWrite, BrTaken, UnCondBr_n, setFlag_n, memRead, branch, ifshift;	
	output logic [1:0] ALUSrc, MemToReg;
	output logic [2:0] ALUOp;
	output logic [4:0] Rd, Rn, Rm;
	output logic [11:0] Imm12;
	output logic [8:0] Imm9;
	output logic [25:0] Imm26;
	output logic [18:0] Imm19;
	output logic [5:0] SHAMT;

	logic setFlag, UnCondBr, condbranch, RegWrite, BrTaken_old;
	
	assign Rd = operation[4:0];
	assign Rn = operation[9:5];
	assign Rm = operation[20:16];
	assign SHAMT = operation[15:10];
	
	input logic rst, clk;
	
	// need for the forwarding unit comparision
	// save the destination register from last two cycle
	output logic [4:0] forwardRd1, forwardRd2;
	DFF5 RD1(forwardRd1, Rd, rst, clk);
  	DFF5 RD2 (forwardRd2, forwardRd1, rst, clk);
	
   // for forwarding to happen, the regWrite needs to be 1
	// also the regWrite signal will be used in the write stage of the pipeline
	// so delay by 4 obtained from this control logic
	output logic forwardRegWrite1, forwardRegWrite2; 
	logic forwardRegWrite3;
	D_FF regWrite1(forwardRegWrite1, RegWrite, rst, clk);
	D_FF regWrite2(forwardRegWrite2, forwardRegWrite1, rst, clk);
	D_FF regWrite3(forwardRegWrite3, forwardRegWrite2, rst, clk);
	D_FF regWrite4(RegWrite_n, forwardRegWrite3, rst, clk);


	assign Imm9  = operation[20:12];
	assign Imm12 = operation[21:10];
	assign Imm19 = operation[23:5];
	assign Imm26 = operation[25:0];
	
	parameter ADDI = 10'b1001000100;          // 0x244
	parameter ADDS = 11'b10101011000;         // 0x558
	parameter AND =  11'b10001010000;         // 0x450
	parameter B = 6'b000101;                  // 0x05;
	parameter BLT = 8'b01010100;              // 0x54 to choose B.cond
	parameter CBZ = 8'b10110100;              // 0xB4
	parameter EOR = 11'b11001010000;           // 0x650
	parameter LDUR = 11'b11111000010;         // 0x7c2
	parameter LSR = 11'b11010011010;          // 0x69a
	parameter STUR = 11'b11111000000;         // 0x7c0
	parameter SUBS = 11'b11101011000;         // 0x758
	
	assign ifshift = (operation[31:21] == LSR);
	
  // cntrl			Operation				  		Notes:
  // 000:			result = B						value of overflow and carry_out unimportant
  // 010:			result = A + B
  // 011:			result = A - B
  // 100:			result = bitwise A & B		value of overflow and carry_out unimportant
  // 101:			result = bitwise A | B		value of overflow and carry_out unimportant
  // 110:			result = bitwise A XOR B	value of overflow and carry_out unimportant
  logic [14:0] control;
  
  //       [14]          [13]      [12:11]     [10:9]           [8]     [7]        [6]       [5]      [4]      [3:1]       [0]     
  assign  {condbranch, Reg2Loc, ALUSrc[1:0], MemToReg[1:0], RegWrite, MemWrite, setFlag, BrTaken_old, UnCondBr, ALUOp[2:0], memRead} = control;


	always_comb begin
      // modified from single cycle
		// the brTaken signal all set to 0 first, 
		// since the cpu will always execute the noop before branch to other address
		// also added signal condbranch which indicates if the instruction is conditional branch
	   if(operation[31:22] == ADDI) begin			
			control = 15'b0x01101000x0100;
		end else if (operation [31:21] == ADDS) begin
			control = 15'b0011101010x0100;
		end else if (operation[31:21] == AND) begin
			control = 15'b0011101000x1000;
		end else if (operation[31:26] == B) begin
			control = 15'b0xxxxx00000xxx0;
		end else if (operation[31:24] == BLT && operation[4:0] == 5'b01011) begin
			control = 15'b1xxxxx00001xxx0; 
		end else if (operation[31:24] == CBZ) begin
			control = 15'b1111xx000010000;
		end else if (operation[31:21] == EOR) begin
			control = 15'b0011101000x1100;
		end else if(operation[31:21] == LDUR) begin
			control = 15'b0x10011000x0101;
		end else if(operation[31:21] == LSR) begin
			control = 15'b0xxx111000xxxx0;
		end else if(operation[31:21] == STUR) begin
			control = 15'b0110xx0100x0100;
		end else if(operation[31:21] == SUBS) begin
			control = 15'b0011101010x0110;
		end else begin
			control = 15'b0;
		end
	end
	
	
	// needed when noop is executed
	// save the branch instruction to evaluate after fetching the noop 
	logic [31:0] branchInstruction;
   DFF32 newBranch(branchInstruction, operation, rst, clk);
	
	// set the control signal if it's a conditional branch(cbz or blt) delay by 1 since it will not be used immediately
	// save the unconditional branch signal with 1 delay since it will also not be used immediately
	D_FF saveBranchInfo (branch, condbranch, rst, clk);
	D_FF saveUncond (UnCondBr_n, UnCondBr, rst, clk);
	// save the flag for setflag uses 2 cycle for cpu in the exec stage
	DFF1_x2 newsetFlag(setFlag_n, setFlag, rst, clk);
	// check if the branch is taken or not based on the saved instruction and signals
	branchCheck updateBrTaken(branchInstruction, zero, negative, overflow, carryout, zero_new, negative_new, overflow_new, carry_out_new, zeroAccelerate, 
               setFlag_n, BrTaken);
	
endmodule


/*

module controlLogic_testbench();
   logic [31:0] operation;
	logic zero, negative, overflow, carryout, zero_new, negative_new, overflow_new, carry_out_new;

	logic Reg2Loc, RegWrite, MemWrite, BrTaken, UnCondBr, setFlag, memRead;	
	logic [1:0] ALUSrc, MemToReg;
	logic [2:0] ALUOp;
	logic [4:0] Rd, Rn, Rm;
	logic [11:0] Imm12;
	logic [8:0] Imm9;
	logic [25:0] Imm26;
	logic [18:0] Imm19;
	logic [5:0] SHAMT;

    
		
	initial begin
	   zero = 0; negative = 0; overflow = 0; carryout = 0; zero_new = 0; 
		negative_new = 0; overflow_new = 0; carry_out_new = 0;
		operation = 32'b10010001000000000000001111100000; #10; //ADDI
		operation = 32'b00010100000000000000000000000000;  #10;  //B
		operation = 32'b11101011000000100000000000100011; #10;   //SUBS
      operation = 32'b10101011000001010000000000100111;  #10;  //ADDS
		operation = 32'b10110100000000000000001010011111; #10; //CBZ
		operation = 32'b11111000000000000000001111100000; #10; //STUR
		operation = 32'b11111000010000000101000001000110; #10; //LDUR
	end


   controlLogic dut (.Reg2Loc, .RegWrite, .MemWrite, .BrTaken, .UnCondBr, .setFlag, .ALUSrc, .MemToReg, .ALUOp, .memRead, .Rd, .Rn, .Rm, .Imm12,
                    .Imm9, .Imm26, .Imm19, .SHAMT, .operation, .zero, .negative, .overflow, .carryout, .zero_new, .negative_new, .overflow_new, .carry_out_new);

						  
						  
						  
endmodule
*/