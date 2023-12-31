//////////////////////////////////////////////////////////////////////////////////
// Author:			Neftali Hernandez, Leslie Rodriguez
// Create Date:		11/23/2023
// File Name:		puvvada_says_top.v
// Description: 	Top file inlcudes input and output ports, local signals, clock division and SSD scanning logic, and Hex-to-SSD
//					conversion logic for the 4 SSDs
// Revision: 		
// Additional Comments: 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module puvvada_says_top (   
		MemOE, MemWR, RamCS, QuadSpiFlashCS, // Disable the three memory chips
        ClkPort,                           // the 100 MHz incoming clock signal
		BtnL, BtnR, BtnC, BtnU, BtnD, Sw0, Sw1, // the Left, Up, Down, and the Right buttons 
		Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs		
		An7, An6, An5, An4, An3, An2, An1, An0, // 8 anodes
		Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
		Dp,                                 // Dot Point Cathode on SSDs
		hSync, vSync, vgaR, vgaG, vgaB    //VGA Signals needed
	  );
    
    // VGA Signals declared as output in this module
    output hSync, vSync;
    output [3:0] vgaR, vgaG, vgaB;
    // VGA Local signals that will be used and passed in port list
    wire bright;
    wire [9:0] hc, vc;
    wire [11:0] rgb;
    wire [11:0] background;
    
    

	/*  INPUTS */
	// Clock & Reset I/O
	input ClkPort;	// the 100 MHZ incoming clock signal for the SSD Scanning 
	
	// make sure to add those to the ee354_numlock_top PORT list also!	
	input BtnL, BtnR, BtnU, BtnD, BtnC;
	input Sw0,Sw1;
	
	/*  OUTPUTS */
	// Control signals on Memory chips 	(to disable them)
	output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;
	// Project Specific Outputs
	// LEDs
	output 	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
	// SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	 An7, An6, An5, An4, An3, An2, An1, An0;
	
	
	/*  LOCAL SIGNALS */
	wire			Reset, ClkPort;
	wire			board_clk, sys_clk;
	wire [1:0]		ssdscan_clk;
	reg [26:0]	    DIV_CLK;
	
	wire 			Btn_L, Btn_R, Btn_U, Btn_C, Btn_D, ON, Start;
	wire 			q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit;
		
	reg [7:0]  		SSD_CATHODES;
	wire [3:0] SSD0, SSD1, SSD2, SSD3; // 7 bits for each SSD
	reg [3:0] SSD;
	reg [3:0] temp_level_ssd_tens, temp_level_ssd_ones; // 2 seperate signals to hold the tens and ones place of our decimal variable 'level'
    
	wire [6:0] level; //display on SSDs
    wire [8:0] score; //result of game displayed on VGA
    wire [3:0] gColor;
    wire [3:0] b;
//------------	
// Disable the three memories so that they do not interfere with the rest of the design.
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
//------------
// CLOCK DIVISION

	// The clock division circuitary works like this:
	//
	// ClkPort ---> [BUFGP2] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> DIV_CLK
	// DIV_CLK ---> [constant assignment] ---> sys_clk;
	
	BUFGP BUFGP1 (board_clk, ClkPort); 	

	// As the ClkPort signal travels throughout our design,
	// it is necessary to provide global routing to this signal. 
	// The BUFGPs buffer these input ports and connect them to the global 
	// routing resources in the FPGA.

	assign Reset = BtnC;
	
//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
	// TODO: create the sensitivity list
	always @ (posedge board_clk, posedge Reset)  
	begin : CLOCK_DIVIDER
      if (Reset)
			DIV_CLK <= 0;
      else
			// just incrementing makes our life easier
			// TODO: add the incrementer code
			DIV_CLK <= DIV_CLK + 1'b1;
	end		
//------------	
	// pick a divided clock bit to assign to system clock
	// your decision should not be "too fast" or you will not see you state machine working
	assign	sys_clk = DIV_CLK[25]; // DIV_CLK[25] (~1.5Hz) = (100MHz / 2**26)
	
	// Going to be used for VGA Module Instantiations per TA video
    wire move_clk;
	assign move_clk = DIV_CLK[19];
