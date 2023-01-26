// control states
`define CTL_STATE_IDLE 0
`define CTL_STATE_FETCH0 1
`define CTL_STATE_FETCH1 2
`define CTL_STATE_DEC0 3
`define CTL_STATE_DEC1 4
`define CTL_STATE_EXEC0 5
`define CTL_STATE_EXEC1 6

// DMA states
`define DMA_STATE_IDLE		0
`define DMA_STATE_FETCH		1
`define DMA_STATE_WAIT	    2
`define DMA_STATE_COPY		3


// opcodes
`define ADD 0
`define SUB 1
`define LSF 2
`define RSF 3
`define AND 4
`define OR 5
`define XOR 6
`define LHI 7
`define LD 8
`define ST 9
`define CPY 10
`define POL 11
`define JLT 16
`define JLE 17
`define JEQ 18
`define JNE 19
`define JIN 20
`define HLT 24
