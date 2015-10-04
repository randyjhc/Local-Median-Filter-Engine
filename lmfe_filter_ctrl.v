//-----------------------------------------------
//--- File Name: lmfe_filter_ctrl.v
//--- Author: randyjhc
//--- Date: 2015-10-04
//--- Description: Controller for the LMFE engine
//-----------------------------------------------
module lmfe_filter_ctrl (
	clk,
	RST,
	IEN,
	DIN,
	Q,
	MED,
	A,
	D,
	CE,
	WE,
	SE,
	INS,
	DEL,
	DOUT,
	OV,
	BZ
);

//-- I/O declaration
input			clk;
input			RST;
input			IEN;
input	[7:0]	DIN;
input	[7:0]	Q;
input	[7:0]	MED;
output	[9:0]	A;
output	[7:0]	D;
output			CE;
output			WE;
output			SE;
output	[7:0]	INS;
output	[7:0]	DEL;
output	[7:0]	DOUT;
output			OV;
output			BZ;

//-- parameters
parameter ST_IDL = 4'h0;
parameter ST_W7L = 4'h1;
parameter ST_R49 = 4'h2;
parameter ST_R7R = 4'h3;
parameter ST_W1L = 4'h4;
parameter ST_R7D = 4'h5;
parameter ST_R7L = 4'h6;
parameter ST_O1LU = 4'h7;
parameter ST_W1LU = 4'h8;
parameter ST_R7DU = 4'h9;
parameter ST_END = 4'ha;

//-- reg and wire
reg		[9:0]	A;
reg		[7:0]	D;
reg				CE;
reg				WE;
reg				SE;
reg		[7:0]	INS;
reg		[7:0]	DEL;
reg		[7:0]	DOUT;
reg				OV;
reg				BZ;
reg		[7:0]	i;
reg		[7:0]	n_DOUT;
reg				n_BZ;
reg				n_OV;
reg		[9:0]	n_A;
reg		[7:0]	n_D;
reg				n_CE;
reg				n_WE;
reg				n_SE;
reg		[7:0]	n_INS;
reg		[7:0]	n_DEL;
reg		[3:0]	state, n_state;
reg		[9:0]	wa, n_wa;
reg		[9:0]	wc, n_wc;
reg		[5:0]	rc, n_rc;
reg		[7:0]	lc, n_lc;
reg		[13:0]	pc, n_pc;
reg		[7:0]	px, n_px;
reg		[7:0]	py, n_py;
reg		[7:0]	mv[0:48];
reg		[7:0]	n_mv[0:48];
reg		[7:0]	mx[0:48];
reg		[7:0]	my[0:48];
reg		[7:0]	ix[0:48];
reg		[7:0]	iy[0:48];
reg				noob[0:48];
reg		[7:0]	med_buf[0:126];
reg		[7:0]	n_med_buf[0:126];

//-- state register
always @ (posedge clk, posedge RST) begin
	if (RST) begin
		state <= ST_IDL;
	end else begin
		state <= n_state;
	end
end

