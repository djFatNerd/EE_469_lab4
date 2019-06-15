`timescale 1ns/10ps

// this file includes all the D flip flops used for 
// the pipeline cpu in order to delay the stage from
// single cycle cpu

// naming: the first number represents the number of the bits
//         the second number represents the number of cycle
// for example: DFF5_x3 is the 5-bits DFF going through 3 cycles
module DFF5_x3 (q, d, rst, clk);
	output logic [4:0] q;
	input logic [4:0] d;
	input logic clk, rst;
	logic [4:0] q_1, q_2;
	
	DFF5 cycle1 (q_1, d, rst,clk);
	DFF5 cycle2 (q_2, q_1, rst,clk);
	DFF5 cycle3 (q, q_2, rst, clk);	
endmodule 


module DFF5_x2 (q, d, rst, clk);
	output logic [4:0] q;
	input logic [4:0] d;
	input logic clk, rst;
	logic [4:0] q_1;
	
	DFF5 cycle1 (q_1, d, rst,clk);
	DFF5 cycle2 (q, q_1, rst,clk);
	
endmodule 

module DFF1_x2 (q, d, rst, clk);
	output logic q;
	input logic d;
	input logic clk, rst;
	logic q_1;
	
	D_FF cycle1 (q_1, d, rst,clk);
	D_FF cycle2 (q, q_1, rst,clk);
	
endmodule 

module DFF3_x2 (q, d, rst, clk);
	output logic [2:0] q;
	input logic [2:0] d;
	input logic clk, rst;
	logic [2:0] q_1;
	
	DFF3 cycle1 (q_1, d, rst,clk);
	DFF3 cycle2 (q, q_1, rst,clk);
	
endmodule 

module DFF1_x3 (q, d, rst, clk);
	output logic q;
	input logic d;
	input logic clk, rst;
	logic q_1, q_2;
	
	D_FF cycle1 (q_1, d, rst,clk);
	D_FF cycle2 (q_2, q_1, rst,clk);
	D_FF cycle3 (q, q_2, rst,clk);
	
endmodule 

module DFF4_x3 (q, d, rst, clk);
	output logic [3:0] q;
	input logic [3:0] d;
	input logic clk, rst;
	logic [3:0] q_1, q_2;
	
	DFF4 cycle1 (q_1, d, rst,clk);
	DFF4 cycle2 (q_2, q_1, rst,clk);
	DFF4 cycle3 (q, q_2, rst,clk);
	
endmodule

module DFF6_x2 (q, d, rst, clk);
	output logic [5:0] q;
	input logic [5:0] d;
	input logic clk, rst;
	logic [5:0] q_1;
	
	DFF6 cycle1 (q_1, d, rst,clk);
	DFF6 cycle2 (q, q_1, rst,clk);
	
endmodule 

module DFF2_x3 (q, d, rst, clk);
	output logic [1:0] q;
	input logic [1:0] d;
	input logic clk, rst;
	logic [1:0] q_1, q_2;
	
	DFF2 cycle1 (q_1, d, rst,clk);
	DFF2 cycle2 (q_2, q_1, rst,clk);
	DFF2 cycle3 (q, q_2, rst,clk);
	
endmodule 

module DFF2 (q, d, rst, clk);
	output logic [1:0] q;
	input logic [1:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 2; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate
	
endmodule

module DFF3 (q, d, rst, clk);
	output logic [2:0] q;
	input logic [2:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 3; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate
	
endmodule

module DFF19 (q, d, rst, clk);
	output logic [18:0] q;
	input logic [18:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 19; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate
	
endmodule

module DFF26 (q, d, rst, clk);
	output logic [25:0] q;
	input logic [25:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 26; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate
	
endmodule

module DFF4 (q, d, rst, clk);
	output logic [3:0] q;
	input logic [3:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 4; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate
	
endmodule

module DFF5 (q, d, rst, clk);
	output logic [4:0] q;
	input logic [4:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 5; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate
	
endmodule

module DFF6 (q, d, rst, clk);
	output logic [5:0] q;
	input logic [5:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 6; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate
	
endmodule

module DFF12 (q, d, rst, clk);
	output logic [11:0] q;
	input logic [11:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 12; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate

endmodule

module DFF9 (q, d, rst, clk);
	output logic [8:0] q;
	input logic [8:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 9; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate

endmodule

module DFF64 (q, d, rst, clk);
	output logic [63:0] q;
	input logic [63:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 64; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate

endmodule

module DFF32 (q, d, rst, clk);
	output logic [31:0] q;
	input logic [31:0] d;
	input logic clk, rst;
	
	genvar i;
	
	generate
		for(i=0; i < 32; i++) begin: eachDff
			D_FF dffs(q[i], d[i], rst, clk);
		end
	endgenerate

endmodule


