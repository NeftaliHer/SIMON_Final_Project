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
	wire [11:0] puvvadaColor; 
	wire [11:0] oneRedColor;
	wire [11:0] twoBlueColor;
	wire [11:0] threeYellowColor;
	wire [11:0] fourGreenColor;
	
	// Code to link the image rom bit files to VGA
	zero_start_testing_smallest_rom zero(.clk(mastClk),.row(vCount), .col(hCount), .color_data(puvvadaColor));
	one_red_smallest_rom red(.clk(mastClk),.row(vCount), .col(hCount), .color_data(oneRedColor));
	two_blue_smallest_rom blue(.clk(mastClk),.row(vCount), .col(hCount), .color_data(twoBlueColor));
	three_yellow_smallest_rom yellow(.clk(mastClk),.row(vCount), .col(hCount), .color_data(threeYellowColor));
	four_green_smallest_rom green(.clk(mastClk),.row(vCount), .col(hCount), .color_data(fourGreenColor));


	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000; //If the screen has other pixels outside of 640x480 then forcing them to be black
		/*else if (block_fill) //If we are within the the grid we specified below. 640x480 then we grab the color from the bit room file and store it in rgb
			rgb = puvvadaColor; 
		else	
			rgb=background;
		*/
		else if (block_fill && gColorNum == 1)
		  rgb = oneRedColor;
		else if (block_fill && gColorNum == 2)
		  //rgb = twoBlueColor;
		  rgb = 12'b0000_0001_1111;
		else if (block_fill && gColorNum == 3)
		  //rgb = threeYellowColor;
		  rgb = 12'b1111_1111_0000;
		else if (block_fill && gColorNum == 4)
		  //rgb = fourGreenColor;
		  rgb = 12'b0000_1111_0000;
		else if(block_fill)
		  rgb = puvvadaColor;
		else
		  rgb = background; // we are updating rgb value down below. The background color is changing
		                    // to match our button presses and the color of the background correlates with the corresponding button
	end
	// block_fill is a 640x480 grid starting at the top left corner and goes to the bottom right.
	assign block_fill=vCount>=(ypos) && vCount<=(ypos+550) && hCount>=(xpos+1) && hCount<=(xpos-700);
	
	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			xpos<=143; //test 43
			ypos<=100; //43
			/*Min_y = 34, Max_y=516, MIN_x=143, MAX_x=784*/
		end
		//else if (clk) begin
		
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/
			
		//end
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
