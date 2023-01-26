`include "defines.vh"

/***********************************
 * CTL module
 **********************************/
module CTL(
	   clk,
	   reset,
	   start,
	   sram_ADDR,
	   sram_DI,
	   sram_EN,
	   sram_WE,
	   sram_DO,
	   opcode,
	   alu0,
	   alu1,
	   aluout_wire
	   );

   // inputs
   input clk;
   input reset;
   input start;
   input [31:0] sram_DO;
   input [31:0] aluout_wire;

   // outputs
   output [15:0] sram_ADDR;
   output [31:0] sram_DI;
   output 	 sram_EN;
   output 	 sram_WE;
   output [31:0] alu0;
   output [31:0] alu1;
   output [4:0]  opcode;

   // registers
   reg [31:0] 	 r2;
   reg [31:0] 	 r3;
   reg [31:0] 	 r4;
   reg [31:0] 	 r5;
   reg [31:0] 	 r6;
   reg [31:0] 	 r7;
   reg [15:0] 	 pc;
   reg [31:0] 	 inst;
   reg [4:0] 	 opcode;
   reg [2:0] 	 dst;
   reg [2:0] 	 src0;
   reg [2:0] 	 src1;
   reg [31:0] 	 alu0;
   reg [31:0] 	 alu1;
   reg [31:0] 	 aluout;
   reg [31:0] 	 immediate;
   reg [31:0] 	 cycle_counter;
   reg [2:0] 	 ctl_state;

   integer 	 verilog_trace_fp, rc;

   initial
     begin
	verilog_trace_fp = $fopen("verilog_trace.txt", "w");
     end

    // sram inputs (outputs from sp)
	reg [31:0] sram_DI;
	reg [15:0] sram_ADDR;
	reg sram_EN;
	reg sram_WE;
	reg sram_WE_prev;

	// DMA
	reg [2:0] dma_state;
	reg [2:0] dma_state_prev;
	reg [31:0] dma_src;
	reg [31:0] dma_dst;
	reg [31:0] dma_len;
	reg [31:0] dma_data;
	reg dma_start;
	reg dma_busy;
	reg mem_busy;

	wire dma_ready;

	assign dma_ready = dma_state_prev == `DMA_STATE_COPY && dma_state == `DMA_STATE_FETCH && ~mem_busy;


   // synchronous instructions
   always@(posedge clk)
     begin

		dma_state_prev <= dma_state;
		sram_WE_prev <= sram_WE;

		if (dma_ready) begin 
			dma_data = sram_DO;
		end

		if (dma_state_prev == `DMA_STATE_COPY && sram_ADDR == dma_dst) begin
			sram_WE <= 1;
		end

		if (~mem_busy && sram_WE)
			sram_WE <= 0;

		if (~sram_WE_prev && sram_WE) begin
			dma_dst <= dma_dst + 1;
			dma_src <= dma_src + 1;
			dma_len <= dma_len - 1;
		end

	if (reset) begin
	   // registers reset
	   r2 <= 0;
	   r3 <= 0;
	   r4 <= 0;
	   r5 <= 0;
	   r6 <= 0;
	   r7 <= 0;
	   pc <= 0;
	   inst <= 0;
	   opcode <= 0;
	   dst <= 0;
	   src0 <= 0;
	   src1 <= 0;
	   alu0 <= 0;
	   alu1 <= 0;
	   aluout <= 0;
	   immediate <= 0;
	   cycle_counter <= 0;
	   ctl_state <= 0;

	   dma_state <= 0;
	   dma_busy <= 0;
	   dma_src <= 0;
	   dma_dst <= 0;
	   dma_len <= 0;
	   mem_busy <= 0;
	   
	end else begin
	   // generate cycle trace
	   $fdisplay(verilog_trace_fp, "cycle %0d", cycle_counter);
	   $fdisplay(verilog_trace_fp, "r2 %08x", r2);
	   $fdisplay(verilog_trace_fp, "r3 %08x", r3);
	   $fdisplay(verilog_trace_fp, "r4 %08x", r4);
	   $fdisplay(verilog_trace_fp, "r5 %08x", r5);
	   $fdisplay(verilog_trace_fp, "r6 %08x", r6);
	   $fdisplay(verilog_trace_fp, "r7 %08x", r7);
	   $fdisplay(verilog_trace_fp, "pc %08x", pc);
	   $fdisplay(verilog_trace_fp, "inst %08x", inst);
	   $fdisplay(verilog_trace_fp, "opcode %08x", opcode);
	   $fdisplay(verilog_trace_fp, "dst %08x", dst);
	   $fdisplay(verilog_trace_fp, "src0 %08x", src0);
	   $fdisplay(verilog_trace_fp, "src1 %08x", src1);
	   $fdisplay(verilog_trace_fp, "immediate %08x", immediate);
	   $fdisplay(verilog_trace_fp, "alu0 %08x", alu0);
	   $fdisplay(verilog_trace_fp, "alu1 %08x", alu1);
	   $fdisplay(verilog_trace_fp, "aluout %08x", aluout);
	   $fdisplay(verilog_trace_fp, "cycle_counter %08x", cycle_counter);
	   $fdisplay(verilog_trace_fp, "ctl_state %08x\n", ctl_state);

	   cycle_counter <= cycle_counter + 1;

	   case (dma_state)
			`DMA_STATE_IDLE: begin
				if (dma_start) begin
					dma_busy <= 1;
					dma_state <= `DMA_STATE_FETCH;
				end
				else begin 
					dma_busy <= 0;
				end
			end	// DMA_STATE_IDLE
			`DMA_STATE_FETCH: begin
				if (~mem_busy) begin
					sram_EN <= 1;
					sram_WE <= 0;
					sram_DI <= 0;
					sram_ADDR <= dma_src[15:0];
					dma_state <= `DMA_STATE_COPY;
				end
				else dma_state <= `DMA_STATE_WAIT;
			end	// DMA_STATE_FETCH
			`DMA_STATE_WAIT: begin
				dma_state <= mem_busy ? `DMA_STATE_WAIT : `DMA_STATE_FETCH;
			end	// DMA_STATE_WAIT
			`DMA_STATE_COPY: begin
				sram_EN <= 1;
				// sram_WE <= dma_len > 0 ? 1 : 0;
				sram_DI <= dma_data;
				sram_ADDR <= dma_dst[15:0];

				// if (sram_WE && ~sram_WE_prev) begin
				// 	dma_dst <= dma_dst + 1;
				// 	dma_src <= dma_src + 1;
				// 	dma_len <= dma_len - 1;
				// end

				if (dma_len > 0) begin
					dma_state <= `DMA_STATE_FETCH;
				end
				else begin
					dma_state <= `DMA_STATE_IDLE;
					dma_start <= 0;
				end
			end	// DMA_STATE_COPY
	   endcase	// dma_state

	   case (ctl_state)
	     `CTL_STATE_IDLE: begin
                pc <= 0;
                if (start)
                  ctl_state <= `CTL_STATE_FETCH0;
             end
	     `CTL_STATE_FETCH0: begin
				mem_busy <= 1;
				ctl_state <= `CTL_STATE_FETCH1;
             end
	     `CTL_STATE_FETCH1: begin
				mem_busy <= 0;
                inst <= sram_DO;

				ctl_state <= `CTL_STATE_DEC0;
             end
	     `CTL_STATE_DEC0: begin
				mem_busy <= 0;
                {opcode, dst, src0, src1, immediate[15:0]} <= inst[29:0];
				immediate[31:16] <= {16{inst[15]}};		// sign extend immediate

				ctl_state <= `CTL_STATE_DEC1;
             end
	     `CTL_STATE_DEC1: begin
				mem_busy <= (opcode == `LD) ? 1 : 0;

				if (opcode == `CPY & ~dma_start) dma_start <= 1;

			// TODO: what about LHI command?
                case (src0)
					0: alu0 <= 0;
					1: alu0 <= immediate;
					2: alu0 <= r2;
					3: alu0 <= r3;
					4: alu0 <= r4;
					5: alu0 <= r5;
					6: alu0 <= r6;
					7: alu0 <= r7;
					default: alu0 <= 'bx;	// shouldn't get here
		 		endcase

                case (src1)
					0: alu1 <= 0;
					1: alu1 <= immediate;
					2: alu1 <= r2;
					3: alu1 <= r3;
					4: alu1 <= r4;
					5: alu1 <= r5;
					6: alu1 <= r6;
					7: alu1 <= r7;
					default: alu1 <= 'bx;	// shouldn't get here
		 		endcase

				ctl_state <= `CTL_STATE_EXEC0;
             end
	     `CTL_STATE_EXEC0: begin
				mem_busy <= (opcode == `LD | opcode == `ST) ? 1 : 0;

				case (opcode)
					`LD,
					`ST,
					`HLT: aluout <= aluout;			// nothing
					`CPY: begin
						dma_start <= 1;
						dma_src <= alu0;
						dma_len <= alu1;

						case (dst) 
							2: dma_dst <= r2;
							3: dma_dst <= r3;
							4: dma_dst <= r4;
							5: dma_dst <= r5;
							6: dma_dst <= r6;
							7: dma_dst <= r7;
						endcase
					end
					default: aluout <= aluout_wire;	// assign value calculated by ALU
				endcase

				ctl_state <= `CTL_STATE_EXEC1;
             end
	     `CTL_STATE_EXEC1: begin
				mem_busy <= 1;
				pc <= pc + 1;

                case (opcode)
					`ADD,
					`SUB,
					`LSF,
					`RSF,
					`AND,
					`OR,
					`XOR,
					`LHI:
						case (dst)
							2: r2 <= aluout_wire;
							3: r3 <= aluout_wire;
							4: r4 <= aluout_wire;
							5: r5 <= aluout_wire;
							6: r6 <= aluout_wire;
							7: r7 <= aluout_wire;
						endcase
					`JLT,
					`JLE,
					`JEQ,
					`JNE,
					`JIN:
						if (aluout) begin
							r7 <= pc;
							pc <= immediate;
						end
					`LD:
						case (dst)
							2: r2 <= sram_DO;
							3: r3 <= sram_DO;
							4: r4 <= sram_DO;
							5: r5 <= sram_DO;
							6: r6 <= sram_DO;
							7: r7 <= sram_DO;
						endcase
					`POL: begin
						case (dst)
							2: r2 <= dma_busy;
							3: r3 <= dma_busy;
							4: r4 <= dma_busy;
							5: r5 <= dma_busy;
							6: r6 <= dma_busy;
							7: r7 <= dma_busy;
						endcase
					end
					`HLT: begin
						ctl_state <= `CTL_STATE_IDLE;
						$fclose(verilog_trace_fp);
						$writememh("verilog_sram_out.txt", top.SP.SRAM.mem);
						$finish;
					end

				endcase

				ctl_state <= `CTL_STATE_FETCH0;
				
             end

			//  default: ctl_state <= `CTL_STATE_FETCH0;
	   endcase	// ctl_state


	end // !reset
     end // @posedge(clk)

	// SRAM ctl
	always @(ctl_state or sram_ADDR or sram_DI or sram_EN or sram_WE) begin

		case (ctl_state) 
			`CTL_STATE_FETCH0: begin	// read from SRAM at address PC
				sram_ADDR = pc;
				sram_WE = 0;
				sram_EN = 1;
			end
			`CTL_STATE_EXEC0: begin			// read from SRAM 
				if (opcode == `LD) begin
					sram_DI = 0;
					sram_ADDR = alu1[15:0];
					sram_WE = 0;
					sram_EN = 1;
				end
			end
			`CTL_STATE_EXEC1: begin			// write to SRAM
				if (opcode == `ST) begin
					sram_DI = alu0;
					sram_ADDR = alu1[15:0];
					sram_WE = 1;
					sram_EN = 1;
				end
			end

		endcase 	// ctl_state or sram_ADDR or sram_DI or sram_EN or sram_WE

	end


endmodule // CTL