//-- next state logic
always @ * begin
	n_state = state;
	case (state)
		ST_IDL: begin
			if (IEN) begin
				n_state = ST_W7L;
			end else begin
				n_state = ST_IDL;
			end
		end
		ST_W7L: begin
			if (wc<895) begin
				n_state = ST_W7L;
			end else begin
				n_state = ST_R49;
			end
		end
		ST_R49: begin
			if (rc<51) begin
				n_state = ST_R49;
			end else begin
				n_state = ST_R7R;
			end
		end
		ST_R7R: begin
			if (rc<9) begin
				n_state = ST_R7R;
			end else if (lc==127 && (pc<639 || pc>16000)) begin
				n_state = ST_R7D;
			end else if (lc==127) begin
				n_state = ST_W1L;
			end else begin
				n_state = ST_R7R;
			end
		end
		ST_W1L: begin
			if (wc<128) begin
				n_state = ST_W1L;
			end else begin
				n_state = ST_R7D;
			end
		end
		ST_R7D: begin
			if (rc<9) begin
				n_state = ST_R7D;
			end else begin
				n_state = ST_R7L;
			end
		end
		ST_R7L: begin
			if (rc<9) begin
				n_state = ST_R7L;
			end else if (lc==127 && (pc<511 || pc>16000)) begin
				n_state = ST_O1LU;
			end else if (lc==127) begin
				n_state = ST_W1LU;
			end else begin
				n_state = ST_R7L;
			end
		end
		ST_O1LU: begin
			if (lc<128) begin
				n_state = ST_O1LU;
			end else if (pc<16256) begin
				n_state = ST_R7DU;
			end else begin
				n_state = ST_END;
			end
		end
		ST_W1LU: begin
			if (wc<128) begin
				n_state = ST_W1LU;
			end else begin
				n_state = ST_R7DU;
			end
		end
		ST_R7DU: begin
			if (rc<9) begin
				n_state = ST_R7DU;
			end else begin
				n_state = ST_R7R;
			end
		end
		ST_END: begin
			n_state = ST_END;
		end
		default: begin
			n_state = ST_IDL;
		end
	endcase
end

//-- output register
always @ (posedge clk, posedge RST) begin
	if (RST) begin
		DOUT <= 1'b0;
		BZ   <= 1'b0;
		OV   <= 1'b0;
		A    <= 1'b0;
		D    <= 1'b0;
		CE   <= 1'b1;
		WE   <= 1'b1;
		SE   <= 1'b1;
		INS  <= 8'hff;
		DEL  <= 8'hff;
	end else begin
		DOUT <= n_DOUT;
		BZ   <= n_BZ;
		OV   <= n_OV;
		A    <= n_A;
		D    <= n_D;
		CE   <= n_CE;
		WE   <= n_WE;
		SE   <= n_SE;
		INS  <= n_INS;
		DEL  <= n_DEL;
	end
end

