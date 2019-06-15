`timescale 1ns/10ps
module cpu(rst, clk);
	input logic rst, clk;
	
	logic Reg2Loc, RegWrite, MemWrite, BrTaken, UnCondBr_n, setFlag_n, memRead, branch;
	logic zero, negative, overflow, carry_out;
	logic adder1_carryout;
	logic adder2_carryout;
	logic negative_new;
	logic zero_new;
	logic overflow_new;
	logic carry_out_new;
	logic [1:0]ALUSrc, MemToReg;
	logic [2:0]ALUOp;
	logic [4:0]Rd, Rn, Rm;
	logic [4:0] RdorRm;
	logic [5:0]SHAMT;
	logic [8:0]Imm9;
	logic [11:0]Imm12;
	logic [18:0]Imm19;
	logic [25:0]Imm26;
	logic [31:0]instruction;
	logic [63:0]SED9;
	logic [63:0]ZED12;
	logic [63:0]SED19;
	logic [63:0]SED26;
	logic [63:0]UnCondBrMUX_out;	
	logic [63:0]shifter1_out;	
	logic [63:0] PC;
	logic [63:0]adder1_out;
	logic [63:0] extended4;
	logic [63:0]adder2_out;
	logic [63:0]BrtakenMUX_out;
	logic [63:0] regWriteData;
	logic [63:0] Da;
	logic [63:0] Db;
	logic [63:0]shifter2_out;
	logic [63:0] ALU_in0;
	logic [63:0] ALU_out;	
	logic [63:0] datamem_out;
	logic [4:0] forwardRd1, forwardRd2;
	logic forwardRegWrite1, forwardRegWrite2;
	logic [63:0] regWriteData_n;
	logic zeroAccelerate;
	
   // -------------------------------------------------Instruction Fetch-----------------------------------------------------------	

	logic [63:0] final_PC, reset_PC;
	// initialize or reset PC	
	mux_64x2x1 resetPC(final_PC, 64'b0, BrtakenMUX_out, rst);
	D_FF_x64 updatePC (PC, final_PC,  clk, 1'b1);
	
	// compute possible new PC 
	// delay the address for unconditional branch since it will not execute immediately
	// also delay conditional branch and determine which address should go next
	logic [25:0] Imm26_n;
	logic [18:0] Imm19_n, nextImm19;
	DFF19 newImm19 (Imm19_n, Imm19, rst,  clk);
	// unconditional branch if taken then feed saved 19-bits immediate, if not taken then feed 0 which is dummy value
	mux_19x2x1 selectAddress(nextImm19, Imm19_n, 19'b0, branch); 
	DFF26 newImm26 (Imm26_n, Imm26, rst,  clk);
	signExtend19 se19 (SED19,nextImm19); //extend the chosen immediate
	signExtend26 se26 (SED26,Imm26_n);

	mux_64x2x1 UnCondBrMUX (UnCondBrMUX_out, SED19, SED26, UnCondBr_n);
	shifter shifter1 (UnCondBrMUX_out, 1'b0, 6'b000010, shifter1_out);
	
	logic [63:0] ifBranchPC, choosePC;
	logic co_pc, negativepc, zeropc, overpc, carrypc;
	//alu (result, negative, zero, overflow, carry_out, A, B, cntrl); if branch PC - 4 back to last branch pc
	alu minus(ifBranchPC, negativepc, zeropc, overpc, carrypc, PC, 64'h0000000000000004, 3'b011);
	mux_64x2x1 choose(choosePC, ifBranchPC, PC,  BrTaken);

   adder_64 adder1 (adder1_out, adder1_carryout, choosePC, shifter1_out, 1'b0);
	
	// PC = PC + 4
	signExtend9 extend4 (extended4, 9'b000000100);
	adder_64 adder2 (adder2_out, adder2_carryout, choosePC, extended4, 1'b0);

	mux_64x2x1 BrTakenMUX (BrtakenMUX_out, adder1_out, adder2_out, BrTaken);
	
	
	// new instruction fetch
	instructmem imfetch (PC, instruction,  clk);
	
	//--------------------------------------------------control----------------------------------------------------------------------------
	// instruction decode
	controlLogic control (Reg2Loc, RegWrite, MemWrite, BrTaken, UnCondBr_n, setFlag_n, ALUSrc, MemToReg, ALUOp, 
								 memRead, Rd, Rn, Rm, Imm12,Imm9, Imm26, Imm19, SHAMT, instruction, zero, negative, 
								 overflow, carry_out, zero_new, negative_new, overflow_new, carry_out_new, branch,
								 forwardRd1, forwardRd2, forwardRegWrite1, forwardRegWrite2, zeroAccelerate, ifshift, rst,  clk);

   // ------------------------------------------------regDec 2------------------------------------------------------------------------------	
	// regDec stage - stage 2
	logic [4:0] Rn_n, Rd_n, Rm_n, Aw;
	logic [11:0] Imm12_n;
	logic [8:0] Imm9_n;
	logic Reg2Loc_n;
   logic [1:0]	ALUSrc_n;
	
	// delay by 1 obtained from control unit 
   DFF5 newRd (Rd_n, Rd, rst,  clk);
	DFF5 newRn (Rn_n, Rn, rst,  clk);
	DFF5 newRm (Rm_n, Rm, rst,  clk);
   D_FF Reg2LocSignal (Reg2Loc_n, Reg2Loc, rst,  clk);
	DFF2 ALUSrcSignal (ALUSrc_n, ALUSrc, rst,  clk);
	DFF12 newImm12 (Imm12_n, Imm12, rst,  clk);
	DFF9 newImm (Imm9_n, Imm9, rst,  clk);
	mux_5x2x1 RdRm  (RdorRm, Rd_n, Rm_n, Reg2Loc_n);
	
	
	// delay Rd by 3 for AW used for Wr stage
	DFF5_x3 writeRd (Aw, Rd_n, rst, clk);
	
	// delayed regWriteData obtained from last mem/wr stage
   // AW is delayed Rd instead of Rd from last mem/wr stage
   // invert clock for regfile to avoid data hazard	
	// and the RegWrite is already delayed in the control signal so no need to delay here
	regfile regdata (Da, Db, regWriteData_n, Rn_n, RdorRm, Aw,
						  RegWrite, ~clk);
	

   logic [63:0] aluA, aluB, execStageOut;
	// zero or sign extend
	zeroExtend12 se12 (ZED12,Imm12_n);
	signExtend9 se9	(SED9, Imm9_n);
	mux_64x4x1 ALUsrcMUX (ALU_in0, aluB, SED9, ZED12, 64'bx, ALUSrc_n);

	// forwarding unit forward_a and forward_b obtained from control delay by 1 
	logic [1:0] ForwardA, ForwardB;
	logic [4:0] forwardRd1_n, forwardRd2_n;
	DFF5 newFor1 (forwardRd1_n, forwardRd1, rst, clk);
	DFF5 newFor2 (forwardRd2_n, forwardRd2, rst, clk);
	logic forwardRegWrite1_n, forwardRegWrite2_n;
	D_FF newreg1(forwardRegWrite1_n, forwardRegWrite1, rst, clk);
	D_FF newreg2(forwardRegWrite2_n, forwardRegWrite2, rst, clk);
	forwardingUnit FU (forwardRd1_n, forwardRd2_n, Rn_n, RdorRm, forwardRegWrite1_n, forwardRegWrite2_n, ForwardA, ForwardB); // delayed rn and rdorrm

	// if last instruction was shift, the forward A value at exec stage will be obtained from the shifter2_out instead of alu output
	logic ifshift_n;
	DFF1_x2 newshiftchoose (ifshift_n, ifshift, rst, clk);
	mux_64x2x1 forwardingexec(execStageOut, shifter2_out, ALU_out, ifshift_n);
	
	
	//                                Bmem   /   Cexec /  Dno forward         
	mux_64x4x1 selectA(aluA, 64'bx, regWriteData, execStageOut, Da, ForwardA);
	mux_64x4x1 selectB(aluB, 64'bx, regWriteData, execStageOut, Db, ForwardB);
	// find zero flag for accelerate branch 
	check_zero accelerate (zeroAccelerate, ALU_in0);
	
	// -------------------------------------------------- EXEC stage 3----------------------------------------------------------------------
	// aluop delay by 2 obtained from control 
	// alua and alub delay by 1 obtained from reg/dec stage
	logic [63:0] aluA_n, ALU_in0_n;
	DFF64 newALUB (ALU_in0_n, ALU_in0, rst, clk);
	DFF64 newALUA (aluA_n, aluA, rst, clk);
	
	logic [2:0] ALUOp_n;
	DFF3_x2 newALUOp (ALUOp_n, ALUOp, rst,  clk);
	
	alu alu(ALU_out, negative_new, zero_new, overflow_new, carry_out_new, aluA_n, ALU_in0_n, ALUOp_n);
	
	
	
	// update flags output negative, zero, overflow, carry_out
	// the setFlag signal is delayed 2 cycle in the controllogic so no need to delay here
	flag_update negative_update  (negative,  negative_new,   clk, setFlag_n);
	flag_update zero_update      (zero, 	  zero_new, 	   clk, setFlag_n);
	flag_update overflow_update  (overflow,  overflow_new,   clk, setFlag_n);
	flag_update carry_out_update (carry_out, carry_out_new,  clk, setFlag_n);

	
	// shifter 2: SHAMT needs to be delayed by 2 obtained from control
	// the value being shifted obtain 
	logic [5:0] SHAMT_n;
	logic [63:0] Da_1;
   DFF6_x2 newSHAMT (SHAMT_n, SHAMT, rst,  clk);

	shifter shifter2 (aluA_n, 1'b1, SHAMT_n,  shifter2_out);

	// --------------------------------------------------MEM stage 4---------------------------------------------------------------------------
	// data memory
	// ALU_out delay by 1 obtained from last stage
	logic [63:0] ALU_out_n;
	DFF64 newALU_out (ALU_out_n, ALU_out, rst,  clk);	
	// Db  delay by 2 obtained from reg/dec stage
	logic [63:0] aluB_1, aluB_2;
	DFF64 newDb1 (aluB_1, aluB, rst,  clk);
	DFF64 newDb2 (aluB_2, aluB_1, rst,  clk);
	// xfer, MemWrite, MemRead delay by 3 obtained from control
	logic [3:0] xfer, xfer_n;
	assign xfer = 4'b1000;
	logic MemWrite_n, MemRead_n;
	DFF4_x3 newXfer (xfer_n, xfer, rst,  clk);
	DFF1_x3 newMemWrite (MemWrite_n, MemWrite, rst,  clk);
	DFF1_x3 newMemRead (MemRead_n, memRead, rst,  clk);
	
											   // read_enable   write_data		     xfer_size
	datamem data (ALU_out_n, MemWrite_n, MemRead_n, 	 aluB_2,			  clk,	xfer_n,  datamem_out);
	
	// shifter2_out obtained from exec delay by 1
	// MemToReg obtained from control delay by 3
	logic [1:0] MemToReg_n;
	logic [63:0] shifter2_out_n;
	DFF2_x3 newMemToReg (MemToReg_n, MemToReg, rst,  clk);
	DFF64 newshifter2 (shifter2_out_n, shifter2_out, rst,  clk);
	
	mux_64x4x1 MenToRegMux (regWriteData, shifter2_out_n, ALU_out_n, datamem_out, 64'bx, MemToReg_n); 
   // ---------------------------------------------------WR stage 5---------------------------------------------------------------------------
	// obtained regWriteData and write back to regfile delay by 1
	DFF64 newRegWriteData(regWriteData_n, regWriteData, rst,  clk);
	
endmodule


module cpu_testbench();
	parameter ClockDelay = 10000;
	logic rst;
	logic clk;
	
	cpu dut (.rst, .clk);
	initial begin
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	integer i;
	
	initial begin
		rst <= 1; @(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
		for (i = 0; i < 1500; i = i + 1) begin
			rst <= 0; @(posedge clk);
		end
		$stop;
	end
	
endmodule


