//------------
	// INPUT: SWITCHES & BUTTONS
	assign Btn_L = BtnL;
	assign Btn_R = BtnR;
	assign Btn_U = BtnU;
	assign Btn_D = BtnD;
	
	assign ON = Sw0;
	assign Start = Sw1; // Changed to Start = Sw1
		
//------------
	// DESIGN
	// Port List
	puvvada_says_sm SM1(.Clk(sys_clk),/*.Move_clk(move_clk),*/ 
	                            .Reset(Reset), 
								.Start(Start),
								.ON(ON), 
                                .Btn_U(Btn_U), 
                                .Btn_R(Btn_R), 
                                .Btn_D(Btn_D), 
                                .Btn_L(Btn_L), 
                                .q_Initial(q_Initial), 
                                .q_GetColor(q_GetColor), 
                                .q_UInput(q_UInput), 
                                .q_Compare(q_Compare), 
                                .q_Lost(q_Lost), 
                                .q_Exit(q_Exit), 
                                .score(score), 
                                .level(level),
								.gColor(gColor),
								.b(b)
								);		
								
	/*display_controller dc(.clk(sys_clk),
	                      .hSync(hSync),
	                      .vSync(vSync),
	                      .bright(bright),
	                      .hCount(hc),
	                      .vCount(vc));*/
	display_controller dc(.clk(sys_clk), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));
	block_controller sc(.clk(move_clk), .mastClk(sys_clk), .bright(bright), .rst(Reset), .hCount(hc), .vCount(vc), .rgb(rgb), .background(background));
	


	
	assign vgaR = rgb[11 : 8];
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];
								
//------------
// OUTPUT: LEDS
	
	assign {Ld7, Ld6, Ld5, Ld4} = {q_Initial, q_GetColor, q_UInput, q_Compare};
	assign {Ld3} = {q_Lost};
	assign {Ld2} = {BtnU}; // Reset is driven by BtnC, other buttons done ligt up
	//assign {Ld2} = {BtnU, BtnD,BtnL, BtnR}; // Reset is driven by BtnC
	assign {Ld1, Ld0} = {Sw1, Sw0};
							
//------------
	// SSD (Seven Segment Display)

	// Code to convert the decimal number stored in 'level' to 2 digit BCD which SSD needs
	// ******NOTE: I dont think this is correct ? - Nef **********
	//** Tried something - Les
	always @(*)
	begin
	   
		if (level < 10)
		begin 
			temp_level_ssd_ones = level; //converts the bit number to a real number then to integer
			temp_level_ssd_tens = 4'b0000; // For single digit value of level the tens place will be 0 (zero)
		end
		else
		begin
			temp_level_ssd_ones = level%10; //Getting ones digit
			temp_level_ssd_tens = level/10; // Getting tens digit
		end
		
	end
	// ******************************************************************
	
	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//
	
	assign ssdscan_clk = DIV_CLK[19:18];
	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	// TODO: inactivate the following four annodes
	assign {An7,An6,An5,An4} = 4'b1111;
	
	assign SSD0 = temp_level_ssd_ones;
	assign SSD1 = temp_level_ssd_tens;
	assign SSD2 = b; //Set SSD2 to display/remain 0
	assign SSD3 = gColor; //Set SSD3 to display/remain 0
	
	always @ (ssdscan_clk, temp_level_ssd_tens, temp_level_ssd_ones)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
		
			// TODO: finish the multiplexer to scan through SSD0-SSD3 with ssdscan_clk[1:0]
			2'b00: SSD = SSD0;
			2'b01: SSD = SSD1;
			2'b10: SSD = SSD2; //Set SSD2 to display/remain 0
			2'b11: SSD = SSD3; //Set SSD3 to display/remain 0
		endcase 
	end	
	
	// and finally convert SSD_num to ssd
	// We convert the output of our 4-bit 4x1 mux

	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};


	// Following is Hex-to-SSD conversion for SSD0
	always @ (SSD) 
	begin : HEX_TO_SSD0
		case (SSD) // We are doing SSD0[3:0] since we only want to look at the first 4 bits of SSD0 which will represent the numbers from 0-9. 
		// Cases for 0-9.  01_100_010
            4'b0000: SSD_CATHODES = 8'b00000011; // 0 //All last bits changed to 1 to turn off.
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9 Got these values from LAB 3 documentation Lab Report
            
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
endmodule