//-- output logic
always @ * begin
	n_DOUT = DOUT;
	n_BZ   = BZ;
	n_OV   = OV;
	n_A    = A;
	n_D    = D;
	n_CE   = CE;
	n_WE   = WE;
	n_SE   = SE;
	n_INS  = INS;
	n_DEL  = DEL;
	case (state)
		ST_IDL: begin
			if (IEN) begin
				// n_state = ST_W7L;
				n_A    = wa;
				n_D    = DIN;
				n_CE   = 1'b0;
				n_WE   = 1'b0;
			end else begin
				// n_state = ST_IDL;
			end
		end
		ST_W7L: begin
			if (wc<895) begin
				// n_state = ST_W7L;
				n_BZ = (wc==894)? 1'b1: 1'b0;
				n_A  = wa;
				n_D  = DIN;
			end else begin
				// n_state = ST_R49;
				n_CE  = 1'b0;
				n_WE  = 1'b1;
			end
		end
		ST_R49: begin
			if (rc<51) begin
				// n_state = ST_R49;
				n_A   = (rc<49)? ((my[rc]-3)<<7) + (mx[rc]-3): 0;				
				n_SE  = (rc>1)? 1'b0: 1'b1;
				n_INS = (rc>1)? (noob[rc-2]>0)? Q: 0: 8'hff;
			end else begin
				// n_state = ST_R7R;
				n_SE = 1'b1;
			end
		end		
		ST_R7R: begin
			if (rc<9) begin
				// n_state = ST_R7R;
				n_OV   = (rc<1)? 1'b1: 0;
				n_DOUT = (rc<1)? MED: 0;
				n_A    = (rc<7)? ((my[6+rc*7]-3)<<7) + (mx[6+rc*7]-3): 0;
				n_SE   = (rc>1)? 1'b0: 1'b1;
				n_INS  = (rc>1)? (noob[6+(rc-2)*7]>0)? Q: 0: 8'hff;
				n_DEL  = (rc>1)? mv[0+(rc-2)*7]: 8'hff;
			end else if (lc==127 && (pc<639 || pc>16000)) begin
				// n_state = ST_R7D;
				n_SE = 1'b1;
			end else if (lc==127) begin
				// n_state = ST_W1L;
				n_BZ = 1'b0;
				n_SE = 1'b1;
			end else begin
				// n_state = ST_R7R;
				n_SE = 1'b1;
			end
		end
		ST_W1L: begin
			if (wc<128) begin
				// n_state = ST_W1L;
				n_BZ   = (wc==127)? 1'b1: 1'b0;
				n_OV   = (rc<1)? 1'b1: 0;
				n_DOUT = (rc<1)? MED: 0;
				n_A    = wa;
				n_D    = DIN;
				n_CE = 0;
				n_WE = 0;
			end else begin
				// n_state = ST_R7D;
				n_CE = 1'b0;
				n_WE = 1'b1;
			end
		end
		ST_R7D: begin
			if (rc<9) begin
				// n_state = ST_R7D;
				n_OV   = (rc<1)? 1'b1: 0;
				n_DOUT = (rc<1)? MED: 0;
				n_A    = (rc<7)? ((my[42+rc]-3)<<7) + (mx[42+rc]-3): 0;
				n_SE   = (rc>1)? 1'b0: 1'b1;
				n_INS  = (rc>1)? (noob[42+(rc-2)]>0)? Q: 0: 8'hff;
				n_DEL  = (rc>1)? mv[0+(rc-2)]: 8'hff;
			end else begin
				// n_state = ST_R7L;
				n_SE = 1'b1;
			end
		end
		ST_R7L: begin
			if (rc<9) begin
				// n_state = ST_R7L;
				n_A    = (rc<7)? ((my[rc*7]-3)<<7) + (mx[rc*7]-3): 0;
				n_SE   = (rc>1)? 1'b0: 1'b1;
				n_INS  = (rc>1)? (noob[(rc-2)*7]>0)? Q: 0: 8'hff;
				n_DEL  = (rc>1)? mv[6+(rc-2)*7]: 8'hff;				
			end else if (lc==127 && (pc<511 || pc>16000)) begin
				// n_state = ST_O1LU;
				n_SE = 1'b1;
			end else if (lc==127) begin
				// n_state = ST_W1LU;
				n_BZ = 1'b0;
				n_SE = 1'b1;
			end else begin
				// n_state = ST_R7L;
				n_SE = 1'b1;
			end
		end
		ST_O1LU: begin
			if (lc<128) begin
				// n_state = ST_O1LU;
				n_OV   = 1'b1;
				n_DOUT = (lc<1)? MED: med_buf[127-lc];
			end else if (pc<16256) begin
				// n_state = ST_R7DU;
				n_OV = 1'b0;
			end else begin
				// n_state = ST_END;
				n_OV = 1'b0;
			end
		end
		ST_W1LU: begin
			if (wc<128) begin
				// n_state = ST_W1LU;
				n_BZ = (wc==127)? 1'b1: 1'b0;
				n_OV   = 1'b1;
				n_DOUT = (lc<1)? MED: med_buf[127-lc];
				n_A  = wa;
				n_D  = DIN;
				n_CE = 1'b0;
				n_WE = 1'b0;
			end else begin
				// n_state = ST_R7DU;
				n_OV = 1'b0;
				n_CE = 1'b0;
				n_WE = 1'b1;
			end
		end
		ST_R7DU: begin
			if (rc<9) begin
				// n_state = ST_R7DU;		
				n_A    = (rc<7)? ((my[42+rc]-3)<<7) + (mx[42+rc]-3): 0;
				n_SE   = (rc>1)? 1'b0: 1'b1;
				n_INS  = (rc>1)? (noob[42+(rc-2)]>0)? Q: 0: 8'hff;
				n_DEL  = (rc>1)? mv[0+(rc-2)]: 8'hff;
			end else begin
				// n_state = ST_R7R;
				n_SE = 1'b1;
			end
		end
		ST_END: begin
			// n_state = ST_END;
		end
	endcase
end

