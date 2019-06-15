`timescale 1ns/10ps
// module check for the brTaken signal based on the saved instruction and signals
module branchCheck(branchInstruction, zero, negative, overflow, carryout, zero_new, negative_new, overflow_new, carry_out_new, zeroAccelerate, 
                   setFlag_n, BrTaken);
	input logic [31:0] branchInstruction;
	input logic zero, negative, overflow, carryout, zero_new, negative_new, overflow_new, carry_out_new, zeroAccelerate;
	input logic setFlag_n;
	output logic BrTaken;
	
	parameter B = 6'b000101;                  // 0x05;
	parameter BLT = 8'b01010100;              // 0x54 to choose B.cond
	parameter CBZ = 8'b10110100;              // 0xB4
	
	always_comb begin 
	   if (branchInstruction[31:26] == B) begin //unconditional branch always taken
			BrTaken = 1'b1;
		end else if (branchInstruction[31:24] == BLT && branchInstruction[4:0] == 5'b01011) begin
		   // if the saved setFlag signal is 1 then use the new flags,
			// otherwise used the old flags
			BrTaken = (setFlag_n & negative_new != overflow_new) | (~setFlag_n & negative != overflow);
		end else if (branchInstruction[31:24] == CBZ) begin
		   // use the accelerate branch(zero flag setted at reg/dec stage)
			BrTaken = zeroAccelerate;
		end else
   	   BrTaken = 1'b0;
		
	end

endmodule
