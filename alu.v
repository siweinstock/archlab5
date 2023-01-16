`include "defines.vh"

/***********************************
 * ALU module
 **********************************/
module ALU(opcode, alu0, alu1, aluout);
   
   input [4:0] opcode;
   input [31:0] alu0, alu1;
   output [31:0] aluout;
   reg [31:0] 	 aluout;

   always@(alu0 or alu1 or opcode)
     begin
	case (opcode)
	  `ADD: aluout = alu0 + alu1;
	  `SUB: aluout = alu0 - alu1;
       `LSF: aluout = alu0 << alu1;
	  `RSF: aluout = alu0 >>> alu1;
	  `AND: aluout = alu0 & alu1;
	  `OR: aluout = alu0 | alu1;
       `XOR: aluout = alu0 ^ alu1;
	  `LHI: aluout = alu0[15:0] | (alu1 << 16);
	  `JLT: aluout = (alu0 < alu1) ? 1 : 0;
	  `JLE: aluout = (alu0 <= alu1) ? 1 : 0;
       `JEQ: aluout = (alu0 == alu1) ? 1 : 0;
	  `JNE: aluout = (alu0 != alu1) ? 1 : 0;
       `JIN: aluout = 1;
	endcase
     end
endmodule // alu