//-- internal register
always @ (posedge clk, posedge RST) begin
	if (RST) begin
		wa <= 0;
		wc <= 0;
		rc <= 0;
		lc <= 0;
		pc <= 0;
		px <= 3;
		py <= 3;
	end else begin
		wa <= n_wa;
		wc <= n_wc;
		rc <= n_rc;
		lc <= n_lc;
		pc <= n_pc;
		px <= n_px;
		py <= n_py;		
	end
end
always @ (posedge clk, posedge RST) begin
	if (RST) begin
		for (i=0; i<49; i=i+1) begin
			mv[i] <= 0;
		end
	end else begin
		for (i=0; i<49; i=i+1) begin
			mv[i] <= n_mv[i];
		end
	end
end
always @ (posedge clk, posedge RST) begin
	if (RST) begin
		for (i=0; i<127; i=i+1) begin
			med_buf[i] <= 0;
		end
	end else begin
		for (i=0; i<127; i=i+1) begin
			med_buf[i] <= n_med_buf[i];
		end
	end
end

//-- internal logic
always @ * begin
	n_wa = wa;
	n_wc = wc;
	n_rc = rc;
	n_lc = lc;
	n_pc = pc;
	n_px = px;
	n_py = py;
	case (state)
		ST_IDL: begin
			if (IEN) begin
				// n_state = ST_W7L;
				n_wa = wa + 1;
				n_wc = 0;
			end else begin
				// n_state = ST_IDL;
			end
		end
		ST_W7L: begin
			if (wc<895) begin
				// n_state = ST_W7L;
				n_wa = wa + 1;
				n_wc = wc + 1;
			end else begin
				// n_state = ST_R49;
				n_rc = 0;
			end
		end
		ST_R49: begin
			if (rc<51) begin
				// n_state = ST_R49;
				n_rc = rc + 1;
				// if (rc>1) n_mv[rc-2] = (noob[rc-2]>0)? Q: 0;
			end else begin
				// n_state = ST_R7R;
				n_rc = 0;
				n_lc = lc + 1;
				n_pc = pc + 1;
				n_px = px + 1;
			end
		end
		ST_R7R: begin	
			if (rc<9) begin
				// n_state = ST_R7R;
				n_rc = rc + 1;
				// if (rc>1) begin
					// n_mv[6+(rc-2)*7] = (noob[6+(rc-2)*7]>0)? Q: 0;
					// for (i=0; i<6; i=i+1) begin
						// n_mv[i+(rc-2)*7] = mv[(i+1)+(rc-2)*7];
					// end
				// end
			end else if (lc==127 && (pc<639 || pc>16000)) begin
				// n_state = ST_R7D;
				n_rc = 0;
				n_lc = 0;
				n_pc = pc + 1;
				n_py = py + 1;
			end else if (lc==127) begin
				// n_state = ST_W1L;
				// n_wa = wa + 1;
				n_wc = 0;
				n_lc = 0;
				n_pc = pc + 1;
				n_py = py + 1;
			end else begin
				// n_state = ST_R7R;
				n_rc = 0;
				n_lc = lc + 1;
				n_pc = pc + 1;
				n_px = px + 1;
			end
		end
		ST_W1L: begin
			if (wc<128) begin
				// n_state = ST_W1L;
				n_lc = lc + 1;
				n_wa = wa + 1;
				n_wc = wc + 1;
			end else begin
				// n_state = ST_R7D;
				n_lc = 0;
				n_rc = 0;
			end
		end
		ST_R7D: begin
			if (rc<9) begin
				// n_state = ST_R7D;
				n_rc = rc + 1;
				// if (rc>1) begin
					// n_mv[42+(rc-2)] = (noob[42+(rc-2)]>0)? Q: 0;
					// for (i=0; i<6; i=i+1) begin
						// n_mv[i*7+(rc-2)] = mv[(i+1)*7+(rc-2)];
					// end
				// end
			end else begin
				// n_state = ST_R7L;
				n_rc = 0;
				n_lc = lc + 1;
				n_pc = pc + 1;
				n_px = px - 1;
			end
		end
		ST_R7L: begin
			if (rc<9) begin
				// n_state = ST_R7L;
				n_rc = rc + 1;
				// if (rc>1) begin
					// n_mv[(rc-2)*7] = (noob[(rc-2)*7]>0)? Q: 0;
					// for (i=0; i<6; i=i+1) begin
						// n_mv[(i+1)+(rc-2)*7] = mv[i+(rc-2)*7];
					// end
				// end
				// n_med_buf[lc-1] = (rc<1)? MED: med_buf[lc-1];
			end else if (lc==127 && (pc<511 || pc>16000)) begin
				// n_state = ST_O1LU;
				n_rc = 0;
				n_lc = 0;
				n_pc = pc + 1;
				n_py = py + 1;
			end else if (lc==127) begin
				// n_state = ST_W1LU;
				n_wc = 0;
				n_lc = 0;
				n_pc = pc + 1;
				n_py = py + 1;
			end else begin
				// n_state = ST_R7L;
				n_rc = 0;
				n_lc = lc + 1;
				n_pc = pc + 1;
				n_px = px - 1;
			end
		end
		ST_O1LU: begin
			if (lc<128) begin
				// n_state = ST_O1LU;
				n_lc = lc + 1;
			end else if (pc<16256) begin
				// n_state = ST_R7DU;
				n_lc = 0;
			end else begin
				// n_state = ST_END;
			end
		end
		ST_W1LU: begin
			if (wc<128) begin
				// n_state = ST_W1LU;
				n_lc = lc + 1;
				n_wa = wa + 1;
				n_wc = wc + 1;
			end else begin
				// n_state = ST_R7DU;
				n_lc = 0;
				n_rc = 0;
			end
		end
		ST_R7DU: begin
			if (rc<9) begin
				// n_state = ST_R7DU;
				n_rc = rc + 1;
				// if (rc>1) begin
					// n_mv[42+(rc-2)] = (noob[42+(rc-2)]>0)? Q: 0;
					// for (i=0; i<6; i=i+1) begin
						// n_mv[i*7+(rc-2)] = mv[(i+1)*7+(rc-2)];
					// end
				// end
			end else begin
				// n_state = ST_R7R;
				n_rc = 0;
				n_lc = lc + 1;
				n_pc = pc + 1;
				n_px = px + 1;
			end
		end
		ST_END: begin
			// n_state = ST_END;
		end
	endcase
