`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author:			Leslie Rodriguez, Neftali Hernandez
// Create Date:   	11/16/2023, 
// Revised: 
// File Name:		puvvada_says_sm.v 
// Description: 
//
//
// Revision: 		1.1
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module puvvada_says_sm(Clk, /*Move_clk,*/ Reset, Start, ON, Btn_U, Btn_R, Btn_D, Btn_L, q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit, score, level, gColor, b /*hSync, vSync, vgaR, vgaG, vgaB*/);
	/*  INPUTS */
	// Clock & Reset
	input	Clk, Reset, Start/*, Move_clk*/;
	input   ON, Btn_U, Btn_R, Btn_D, Btn_L; //On is SW0
	
	/*
	// VGA Signals
	output hSync, vSync;
	output [3:0] vgaR, vgaG, vgaB;
	// VGA Local signals that will be used and passed in port list
    wire bright;
    wire [9:0] hc, vc;
    wire [11:0] rgb;
    wire [11:0] background;
    assign vgaR = rgb[11 : 8];
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];
	
	
	
	// VGA Port List
	display_controller dc(.clk(sys_clk),
	                      .hSync(hSync),
	                      .vSync(vSync),
	                      .bright(bright),
	                      .hCount(hc),
	                      .vCount(vc));
	
	block_controller bc(.clk(Move_clk), 
	                    .mastClk(sys_clk), 
	                    .bright(bright), 
	                    .rst(Reset),
	                    .hCount(hc),
	                    .vCount(vc),
	                    .rgb(rgb),
	                    .background(background));
	                    
	*/
	
/*  OUTPUTS */
	// store current state
	output reg [6:0] level; //display on SSDs
	output reg [8:0] score; //result of game displayed on VGA
	output reg [3:0] gColor;
	output reg [3:0] b;
	output q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit;
	reg [5:0] state; //6 states

	
	//reg[3:0] Timerout_count;
	//wire Timerout;
	
	assign {q_Exit, q_Lost, q_Compare, q_UInput, q_GetColor, q_Initial} = state;
	
	localparam
	    INITIAL		=   6'b000001,
	    GET_COLOR 	=   6'b000010,
	    U_INPUT		=   6'b000100,
	    COMPARE		=   6'b001000,
	    LOST		=   6'b010000,
	    EXIT		=   6'b100000,
	    UNK			=   6'bXXXXXX;
	
	
	// NSL AND SM
	integer RED = 1;
	integer BLUE = 2;
	integer YELLOW = 3;
	integer GREEN = 4;
	integer count, b_input, curr,i;
	reg [29:0] colors;
	integer MAX = 9;
    reg [2:0] the_color;
	
	
	always @ (posedge Clk, posedge Reset)
	begin : start_Game
		if(Reset) 
		  begin
			if(ON)
			state <= INITIAL;
		  end
		else				
				case(state)	
					INITIAL:
					begin
						// state transfers
					    if (~ON) state <= EXIT;
						if(Start && ON) state <= GET_COLOR;
						
						// data transfers
						score <= 8'h00;
						level <= 6'h01;
						count = 1;
						b_input = 0;
						curr = 0;
						colors = 0;
						gColor <= 4'b0000;
						
						//VGA START SCREEN DSIPLAY 
					end	
					
					GET_COLOR:
					begin
						// state transfers
						if (~ON) state <= EXIT;
						else state <= U_INPUT;
		
					
						// generates a 29 bit long number that is equivalent to 10 rounds (spereated by 3 bits)
					    colors[2:0] = 1;
						colors[5:3] = 2;
						colors[8:6] = 3;
						colors[11:9] = 4;
						colors[14:12] = 1;
						colors[17:15] = 2;
						colors[20:18] = 3;
						colors[23:21] = 4;
						colors[26:24] = 1;
						colors[29:27] = 2;
						//end
						
						//VGA DSIPLAY COLORS
						//maybse use #100? for speed?
					end

					U_INPUT:
					begin
						the_color[0] = colors[curr];
					    the_color[1] = colors[curr+1];
					    the_color[2] = colors[curr+2];
					    gColor <= the_color;
					    
						// state transfers
						if (~ON) state <= EXIT;
						else if (b_input == 0) state <= U_INPUT;
						else if ((b_input != 0) && (~Btn_U && ~Btn_R && ~Btn_D && ~Btn_L)) state <= COMPARE; 
						
						// data transfers
						if (Btn_U) b_input <= RED;
						else if (Btn_R) b_input <= BLUE;
						else if (Btn_D) b_input <= YELLOW;
						else if (Btn_L) b_input <= GREEN;
						
						b <= b_input;
						
					end	
					
					COMPARE:
					begin
					   $display("COMPARE");

					    //takes a portion of the large number "colors" and sections it by 3 bits to result in a 1-4 choice. 
					    //the_color[0] = colors[curr];
					    //the_color[1] = colors[curr+1];
					    //the_color[2] = colors[curr+2];					    
					    
						// state transfers
						if (~ON) state <= EXIT;
						else if ((b_input == the_color) && (level != count)) state <= U_INPUT;
						else if ((b_input == the_color) && (level == count)) state <= GET_COLOR; 
						else if ((b_input != the_color)) state <= LOST; 
						
						//got the current color correct, will go back to u-input for next
						if (b_input == the_color) 
						begin
						  //got the last color correct
						  if (level == count)
						  begin
							 if (count == MAX) count <= MAX;
							 else 
							 count <= 1;
							 score <= score + level;
							 curr <= 0;
							 level <= level +1;
						  end
						  else
						  begin
						      curr <= curr + 3;
						      count <= count + 1;
						  end
						  b_input <= 0;
						end
					end
					
					LOST:
					begin
						// VGA DISPLAY END SCREEN
						// Message "Play Again?
						if (Start && ON) state <= INITIAL;
						// Message "Done for Today?"
						if (~ON) state <= EXIT;
						
						
					end
					
					EXIT:
					begin
						// VGA Exit Display
						// Message "Did you sign attendance? Okay Bye."
						if (Start && ON) state <= INITIAL;
						score <= 8'h00;
						level <= 6'h00;
					end
					
					default:		
						state <= UNK;
				endcase
	end
	
	//No OFL?
	
endmodule