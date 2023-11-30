`timescale 1ns / 1ps

module block_controller(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input mastClk,
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
	wire [11:0] puvvadaColor; //Will hold the color from the bitrom file
	
	// Code to link the image rom bit files to VGA
	zero_start_testing_smallest_rom zero(.clk(mastClk),.row(vCount), .col(hCount), .color_data(puvvadaColor));
	
	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000; //If the screen has other pixels outside of 640x480 then forcing them to be black
		else if (block_fill) //If we are within the the grid we specified below. 640x480 then we grab the color from the bit room file and store it in rgb
			rgb = puvvadaColor; 
		else	
			rgb=background;
	end
	// block_fill is a 640x480 grid starting at the top left corner and goes to the bottom right.
	assign block_fill=vCount>=(ypos) && vCount<=(ypos+480) && hCount>=(xpos+1) && hCount<=(xpos-639);
	
	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			xpos<=450;
			ypos<=250;
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
		    background <= 12'b0000_1111_0000; // Green Background for any left over white space on the screen 
	end

	
	
endmodule
