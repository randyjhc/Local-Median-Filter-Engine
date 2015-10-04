module LMFE (clk, reset, Din, in_en, busy, out_valid, Dout);
input   clk;
input   reset;
input   in_en;
output  busy;
output  out_valid;
input   [7:0]  Din;
output  [7:0]  Dout;

wire [9:0] sram_address;
wire [7:0] sram_in;
wire [7:0] sram_out;
wire [7:0] sort_insert;
wire [7:0] sort_delete;
wire [7:0] sort_median;
wire chip_enable;
wire write_enable;
wire sort_enable;

FILTER_CTRL F0 (
// input port
	.clk(clk),
	.RST(reset),
	.IEN(in_en),
	.DIN(Din),
	.Q(sram_out),
	.MED(sort_median),
// output port
	.A(sram_address),
	.D(sram_in),	
	.CE(chip_enable),
	.WE(write_enable),
	.SE(sort_enable),
	.INS(sort_insert),
	.DEL(sort_delete),
	.DOUT(Dout),
	.OV(out_valid),
	.BZ(busy)
);

MEDIAN49 M0 (
// input port
	.clk(clk),
	.RST(reset),
	.SEN(sort_enable),
	.INS(sort_insert),
	.DEL(sort_delete),
// output port
	.MED(sort_median)
);

sram_1024x8_t13 S0 (
	.Q (sram_out),
	.CLK (clk),
	.CEN (chip_enable),
	.WEN (write_enable),
	.A (sram_address),
	.D (sram_in)
);

endmodule