end
// mv[i]
always @ * begin
	for (i=0; i<49; i=i+1) begin
		n_mv[i] = mv[i];
	end
	if (state==ST_R49 && rc<51 && rc>1) begin
		n_mv[rc-2] = (noob[rc-2]>0)? Q: 0;
	end else if (state==ST_R7R && rc<9 && rc >1) begin
		n_mv[6+(rc-2)*7] = (noob[6+(rc-2)*7]>0)? Q: 0;
		for (i=0; i<6; i=i+1) begin
			n_mv[i+(rc-2)*7] = mv[(i+1)+(rc-2)*7];
		end
	end else if (state==ST_R7D && rc<9 && rc >1) begin
		n_mv[42+(rc-2)] = (noob[42+(rc-2)]>0)? Q: 0;
		for (i=0; i<6; i=i+1) begin
			n_mv[i*7+(rc-2)] = mv[(i+1)*7+(rc-2)];
		end
	end else if (state==ST_R7L && rc<9 && rc >1) begin
		n_mv[(rc-2)*7] = (noob[(rc-2)*7]>0)? Q: 0;
		for (i=0; i<6; i=i+1) begin
			n_mv[(i+1)+(rc-2)*7] = mv[i+(rc-2)*7];
		end
	end else if (state==ST_R7DU && rc<9 && rc >1) begin
		n_mv[42+(rc-2)] = (noob[42+(rc-2)]>0)? Q: 0;
		for (i=0; i<6; i=i+1) begin
			n_mv[i*7+(rc-2)] = mv[(i+1)*7+(rc-2)];
		end
	end else begin
	
	end
