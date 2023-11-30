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
//---FLIPFLIP Module for Random-----------------------------------------------
module flipflop(q, clk, reset, d);
    input clk;
    input reset;
    input d;
    output q;
    reg q;
   
    always @(posedge clk, posedge reset)
     begin
        if(reset)
            q = 0;
        else q = d;
        $display("here 1");
    end
    
    specify
        $setup(d, clk, 2);
        $hold(clk, d, 0);
    endspecify
    
endmodule

//---MUX Module for Random----------------------------------------------------
module mux (q, control, a, b);
    output q;
    reg q;
    input control, a, b;
    wire notcontrol;
    
    always @(control or notcontrol or a or b) begin
        q = (control & a) |(notcontrol & b);
        $display("here 2"); end
    not (notcontrol, control);

endmodule

//---XOR Module-------------------------------------
module XOR (Y, A, B);
    output Y; 
    reg Y;
    input A,B;
    
    always @(A or B)
    begin
    if (A == 1'b0 & B == 1'b0) 
      Y = 1'b0; 
    if (A == 1'b1 & B == 1'b1) 
      Y = 1'b0;  
    else 
      Y = 1'b1;
      
     $display("here 3");
   end 
endmodule


//---Completed Random -------------------------------------------------------------
module lfsr(q, clk, rst, seed, load);
    output q;
    input [3:0] seed;
    input load;
    input rst;
    input clk;
    
    wire q;
    wire [3:0] state_out;
    wire [3:0] state_in;
    wire nextbit;
    
    flipflop F[3:0](state_out, state_in);
    mux M1[3:0](state_in, load, seed, {state_out[2], state_out[1], state_out[0], nextbit});
    XOR G1(nextbit, state_out[2], state_out[3]);
    assign q = nextbit;
    
    always @(q) $display("here 4: %b", q);

endmodule

//-----------------

module D_FF(input clk, reset, input load, D, output reg Q);
    always @ (posedge clk)
    begin
    if (reset) 
    begin Q <= 1'b0;
     $display("here5.1"); end
    else if(load) 
    begin Q <= D;
     $display("here5.2"); end
    $display("here5.3");

    end
endmodule

module puvvada_says_sm(Clk, SCEN, Reset, Start, ON, 
                       Btn_U, Btn_R, Btn_D, Btn_L, 
                       q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit,
                       score, level, gColor,b);
	/*  INPUTS */
	// Clock & Reset
	input	Clk, SCEN, Reset, Start;
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
    
    parameter zero = 4'b0000;
    wire [3:0] Q = 4'b0001;
    
   // D_FF D0(Clk, Reset, ON, Q[1], Q[0]);
   // D_FF D1(Clk, Reset, ON, Q[2], Q[1]);
   // D_FF D2(Clk, Reset, ON, Q[3], Q[2]);
   // D_FF D3(Clk, Reset, ON, ~(Q[3] ^ Q[2]),Q[3]);
    
//  lfsr C1[2:0](huh[0], Clk, Reset, 4'b0001, 1'b1);
//	lfsr C2[2:0](huh[1], Clk, Reset, 4'b0010, 1 );
//  lfsr C3[2:0](colors[8:6], Clk, Reset, 4'b0001, 1);
//	lfsr C4[2:0](colors[11:9], Clk, Reset, 4'b0001, 1);
//	lfsr C5[2:0](colors[14:12], Clk, Reset, 4'b0010, 0);
//	lfsr C6[2:0](colors[17:15], Clk, Reset, 4'b0100, 1);
//	lfsr C7[2:0](colors[20:18], Clk, Reset, 4'b0001, 1);
//  lfsr C8[2:0](colors[23:21], Clk, Reset, 4'b0001, 1);
//	lfsr C9[2:0](colors[26:24], Clk, Reset, 4'b0001, 1);
//	lfsr C10[2:0](colors[29:27], Clk, Reset, 4'b0001, 1);
	
	
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
						b_input <= 0;
						curr = 0;
						colors = 0;
						gColor <= 'd0;
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
						   colors[14:12] = 3; end
						
						else if (level == 6) begin
					       colors[2:0] = 2;
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
						   colors[8:6] = 3;
						   colors[11:9] = 1;
						   colors[14:12] = 1;   
						   colors[17:15] = 4;   
						   colors[20:18] = 2; 
						   colors[23:21] = 1; end
					   
					   else if (level == 9) begin
					       colors[2:0] = 2;
						   colors[5:3] = 3;
						   colors[8:6] = 1;
						   colors[11:9] = 1;
						   colors[14:12] = 4;   
						   colors[17:15] = 4;   
						   colors[20:18] = 3; 
						   colors[23:21] = 2; 
						   colors[26:24] = 4; end
						   
						else if (level == 10) begin
					       colors[2:0] = 3;
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