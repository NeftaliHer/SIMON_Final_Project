`timescale 1ns / 1ps

module block_controller(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input mastClk,
	input btnu,
	input btnr,
	input btnd,
	input btnl,
	input [3:0] gColorNum, //has to be 4 bits
	input bright,
	input rst,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background
   );
	wire block_fill;
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg [9:0] xpos, ypos;
	
	parameter RED   = 12'b1111_0000_0000;
	//Will hold the color from the bitrom file
	wire [11:0] puvvadaBasicBoard; 
	wire [11:0] oneRedColor;
	wire [11:0] twoBlueColor;
	wire [11:0] threeYellowColor;
	wire [11:0] fourGreenColor;
	wire [11:0] startScreen;
	wire [11:0] loseScreen;
	
	// Code to link the image rom bit files to VGA. All images are 115x115 pixels converted to BMP
	gameBoard_rom boardScreen(.clk(mastClk),.row(vCount), .col(hCount), .color_data(puvvadaBasicBoard));
	red_new_rom red(.clk(mastClk),.row(vCount), .col(hCount), .color_data(oneRedColor));
	blue_new_rom blue(.clk(mastClk),.row(vCount), .col(hCount), .color_data(twoBlueColor));
	yellow_new_rom yellow(.clk(mastClk),.row(vCount), .col(hCount), .color_data(threeYellowColor));
	green_new_rom green(.clk(mastClk),.row(vCount), .col(hCount), .color_data(fourGreenColor));
    getStarted_rom getStartedScreen(.clk(mastClk),.row(vCount), .col(hCount), .color_data(startScreen));
    puvvada_youlose_small_rom lostScreen(.clk(mastClk),.row(vCount), .col(hCount), .color_data(loseScreen));
    

	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000; //If the screen has other pixels outside of 640x480 then forcing them to be black
		else if(block_fill && gColorNum==0)
		  rgb = puvvadaBasicBoard; // Will display the basic SIMON Game board
		else if (block_fill && gColorNum == 7) //gColorNum=7 shows us in Initial state meaning Sw0 on waiting for Sw1 to display the colors above
		  rgb = startScreen; // Puvvada Lets get started screen
		else if (block_fill && gColorNum == 1)
		  rgb = oneRedColor;
		else if (block_fill && gColorNum == 2)
		  rgb = twoBlueColor;
		  //rgb = 12'b0000_0001_1111; //Blue screen used for testing
		else if (block_fill && gColorNum == 3)
		  rgb = threeYellowColor;
		  //rgb = 12'b1111_1111_0000; //Yellow screen used for testing
		else if (block_fill && gColorNum == 4)
		  rgb = fourGreenColor;
		  //rgb = 12'b0000_1111_0000; //Green color used for testing
		else if (block_fill && gColorNum == 5) //gColorNum = 5 represents the YOU LOSE state image
		  rgb = loseScreen;
		  //rgb = 12'b1010_1010_1010;
		else
		  rgb = background; // we are updating rgb value down below. The background color is changing
		                    // to match our button presses and the color of the background correlates with the corresponding button
	end
	// block_fill was a 640x480 grid starting at the top left corner and goes to the bottom right.
	//assign block_fill=vCount>=(ypos) && vCount<=(ypos+550) && hCount>=(xpos+1) && hCount<=(xpos-700);
	//assign block_fill=vCount>=(ypos) && vCount<=(ypos+550) && hCount>=(xpos+1) && hCount<=(xpos-700);
	assign block_fill=vCount>=(ypos-125) && vCount<=(ypos+125) && hCount>=(xpos-200) && hCount<=(xpos+180);

	
	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			xpos<=450;//200; //143 good //test 43
			ypos<=250;//100; //100 good //43
			
		end
	end
	
	//the background color reflects the most recent button press
	always@(posedge clk, posedge rst) begin
		if(rst)
			background <= 12'b1111_1111_1111; // White background
		else
		  if(btnu)
		      background <= 12'b1111_0000_0000; //Red rgb 
		    else if(btnr)
              background <= 12'b0000_0001_1111; //Blue rgb color 
            else if(btnd)
              background <= 12'b1111_1111_0000; //Yellow rgb color 
            else if(btnl)
              background <= 12'b0000_1111_0000; //Green rgb color
			else
				background <= 12'b0000_0000_0000; // Black rgb color
	end

	
	
endmodule