end
// med_buf[i]
always @ * begin
	for (i=0; i<127; i=i+1) begin
		n_med_buf[i] = med_buf[i];
	end
	if (state==ST_R7L && rc<1) begin
		n_med_buf[lc-1] = MED;
	end else begin
	
	end
end
// mx[i]
always @ * begin
	for (i=0; i<7; i=i+1) begin
		mx[7*i+0] = px-3;
		mx[7*i+1] = px-2;
		mx[7*i+2] = px-1;
		mx[7*i+3] = px;
		mx[7*i+4] = px+1;
		mx[7*i+5] = px+2;
		mx[7*i+6] = px+3;
	end
end
// my[i]
always @ * begin
	for (i=0; i<7; i=i+1) begin
		my[i+0] = py-3;
		my[i+7] = py-2;
		my[i+14] = py-1;
		my[i+21] = py;
		my[i+28] = py+1;
		my[i+35] = py+2;
		my[i+42] = py+3;
	end
end
// noob[i]
always @ * begin
	for (i=0; i<49; i=i+1) begin
		noob[i] = (mx[i]>2 && mx[i]<131 && my[i]>2 && my[i]<131)? 1'b1: 1'b0;
	end
end
// assign mx[0] = px-3;  assign mx[1] = px-2;  assign mx[2] = px-1;  assign mx[3] = px;  assign mx[4] = px+1;  assign mx[5] = px+2;  assign mx[6] = px+3;
// assign mx[7] = px-3;  assign mx[8] = px-2;  assign mx[9] = px-1;  assign mx[10] = px; assign mx[11] = px+1; assign mx[12] = px+2; assign mx[13] = px+3;
// assign mx[14] = px-3; assign mx[15] = px-2; assign mx[16] = px-1; assign mx[17] = px; assign mx[18] = px+1; assign mx[19] = px+2; assign mx[20] = px+3;
// assign mx[21] = px-3; assign mx[22] = px-2; assign mx[23] = px-1; assign mx[24] = px; assign mx[25] = px+1; assign mx[26] = px+2; assign mx[27] = px+3;
// assign mx[28] = px-3; assign mx[29] = px-2; assign mx[30] = px-1; assign mx[31] = px; assign mx[32] = px+1; assign mx[33] = px+2; assign mx[34] = px+3;
// assign mx[35] = px-3; assign mx[36] = px-2; assign mx[37] = px-1; assign mx[38] = px; assign mx[39] = px+1; assign mx[40] = px+2; assign mx[41] = px+3;
// assign mx[42] = px-3; assign mx[43] = px-2; assign mx[44] = px-1; assign mx[45] = px; assign mx[46] = px+1; assign mx[47] = px+2; assign mx[48] = px+3;

// assign my[0] = py-3;  assign my[1] = py-3;  assign my[2] = py-3;  assign my[3] = py-3;  assign my[4] = py-3;  assign my[5] = py-3;  assign my[6] = py-3;
// assign my[7] = py-2;  assign my[8] = py-2;  assign my[9] = py-2;  assign my[10] = py-2; assign my[11] = py-2; assign my[12] = py-2; assign my[13] = py-2;
// assign my[14] = py-1; assign my[15] = py-1; assign my[16] = py-1; assign my[17] = py-1; assign my[18] = py-1; assign my[19] = py-1; assign my[20] = py-1;
// assign my[21] = py;   assign my[22] = py;   assign my[23] = py;   assign my[24] = py;   assign my[25] = py;   assign my[26] = py;   assign my[27] = py;
// assign my[28] = py+1; assign my[29] = py+1; assign my[30] = py+1; assign my[31] = py+1; assign my[32] = py+1; assign my[33] = py+1; assign my[34] = py+1;
// assign my[35] = py+2; assign my[36] = py+2; assign my[37] = py+2; assign my[38] = py+2; assign my[39] = py+2; assign my[40] = py+2; assign my[41] = py+2;
// assign my[42] = py+3; assign my[43] = py+3; assign my[44] = py+3; assign my[45] = py+3; assign my[46] = py+3; assign my[47] = py+3; assign my[48] = py+3;

endmodule
