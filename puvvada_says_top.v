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
		Dp                                 // Dot Point Cathode on SSDs
	  );


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
		
	reg [6:0]  		SSD_CATHODES;
	reg [6:0] SSD0, SSD1, SSD2, SSD3; // 7 bits for each SSD
	integer temp_level_ssd_tens, temp_level_ssd_ones, temp; // 2 seperate signals to hold the tens and ones place of our decimal variable 'level'
    
	wire [6:0] level; //display on SSDs
    wire [8:0] score; //result of game displayed on VGA
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
	puvvada_says_sm SM1(.Clk(sys_clk), .Reset(Reset), 
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
                                .level(level)
								);		
								
//------------
// OUTPUT: LEDS
	
	assign {Ld7, Ld6, Ld5, Ld4} = {q_Initial, q_GetColor, q_UInput, q_Compare};
	assign {Ld3} = {q_Lost};
	assign {Ld2} = {BtnU, BtnD,BtnL, BtnR}; // Reset is driven by BtnC
	assign {Ld1, Ld0} = {Sw1, Sw0};
							
//------------
	// SSD (Seven Segment Display)

	// Code to convert the decimal number stored in 'level' to 2 digit BCD which SSD needs
	// ******NOTE: I dont think this is correct ? - Nef **********
	always @(*)
	begin
	    temp = level;
	   
		if (level < 10)
		begin 
			temp_level_ssd_ones = 1'd2; //converts the bit number to a real number then to integer
			temp_level_ssd_tens = 1'd0; // For single digit value of level the tens place will be 0 (zero)
		end
		else
		begin
			temp_level_ssd_ones =  temp[0]; //Getting ones digit
			temp_level_ssd_tens =  temp[1]; // Getting tens digit
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
	
	always @ (ssdscan_clk, temp_level_ssd_tens, temp_level_ssd_ones)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
		
			// TODO: finish the multiplexer to scan through SSD0-SSD3 with ssdscan_clk[1:0]
			2'b00: SSD0 = {temp_level_ssd_ones};
			2'b01: SSD1 = {temp_level_ssd_tens};
			2'b10: SSD2 = 1'd6; //Set SSD2 to display/remain 0
			2'b11: SSD3 = 1'd8; //Set SSD3 to display/remain 0
		endcase 
	end	
	
	// and finally convert SSD_num to ssd
	// We convert the output of our 4-bit 4x1 mux

	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};


	// Following is Hex-to-SSD conversion for SSD0
	always @ (SSD0) 
	begin : HEX_TO_SSD0
		case (SSD0) // We are doing SSD0[3:0] since we only want to look at the first 4 bits of SSD0 which will represent the numbers from 0-9. 
		// Cases for 0-9.  
            1'd0: SSD_CATHODES = 8'b00000011; // 0 //All last bits changed to 1 to turn off.
			1'd1: SSD_CATHODES = 8'b10011111; // 1
			1'd2: SSD_CATHODES = 8'b00100101; // 2
			1'd3: SSD_CATHODES = 8'b00001101; // 3
			1'd4: SSD_CATHODES = 8'b10011001; // 4
			1'd5: SSD_CATHODES = 8'b01001001; // 5
			1'd6: SSD_CATHODES = 8'b01000001; // 6
			1'd7: SSD_CATHODES = 8'b00011111; // 7
			1'd8: SSD_CATHODES = 8'b00000001; // 8
			1'd9: SSD_CATHODES = 8'b00001001; // 9 Got these values from LAB 3 documentation Lab Report
            
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	// Following is Hex-to-SSD conversion for SSD1
	//always @ (SSD1) 
	//begin : HEX_TO_SSD1
		//case (SSD1) // We are doing SSD1[3:0] since we only want to look at the first 4 bits of SSD0 which will represent the numbers from 0-9.  
		// Cases for 0-9.  
            //1'd0: SSD_CATHODES = 8'b00000011; // 0 //All last bits changed to 1 to turn off.
			//1'd1: SSD_CATHODES = 8'b10011111; // 1
			//1'd2: SSD_CATHODES = 8'b00100101; // 2
			//1'd3: SSD_CATHODES = 8'b00001101; // 3
			//1'd4: SSD_CATHODES = 8'b10011001; // 4
			//1'd5: SSD_CATHODES = 8'b01001001; // 5
			//1'd6: SSD_CATHODES = 8'b01000001; // 6
			//1'd7: SSD_CATHODES = 8'b00011111; // 7
			//1'd8: SSD_CATHODES = 8'b00000001; // 8
			//1'd9: SSD_CATHODES = 8'b00001001; // 9 Got these values from LAB 3 documentation Lab Report
            
			//default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		//endcase
	//end	
	
	// Following is Hex-to-SSD conversion for SSD2
	//always @ (SSD2) 
	//begin : HEX_TO_SSD2
	//	case (SSD2)
			// Cases for 0 since SSD2 will always be 0  
    //        4'b0000: SSD_CATHODES = 8'b01000001; // 0
	//		default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
	//	endcase
	//end	
	
	// Following is Hex-to-SSD conversion for SSD3
	//always @ (SSD3) 
	//begin : HEX_TO_SSD3
	//	case (SSD3)
			// Cases for 0 since SSD3 will always be 0  
   //         4'b0000: SSD_CATHODES = 8'b00011111; // 0
  //		default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
	//	endcase
	//end	
	
endmodule


