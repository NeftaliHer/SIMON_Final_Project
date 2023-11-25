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
module puvvada_says_sm(Clk, Reset, Start, ON, Btn_U, Btn_R, Btn_D, Btn_L, q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit, score, level);
	/*  INPUTS */
	// Clock & Reset
	input	Clk, Reset, Start; // <--- What is start? Is it BtnC input?
	input   ON, Btn_U, Btn_R, Btn_D, Btn_L; //On is SW0
	
	
	/*  OUTPUTS */
	// store current state
	output reg [6:0] level; //display on SSDs 
	output reg [8:0] score; //result of game displayed on VGA
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
	reg [49:0] colors = 0;
	integer MAX = 49;
	
	
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
						if (Start && ON) state <= GET_COLOR;
						if (~ON) state <= EXIT;
						
						// data transfers
						score <= 8'h00; // <- Does this need to be a hex? Wouldnt it be easier to be a decimal?
						level <= 6'h01; // <- does level need to be a hex number? Can we make it a decimal instead?
						count = 1;
						b_input = 0;
						curr = 0;
						colors = 0;
						
						//VGA START SCREEN DSIPLAY 
					end	
					
					GET_COLOR:
					begin
						// state transfers
						if (~ON) state <= EXIT;
						else state <= U_INPUT;
						
						// data transfers
						for (i = 0; i < count; i=i+1)
						begin
							colors[i] = $urandom_range(1,4);
						end
						
						//VGA DSIPLAY COLORS
						//maybse use #100? for speed?
					end

					U_INPUT:
					begin
					    //UNPRESSED = (~Btn_U && ~Btn_R && ~Btn_D && ~Btn_L);
						// state transfers
						if (~ON) state <= EXIT;
						else if (b_input == 0) state <= U_INPUT;
						else if ((b_input != 0) && (~Btn_U && ~Btn_R && ~Btn_D && ~Btn_L)) state <= COMPARE; 
						
						// data transfers
						if (Btn_U) b_input = RED;
						else if (Btn_R) b_input = BLUE;
						else if (Btn_D) b_input = YELLOW;
						else if (Btn_L) b_input = GREEN;
						
					end	
					
					COMPARE:
					begin
						// state transfers
						if (~ON) state <= EXIT;
						else if ((b_input == colors[curr]) && (curr != count)) state <= U_INPUT;
						else if ((b_input == colors[count])) state <= GET_COLOR; // Question: We might need to add && Curr == Count here right? 
						else if ((b_input != colors[curr])) state <= LOST; 
						
						// data transfers
						if (b_input == colors[curr]) curr <= curr + 1;
						if (curr == count)
						begin
							if (count == MAX) count <= MAX;
							else count <= count + 1;
							score <= score + count;
							// Nef adding level<=level + 1 here too
							level <= level + 1;
							curr <= 0;
						end
					end
					
					LOST:
					begin
						// VGA DISPLAY END SCREEN
						// Message "Play Again?"
						if (Start && ON) state <= INITIAL;
						// Message "Done for Today?"
						if (~ON) state <= EXIT;
						
					end
					
					EXIT:
					begin
						// VGA Exit Display
						// Message "Did you sign attendance? Okay Bye."
					end
					
					default:		
						state <= UNK;
				endcase
	end
	
	//No OFL?
	
endmodule