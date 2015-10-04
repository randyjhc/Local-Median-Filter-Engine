`timescale 1ns/10ps
`define CYCLE      8				//-- clock period
`define End_CYCLE  10000000			//-- time to end the simulation
`define PAT        "../patt/pattern1.dat"	//-- input image pattern
`define EXP        "../patt/golden1.dat"	//-- golden image file

module systest;

//-- parameter
parameter N_EXP   = 16384;
parameter N_PAT   = N_EXP;

//-- reg and wire
reg				clk ;
reg				reset ;
reg   			in_en;
reg		[7:0]	Din;
wire			busy;
wire			out_valid;
wire	[7:0]	Dout;
reg		[7:0]	pat_mem   [0:N_PAT-1];
reg		[7:0]	exp_mem   [0:N_EXP-1];
reg		[7:0]	out_temp;
reg				stop;
integer			i, out_f, err, pass, exp_num, times;
reg				over;

//-- design under test
lmfe_top u_lmfe_top(
	.clk		(clk),
	.reset		(reset),
	.Din		(Din),
	.in_en		(in_en),
	.busy		(busy),
	.out_valid	(out_valid),
	.Dout		(Dout)
);         
 
//-- read input and golden image
initial	$readmemh (`PAT, pat_mem);
initial	$readmemh (`EXP, exp_mem);

//-- initialization
initial begin
#0;
   clk         = 1'b0;
   reset       = 1'b0;
   in_en       = 1'b0;   
   Din         = 'hz;
   stop        = 1'b0;  
   over        = 1'b0;
   exp_num     = 0;
   err         = 0;
   pass        = 0;
   times       = 1;            
end

//-- clock generator
always begin #(`CYCLE/2) clk = ~clk; end

//-- dump waveform
initial begin
	$dumpfile("top.vcd");
	$dumpvars(1, systest);

	out_f = $fopen("out.dat");
	if (out_f == 0) begin
		$display("Output file open error !");
		$finish;
	end
end


initial begin
	@(negedge clk)  reset = 1'b1;
	#`CYCLE         reset = 1'b0;
	
	#(`CYCLE*2);   
	@(negedge clk) i=0;
	while (i <= N_PAT) begin               
		if(!busy) begin
			Din = pat_mem[i];
			in_en = 1'b1;
			i=i+1;
		end 
		else begin
			Din = 'hz; in_en = 1'b0;
		end                    
		@(negedge clk); 
    end     
    in_en = 0;
	Din='hz;
end

always @(posedge clk)begin
	out_temp = exp_mem[exp_num];
	if(out_valid)begin
		$fdisplay(out_f,"%2h", Dout);      
		if(Dout !== out_temp) begin
			$display("ERROR at %5d:output %2h !=expect %2h " ,exp_num, Dout, out_temp);
			err = err + 1;  
		end            
		else begin      
			pass = pass + 1;
		end
		#1 exp_num = exp_num + 1;
	end     
	if(exp_num === N_EXP)  over = 1'b1;   
end

always @(exp_num)begin  
	if(exp_num === (1000*times) && err === 0)begin  
		$display("Output pixel: 0 ~ %5d are correct!\n", (1000*times));
		times=times+1;
	end
end

initial  begin
	#(`CYCLE * `End_CYCLE);
	$display("-----------------------------------------------------\n");
	$display("Error!!! Somethings' wrong with your code ...!\n");
	$display("-------------------------FAIL------------------------\n");
	$display("-----------------------------------------------------\n");
	$finish;
end

initial begin
	@(posedge over)      
    if((over) && (exp_num!='d0)) begin
		$display("-----------------------------------------------------\n");
        if (err == 0)  begin
			$display("Congratulations! All data have been generated successfully!\n");
            $display("-------------------------PASS------------------------\n");
        end
        else begin
            $display("There are %d errors!\n", err);
            $display("-----------------------------------------------------\n");
        end
    end
    #(`CYCLE/2); $finish;
end
   
endmodule









