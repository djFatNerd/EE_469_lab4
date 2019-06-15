module forwardingUnit(forwardRd1, forwardRd2, Rn, RdorRm, forwardRegWrite1, forwardRegWrite2, ForwardA, ForwardB);
// keep track of Rd 2 cycle will need for forwarding [if destination is current Aa/Ab]
// keep track of regWrite 2 cycle will need for forwarding [regWrite needs to be 1 to write]   
   input logic [4:0] forwardRd1, forwardRd2, Rn, RdorRm;
	input logic forwardRegWrite1, forwardRegWrite2;
	output logic [1:0] ForwardA, ForwardB;
	
	always_comb begin
	   if((Rn != 5'b11111) & (forwardRd1 == Rn) & forwardRegWrite1)  begin // forward from exec(last cycle)
		   ForwardA = 2'b01;
		end else if ((Rn != 5'b11111) & (forwardRd2 == Rn) & forwardRegWrite2) begin // forward from mem(2 cycles ago)
		   ForwardA = 2'b10;
		end else begin
		   ForwardA = 2'b00; // no forwarding
			
		end
		

		if((RdorRm != 5'b11111) & (forwardRd1 == RdorRm) & forwardRegWrite1)  begin // forward from exec
		   ForwardB = 2'b01;
		end else if ((RdorRm != 5'b11111) & (forwardRd2 == RdorRm) & forwardRegWrite2) begin // forward from mem
		   ForwardB = 2'b10;
		end else begin
		   ForwardB = 2'b00; // no forwarding
			
		end
	
	end
	

endmodule