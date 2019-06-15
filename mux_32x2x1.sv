
`timescale 1ns/10ps
module mux_32x2x1(out, A, B, sel);
	input logic  [31:0] A;
	input logic  [31:0] B;
	input logic  sel;
	
	output logic [31:0] out;
	
	genvar i;
	generate 
		for (i = 0 ; i < 32; i++) begin: eachBit
			mux_2x1 eachMux(out[i], {A[i], B[i]}, sel);
		end
	endgenerate
	
endmodule