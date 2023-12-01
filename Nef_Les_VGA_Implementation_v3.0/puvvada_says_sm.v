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


module puvvada_says_sm(Clk, Reset, Start, ON, 
                       Btn_U, Btn_R, Btn_D, Btn_L, 
                       q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit,
                       score, level, gColor,b);
	/*  INPUTS */
	// Clock & Reset
	input	Clk, Reset, Start;
	input   ON, Btn_U, Btn_R, Btn_D, Btn_L; //On is SW0
	
	
	/*  OUTPUTS */
	// store current state
	output reg [6:0] level; //display on SSDs
	output reg [8:0] score; //result of game displayed on VGA
	output reg [3:0] gColor;
	output reg [3:0] b;
	output q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit;
	reg [5:0] state; //6 states
	
	
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
			gColor <= 0; // This '0' will trigger the basic board display on the screen in block_controller.v
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
						b_input <= 0;
						curr = 0;
						colors = 0;
						//gColor <= 'd0;
						gColor <= 7; // 7 for the start screen with puvvada
						//$display("Q: %b", Q);
						
						//VGA START SCREEN DSIPLAY 
					end	
					
					GET_COLOR:
					begin
						// state transfers
						if (~ON) state <= EXIT;
						else if(count > level)  state <= U_INPUT;
						else state <= GET_COLOR;
					
						// generates a 29 bit long number that is equivalent to 10 rounds (spereated by 3 bits)
					    if (level == 1)
					       colors[2:0] = 1;
					       
					    else if (level == 2) begin
					       colors[2:0] = 4;
						   colors[5:3] = 3; end
						   
						else if (level == 3) begin
					       colors[2:0] = 1;
						   colors[5:3] = 2;
						   colors[8:6] = 1; end
						   
						else if (level == 4) begin
					       colors[2:0] = 4;
						   colors[5:3] = 2;
						   colors[8:6] = 3;
						   colors[11:9] = 1; end
					    
					    else if (level == 5) begin
					       colors[2:0] = 1;
						   colors[5:3] = 4;
						   colors[8:6] = 2;
						   colors[11:9] = 3;
						   colors[14:12] = 2; end
						
						else if (level == 6) begin
					       colors[2:0] = 1;
						   colors[5:3] = 2;
						   colors[8:6] = 3;
						   colors[11:9] = 1;
						   colors[14:12] = 3;   
						   colors[17:15] = 4; end
						   
						else if (level == 7) begin
					       colors[2:0] = 1;
						   colors[5:3] = 2;
						   colors[8:6] = 4;
						   colors[11:9] = 1;
						   colors[14:12] = 2;   
						   colors[17:15] = 4;   
						   colors[20:18] = 2; end
						   
						else if (level == 8) begin
					       colors[2:0] = 4;
						   colors[5:3] = 3;
						   colors[8:6] = 2;
						   colors[11:9] = 1;
						   colors[14:12] = 2;   
						   colors[17:15] = 4;   
						   colors[20:18] = 2; 
						   colors[23:21] = 1; end
					   
					   else if (level == 9) begin
					       colors[2:0] = 2;
						   colors[5:3] = 3;
						   colors[8:6] = 1;
						   colors[11:9] = 3;
						   colors[14:12] = 2;   
						   colors[17:15] = 4;   
						   colors[20:18] = 3; 
						   colors[23:21] = 2; 
						   colors[26:24] = 4; end
						   
						else if (level == 10) begin
					       colors[2:0] = 1;
						   colors[5:3] = 3;
						   colors[8:6] = 4;
						   colors[11:9] = 1;
						   colors[14:12] = 2;   
						   colors[17:15] = 4;   
						   colors[20:18] = 3; 
						   colors[23:21] = 1; 
						   colors[26:24] = 4;
						   colors[29:27] = 1; end
						//end
						
						//Display Sequence
						the_color[0] = colors[curr];
					    the_color[1] = colors[curr+1];
					    the_color[2] = colors[curr+2];
					    gColor <= the_color;
					    if(count > level)  begin
					       count <= 1;
					       gColor <= 0;
					       curr <= 0;
					       end
					    else begin
					       count <= count +1;
					       curr <= curr + 3;
					      end
						
						
					end

					U_INPUT:
					//if(SCEN)
					begin
					    
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
					    //takes a portion of the large number "colors" and sections it by 3 bits to result in a 1-4 choice. 
					    the_color[0] = colors[curr];
					    the_color[1] = colors[curr+1];
					    the_color[2] = colors[curr+2];					    
					    
						// state transfers
						if (~ON) state <= EXIT;
						else if ((b_input == the_color) && (level != count)) state <= U_INPUT;
						else if ((b_input == the_color) && (level == count)) state <= GET_COLOR; 
						else if ((b_input != the_color)) 
						begin
						state <= LOST; 
						gColor <= 5;                                                                                                                                                                                             
						end
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
						  
						end
				        b_input <= 0;
				        b <= 0; 
					end
					
					LOST:
					begin
						// VGA DISPLAY END SCREEN
						// Message "Play Again?
						if (~Start && ON) state <= INITIAL;
						// Message "Done for Today?"
						if (~ON) state <= EXIT;
						
					end
					
					EXIT:
					begin
						// VGA Exit Display
						// Message "Did you sign attendance? Okay Bye."
						if (~Start && ON) state <= INITIAL;
						score <= 8'h00;
						level <= 6'h00;
					end
					
					default:		
						state <= UNK;
				endcase
	end
	
	//No OFL?
	
endmodule