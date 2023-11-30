//puvvada says test bench
//////////////////////////////////////////////////////////////////////////////////
// Author:		  Leslie Rodriguez and Neftali 
// Create Date:   11/22/23
// File Name:	  puvvada_says_tb.v 
// Description:   Final Project
//
//
// Revision: 		1.1
// Additional Comments:  
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module puvvada_says_tb_v;

	// Inputs
	reg Clk;
	reg Reset;
	reg Start;
	reg ON; //Btn_C
	reg Btn_U, Btn_R, Btn_D, Btn_L;

	// Outputs
	wire [6:0] level;
	wire [8:0] score;
	wire q_Initial;
	wire q_GetColor;
	wire q_UInput;
	wire q_Compare;
	wire q_Lost;
	wire q_Exit;
	reg [6*8:0] state_string; // 6-character string for symbolic display of state
	
	
	// Instantiate the Unit Under Test (UUT)
	puvvada_says_sm uut (
		.Clk(Clk), 
		.Reset(Reset), 
		.Start(Start), 
		.ON(ON), 
		.Btn_U(Btn_U), 
		.Btn_R(Btn_R), 
		.Btn_D(Btn_D), 
		.Btn_L(Btn_L), 
		.level(level),
		.score(score), 
		.q_Initial(q_Initial), 
		.q_GetColor(q_GetColor), 
		.q_UInput(q_UInput), 
		.q_Compare(q_Compare), 
		.q_Lost(q_Lost), 
		.q_Exit(q_Exit)
	);
	
	initial 
		  begin
			Clk = 0; // Initialize clock
		  end
		  
	always  begin #10; Clk = ~ Clk; end

	initial 
	begin
		// Initialize Inputs

		Clk = 0;
		Reset = 0;
		Start = 0;
		ON = 0;
		Btn_U = 0;
		Btn_R = 0;
		Btn_D = 0;
		Btn_L = 0;
		
		// Wait 100 ns for global reset to finish
		#100;
		Reset = 1;
		ON = 1;
		#10;		
		Reset = 0;
		#10;
		
		//Inital State
		Start = 1;
		//Figure out waiting time for Get Color State
		#100
		
		//PUT 4 options of colors 2 times hoping for the best against the game haha
		//U_Input option 1
		Btn_U = 1;
		#50  //slow press
		Btn_U = 0;
		//Figure "exact" out waiting time for Compare State but works for now
		#100
		
		//U_Input option 2
		Btn_R = 1;
		#50
		Btn_R = 0;
		#100
		
		//U_Input option 3
		Btn_L = 1;
		#50
		Btn_L = 0;
		#100
		
		//U_Input option 4
		Btn_D = 1;
		#50
		Btn_D = 0;
		#100
		
		//--------------------------------
		//U_Input option 1
		Btn_U = 1;
		#25  //fast press
		Btn_U = 0;
		#100
		
		//U_Input option 2
		Btn_R = 1;
		#25
		Btn_R = 0;
		#100
		
		//U_Input option 3
		Btn_L = 1;
		#25
		Btn_L = 0;
		#100
		
		//U_Input option 4
		Btn_D = 1;
		#25
		Btn_D = 0;
		#100
		
		//Compare state and Lost or Note
		
		ON = 0;
		#100
		
		$finish;
		
	end
	
	always @(*)
		begin
			case ({q_Initial, q_GetColor, q_UInput, q_Compare, q_Lost, q_Exit})    // Note the concatenation operator {}
				6'b000001: state_string = q_Initial;  
				6'b000010: state_string = q_GetColor;       
				6'b000100: state_string = q_UInput;
				6'b001000: state_string = q_Compare;
				6'b010000: state_string = q_Lost;
				6'b100000: state_string = q_Exit;

			endcase
			
		end
 
      
endmodule
		
		
		