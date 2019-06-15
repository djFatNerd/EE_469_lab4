// 2:1 64bits mux

`timescale 1ns/10ps
module mux_19x2x1(out, A, B, sel);
	input logic  [18:0] A;
	input logic  [18:0] B;
	input logic  sel;
	
	output logic [18:0] out;
	
	genvar i;
	generate 
		for (i = 0 ; i < 19; i++) begin: eachBit
			mux_2x1 eachMux(out[i], {A[i], B[i]}, sel);
		end
	endgenerate
	
endmodule