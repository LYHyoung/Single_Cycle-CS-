`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  KWU
// Engineer: SWL
// 
// Create Date:    03/17/2021 
// Module Name:    SingleCycle 
// Project Name:   Single Cycle Processor
//
// Revision: 
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module SingleCycle(i_clk,i_rst_n,o_PC);
	input i_clk, i_rst_n;
	output [31:0] o_PC;

	wire [4:0] ALUop;
	wire [3:0] ALUctrl;
	wire [4:0] ALU_funct;
	wire [1:0] RegDst, RegDatSel;
	wire [2:0] Branch;
	wire ALU_zero, ALU_ovr, ALU_carry, ALU_posi, MemWrite, MemtoReg, RegWrite, ExtMode;
  wire [1:0] DatWidth,ALUsrc,Jump;

	wire [31:0] w_pc_reg, w_pc_mab4, w_jump_addr, w_br_ofs;
	wire [25:0] w_instr_imm26;
  wire [31:0] w_pc_plus4, w_next_pc, w_br_addr, w_SEU_data;
  wire [31:0] w_hi_reg, w_lo_reg;
	wire [31:0] w_instr, w_br_chk_addr;
	wire [3:0]  w_pc_msb4;
	wire        w_br_ok;
	wire        w_const_ld;
	
	assign o_PC = w_pc_reg;

	assign w_pc_plus4 = 32'h00000004 + w_pc_reg; 

	assign w_br_ofs = w_SEU_dat<<2;
	assign w_br_addr = w_br_ofs + w_pc_plus4;

	assign w_instr_imm26 = w_instr[25:0];
	assign w_pc_msb4 = w_pc_plus4[31:28];
	assign w_jump_addr = {w_pc_msb4[3:0], w_instr_imm26[25:0]} << 2;

	assign w_br_ok = (Branch == 3'b100) ?  ALU_zero :
	                 (Branch == 3'b101) ? ~ALU_zero :
	                 (Branch == 3'b110) ? ~ALU_posi :
	                 (Branch == 3'b111) ?  ALU_posi : 
	                 (Branch == 3'b011) ?  1'b1     : 
	                 1'b0; 

  assign w_br_chk_addr = w_br_ok ? w_br_addr : w_pc_plus4; 
  assign w_next_pc = (Jump==2'b00) ? w_br_chk_addr :
                     (Jump==2'b01) ? w_jump_addr   :
                     (Jump==2'b10) ? w_rreg_dat1   : 32'bx; 
	PC 			U0_PC(i_clk,i_rst_n,w_next_pc,w_pc_reg); 
	IM 			U1_IM(w_pc_reg,w_instr); 

  wire [4:0]  w_wr_reg;
	wire [31:0] w_alu_or_dm, w_wr_dat, w_rreg_dat1, w_rreg_dat2;
	wire [31:0] w_ALU_dat, w_SEU_dat, w_DM_dat, w_alu_ain, w_alu_bin;
	wire [4:0]  w_shamt = w_instr[10:6];
		
	assign w_wr_reg = (RegDst == 2'b00) ? w_instr[20:16] :
	                  (RegDst == 2'b01) ? w_instr[15:11] :
	                  (RegDst == 2'b10) ? 5'd31 :
	                  (RegDst == 2'b11) ? 5'b0 : 5'bx;  
  assign w_wr_dat = (RegDatSel == 2'b11) ? w_pc_plus4 :
                    (RegDatSel == 2'b10) ? w_hi_reg   :
                    (RegDatSel == 2'b01) ? w_lo_reg   :
                    (RegDatSel == 2'b00) ? w_alu_or_dm: 32'bx;
  assign w_alu_or_dm = MemtoReg ? w_DM_dat : w_ALU_dat; 
	RF 			U2_RF(i_clk,i_rst_n,w_instr[25:21],w_instr[20:16],w_wr_reg,w_wr_dat,RegWrite,w_rreg_dat1,w_rreg_dat2);

	SEU 		U3_SEU(w_instr[15:0],w_SEU_dat,ExtMode); 
	assign w_alu_ain = w_const_ld ? w_rreg_dat2 : w_rreg_dat1;
  assign w_alu_bin = (ALUsrc==2'b00) ? w_rreg_dat2 :
                     (ALUsrc==2'b01) ? w_SEU_dat   :
                     (ALUsrc==2'b10) ? 32'b0 : 32'bx; 
	ALU 		U4_ALU(w_alu_ain,w_alu_bin,w_shamt,ALUop,ALUctrl,w_ALU_dat,ALU_zero,ALU_ovr,ALU_carry,ALU_posi);

  MULT    U5_MULT(i_clk,i_rst_n,w_rreg_dat1,w_rreg_dat2,ALUop,w_hi_reg,w_lo_reg);

	DM 		  U6_DM(i_clk,MemWrite,DatWidth,w_ALU_dat,w_rreg_dat2,w_DM_dat);

	ControlTop	U7_CTRL(w_instr[31:26],w_instr[5:0],RegDst,Jump,Branch,MemtoReg,ALUop,ALUctrl,
	                    MemWrite,DatWidth,ALUsrc,RegWrite,RegDatSel,ExtMode,w_const_ld); 
	
endmodule

//////////////////////////////////////////////////////////////////////////////////

module PC(i_clk, i_rst_n, i_next_pc, o_pc_reg);
	input i_clk,i_rst_n;      
	input [31:0] i_next_pc;   
	output [31:0] o_pc_reg;       
	reg [31:0] o_pc_reg;

	always@ (posedge i_clk or negedge i_rst_n) begin
		if(i_rst_n==0)    o_pc_reg = 31'd0;
		else    o_pc_reg = i_next_pc;
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////

module ControlTop(op,func,RegDst,Jump,Branch,MemtoReg,ALUop,ALUctrl,MemWrite,DatWidth,
                  ALUsrc,RegWrite,RegDatSel,ExtMode,ConstLD);
	input [5:0] op;
	input [5:0] func;
	output wire [1:0] RegDst, RegDatSel;
	output MemtoReg,MemWrite,RegWrite,ExtMode;  
	output wire [1:0] DatWidth,ALUsrc,Jump;
	output wire [2:0] Branch;
	output [4:0] ALUop;         
	output [3:0] ALUctrl;
	output ConstLD;
	wire sel;
	wire [1:0] RegDst_main, RegDst_my, RegDatSel_main, RegDatSel_my;
	wire MemWrite_main,MemtoReg_main,RegWrite_main,ExtMode_main;
	wire MemWrite_my,MemtoReg_my,RegWrite_my,ExtMode_my;
	wire [1:0] DatWidth_main,ALUsrc_main,DatWidth_my,ALUsrc_my,Jump_main,Jump_my;
  wire [2:0] Branch_main, Branch_my;
	wire [4:0] ALUop_main,ALUop_my;
	wire [3:0] ALUctrl_main,ALUctrl_my;

	MainControl U0_MainControl(op,func,RegDst_main,Jump_main,Branch_main,MemtoReg_main,
	                           ALUop_main,ALUsrc_main,ALUctrl_main,MemWrite_main,DatWidth_main,
	                           RegWrite_main,RegDatSel_main,ExtMode_main,ConstLD,sel);
	MyControl 	U1_MyControl(op,func,RegDst_my,Jump_my,Branch_my,MemtoReg_my,
	                           ALUop_my,ALUsrc_my,ALUctrl_my,MemWrite_my,DatWidth_my,
	                           RegWrite_my,RegDatSel_my,ExtMode_my);

  assign RegDst   = sel ? RegDst_my   : RegDst_main;
  assign Jump     = sel ? Jump_my     : Jump_main;
  assign Branch   = sel ? Branch_my   : Branch_main;
  assign MemtoReg = sel ? MemtoReg_my : MemtoReg_main;
  assign MemWrite = sel ? MemWrite_my : MemWrite_main;
  assign DatWidth = sel ? DatWidth_my : DatWidth_main;
  assign ALUsrc   = sel ? ALUsrc_my   : ALUsrc_main;
  assign RegWrite = sel ? RegWrite_my : RegWrite_main;
  assign RegDatSel= sel ? RegDatSel_my: RegDatSel_main;
  assign ALUop    = sel ? ALUop_my    : ALUop_main;
  assign ALUctrl  = sel ? ALUctrl_my  : ALUctrl_main;
  assign ExtMode  = sel ? ExtMode_my  : ExtMode_main;

endmodule

//////////////////////////////////////////////////////////////////////////////////

module ALU(i_data1, i_data2, shamt, ALUop, ALUctrl, o_result, o_zero, o_overflow, o_carry, o_positive);
	input [31:0] i_data1, i_data2;  
	input [4:0] shamt;
	input [4:0] ALUop;              
	input [3:0] ALUctrl;
	output reg [31:0] o_result;         
	output reg o_overflow, o_carry;     
	output o_zero, o_positive;
	
	reg [31:0] m_data; 
	wire [4:0] w_shift;
	wire [31:0] w_ain, w_bin;
	
	assign w_shift = (ALUctrl[0]==1'b0) ? shamt : i_data1[4:0];
	assign w_ain = (ALUctrl[1]==1'b0) ? i_data1 : i_data2;
	assign w_bin = (ALUctrl[1]==1'b0) ? i_data2 : i_data1;
	
	assign o_zero = (o_result == 32'b0) ? 1'b1 : 1'b0;
	assign o_positive = ((o_result[31] == 1'b0)&&(o_zero==1'b0)) ? 1'b1 : 1'b0;
	
	always @(*) begin
		case (ALUop)
			5'b00000 : begin 
				o_result = w_ain & w_bin;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b00001 : begin 
				o_result = w_ain | w_bin;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b00010 : begin 
				o_result = ~(w_ain | w_bin);
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b00011 : begin 
				o_result = w_ain ^ w_bin;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b00100 : begin 
				{o_carry, o_result} = $signed(w_ain) + $signed(w_bin);
				o_overflow = (w_ain[31]&w_bin[31]&~o_result[31])|(~w_ain[31]&~w_bin[31]&o_result[31]);
			end
			5'b00101 : begin 
				{o_carry, o_result} = $unsigned(w_ain) + $unsigned(w_bin);
				o_overflow = o_carry;
			end
			5'b00110 : begin 
			  m_data = ~(w_bin);
				{o_carry, o_result} = $signed(w_ain) + $signed(m_data) + 1;
				o_overflow = (w_ain[31]&m_data[31]&~o_result[31])|(~w_ain[31]&~m_data[31]&o_result[31]);
			end
			5'b00111 : begin 
				{o_carry, o_result} = $unsigned(w_ain) - $unsigned(w_bin);
				o_overflow = o_carry;
			end
			5'b01000 : begin 
				o_result = 32'h0;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b01101 : begin	
				o_result = w_bin << w_shift;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b01110 : begin	
				o_result = w_bin >> w_shift;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b01111 : begin	
				o_result = $signed(w_bin) >>> w_shift;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b10000 : begin 
				o_result = ($signed(w_ain) < $signed(w_bin)) ? 32'b1 : 32'b0;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b10001 : begin 
				o_result = ($unsigned(w_ain) < $unsigned(w_bin)) ? 32'b1 : 32'b0;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
			5'b11101 : begin
				o_carry = 1'b0;
				o_overflow = 1'b0;
				o_result = {w_bin[15:0], w_ain[15:0]};
			end
			5'b11110 : begin 
				o_carry = 1'b0;
				o_overflow = 1'b0;
				o_result = {w_ain[31:16], w_bin[15:0]};
			end
			5'b11111 : begin 
				o_carry = 1'b0;
				o_overflow = 1'b0;
				o_result = {w_bin[15:0], 16'b0};
			end
			default   : begin
				o_result = 32'h0;
				o_carry = 1'b0;
				o_overflow = 1'b0;
			end
		endcase
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////

module MULT(i_clk,i_rst_n,i_data1, i_data2, ALUop, o_hi, o_lo);
  input i_clk,i_rst_n;
	input [31:0] i_data1, i_data2; 
	input [4:0] ALUop;       
	output reg [31:0] o_hi, o_lo;
	
  always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
      o_hi <= 32'b0;
      o_lo <= 32'b0;
    end
    else begin
      if (ALUop == 5'b01001) begin   
        {o_hi, o_lo} <= $signed(i_data1) * $signed(i_data2);
      end
      else if (ALUop == 5'b01010) begin 
        {o_hi, o_lo} <= $unsigned(i_data1) * $unsigned(i_data2);
      end
      else if (ALUop == 5'b01011) begin  
        o_lo <= $signed(i_data1) / $signed(i_data2);
        o_hi <= $signed(i_data1) % $signed(i_data2);
      end
      else if (ALUop == 5'b01100) begin 
        o_lo <= $unsigned(i_data1) / $unsigned(i_data2);
        o_hi <= $unsigned(i_data1) % $unsigned(i_data2);
      end
      else if (ALUop == 5'b10010) begin 
        o_hi <= $unsigned(i_data1);
        o_lo <= o_lo;
      end
      else if (ALUop == 5'b10011) begin  
        o_hi <= o_hi;
        o_lo <= $unsigned(i_data1);
      end
      else begin
        o_lo <= o_lo;
        o_hi <= o_hi;
      end
    end
  end
endmodule

//////////////////////////////////////////////////////////////////////////////////

module SEU(i_halfword,o_word,ext_mode);
	input [15:0] i_halfword;     
	input ext_mode;
	output [31:0] o_word;        
	reg    [31:0] o_word;

	always@(*) begin
		if (ext_mode==1'b0) begin
			o_word = {16'h0000, i_halfword[15:0]};
		end
		else begin
			if(i_halfword[15]==1'b1) begin
				o_word = {16'hFFFF, i_halfword[15:0]};
			end
			else begin
				o_word = {16'h0000, i_halfword[15:0]};
			end
		end
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////

module MainControl(op,func,RegDst,Jump,Branch,MemtoReg,ALUOp,ALUsrc,ALUctrl,
                   MemWrite,DatWidth,RegWrite,RegDatSel,ExtMode,ConstLD,sel);
	input [5:0] op;  
	input [5:0] func;
	output reg [1:0] RegDst, RegDatSel;
	output reg MemtoReg,MemWrite,RegWrite,ExtMode;  
	output reg [1:0] DatWidth,ALUsrc,Jump;
	output reg [2:0] Branch;
	output reg [4:0] ALUOp;     
	output reg [3:0] ALUctrl;
	output reg ConstLD;
	output reg sel;

	always@(*) begin
		if(op==6'b000000) begin  
      if (func==6'b100000) begin  		  // add
  			ALUOp    = 5'b00100;  ALUctrl  = 4'b0000;
  			RegDst   = 2'b01;     ALUsrc   = 2'b00;
  			RegWrite = 1'b1;      MemtoReg = 1'b0;    
  			MemWrite = 1'b0;      DatWidth = 2'b00;
  			Jump     = 2'b00;     Branch   = 3'b000;    
  			RegDatSel= 2'b00;     ExtMode  = 1'bx; 
  			ConstLD  = 1'b0;      sel      = 1'b0;
  		end
      else if (func==6'b100010) begin  	// sub
  			ALUOp    = 5'b00110;  ALUctrl  = 4'b0000;
  			RegDst   = 2'b01;     ALUsrc   = 2'b00;
  			RegWrite = 1'b1;      MemtoReg = 1'b0;    
  			MemWrite = 1'b0;      DatWidth = 2'b00;
  			Jump     = 2'b00;     Branch   = 3'b000;    
  			RegDatSel= 2'b00;     ExtMode  = 1'bx; 
  			ConstLD  = 1'b0;      sel      = 1'b0;
  		end
      else begin   
  			ALUOp    = 5'bxxxxx; 	ALUctrl  = 4'bxxxx;
  			RegDst   = 2'bxx;     ALUsrc   = 2'bxx;
  			RegWrite = 1'bx;      MemtoReg = 1'bx;  
  			MemWrite = 1'bx;      DatWidth = 2'bxx;    
        Jump     = 2'bxx;     Branch   = 3'bxxx;
        RegDatSel= 2'bxx;     ExtMode  = 1'bx; 
  			ConstLD  = 1'b0;      sel      = 1'b1;
  		end
		end
		else if(op==6'b100011) begin 		// lw
			ALUsrc   = 2'b01;       RegDst   = 2'b00;    
			RegWrite = 1'b1;        MemtoReg = 1'b1;  
			MemWrite = 1'b0;        DatWidth = 2'b00;
			ALUOp    = 5'b00100;    ALUctrl  = 4'b0000;
			Jump     = 2'b00;       Branch   = 3'b000;      
			RegDatSel= 2'b00;       ExtMode  = 1'b1; 
 			ConstLD  = 1'b0;        sel      = 1'b0;
		end
		else if(op==6'b101011) begin 		// sw
			ALUsrc   = 2'b01;      	RegDst   = 2'bxx;     
			RegWrite = 1'b0;        MemtoReg = 1'bx;   
			MemWrite = 1'b1;        DatWidth = 2'b00;
			ALUOp    = 5'b00100;    ALUctrl  = 4'b0000;
			Jump     = 2'b00;       Branch   = 3'b000;       
			RegDatSel= 2'b00;       ExtMode  = 1'b1; 
 			ConstLD  = 1'b0;        sel      = 1'b0;
		end
		else if(op==6'b001101) begin 		// ori
			ALUsrc   = 2'b01;      	RegDst   = 2'b00;
			RegWrite = 1'b1;        MemtoReg = 1'b0;
			MemWrite = 1'b0;        DatWidth = 2'b00;
			ALUOp    = 5'b00001;    ALUctrl  = 4'b0000;
			Jump     = 2'b00;       Branch   = 3'b000;
			RegDatSel= 2'b00; 		ExtMode  = 1'b0;
 			ConstLD  = 1'b0;  		sel      = 1'b0;
		end
		else if(op==6'b001111) begin		// lui
			ALUsrc   = 2'b01; 			RegDst   = 2'b00;     
			RegWrite = 1'b1;  			MemtoReg = 1'b0;   
			MemWrite = 1'b0;  			DatWidth = 2'b00;
			ALUOp    = 5'b11111; 		ALUctrl  = 4'b0000;
			Jump     = 2'b00;    		Branch   = 3'b000;
			RegDatSel= 2'b00; 			ExtMode  = 1'b0; 
 			ConstLD  = 1'b0;  			sel      = 1'b0;
		end
		else if(op==6'b011000) begin 		// llo
			ALUsrc   = 2'b01; 			RegDst   = 2'b00;     
			RegWrite = 1'b1;  			MemtoReg = 1'b0;   
			MemWrite = 1'b0;  			DatWidth = 2'b00;
			ALUOp    = 5'b11110;			ALUctrl  = 4'b0000;
			Jump     = 2'b00; 			Branch   = 3'b000;    
			RegDatSel= 2'b00; 			ExtMode  = 1'b0; 
 			ConstLD  = 1'b1;  			sel      = 1'b0;
		end
		else if(op==6'b011001) begin 		// lhi
			ALUsrc   = 2'b01; 			RegDst   = 2'b00;
			RegWrite = 1'b1;  			MemtoReg = 1'b0;
			MemWrite = 1'b0;  			DatWidth = 2'b00;
			ALUOp    = 5'b11101; 		ALUctrl  = 4'b0000;
			Jump     = 2'b00;    		Branch   = 3'b000;    
			RegDatSel= 2'b00; 			ExtMode  = 1'b0; 
 			ConstLD  = 1'b1;  			sel      = 1'b0;
		end
		else if(op==6'b000010) begin 		// j
			ALUsrc   = 2'bxx;     		RegDst   = 2'bxx;     
			RegWrite = 1'b0;   			MemtoReg = 1'bx;   
			MemWrite = 1'b0;   			DatWidth = 2'bxx;
			ALUOp    = 5'bxxxxx;  		ALUctrl  = 4'bxxxx;
			Jump     = 2'b01;     		Branch   = 3'bxxx;    
			RegDatSel= 2'bxx; 			ExtMode  = 1'bx; 
 			ConstLD  = 1'bx;  			sel      = 1'b0;
		end
		else begin
			ALUsrc   = 2'bxx; 			RegDst   = 2'bxx;    
			RegWrite = 1'bx;  			MemtoReg = 1'bx;   
			MemWrite = 1'bx;  			DatWidth = 2'bxx;
			ALUOp    = 5'bxxxxx; 		ALUctrl  = 4'bxxxx;
			Jump     = 2'bxx;    		Branch   = 3'bxxx;    
			RegDatSel= 2'bxx; 			ExtMode  = 1'bx; 
 			ConstLD  = 1'b0;  			sel      = 1'b1;
		end
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////

module IM(i_addr, o_instr);       
	input [31:0]  i_addr;       
	output [31:0] o_instr;      
	reg [31:0]    o_instr;      
	reg [7:0] inst_mem[0:1023]; 

  reg w_WE;
  reg [31:0] w_addr, w_data;

	initial	begin
		$readmemb("INSTR_ROM.txt", inst_mem, 0, 255);    
    w_WE = 1'b0;
	end

	always @(i_addr) begin
		o_instr[7:0]  <=inst_mem[i_addr+3];
		o_instr[15:8] <=inst_mem[i_addr+2];
		o_instr[23:16]<=inst_mem[i_addr+1];
		o_instr[31:24]<=inst_mem[i_addr]; 
	end

  always @(posedge w_WE) begin
    if (w_WE==1'b1) begin
      inst_mem[w_addr+3] <= w_data[7:0];
      inst_mem[w_addr+2] <= w_data[15:8];
      inst_mem[w_addr+1] <= w_data[23:16];
      inst_mem[w_addr]   <= w_data[31:24];
    end
  end

endmodule

//////////////////////////////////////////////////////////////////////////////////

module DM(i_clk, MemWrite, DatWidth, i_addr, i_data, o_data);
	input i_clk, MemWrite; 
	input [1:0] DatWidth;       
	input [31:0]i_addr;         
	input [31:0]i_data;         
	output [31:0]o_data;        
	
	reg [31:0] o_data;
	reg [7:0] mem[0:1023];             
	
	wire [31:0] w_addr;
	
	assign w_addr = {i_addr[31:02], i_addr[01:00] & DatWidth};

	initial	begin
		$readmemb("DATA_RAM.txt",mem, 0, 255); 
	end

	always@(posedge i_clk) begin
		if(MemWrite==1'b1) begin
		  if (DatWidth == 2'b00) begin
        mem[w_addr+3] <= i_data[7:0];
        mem[w_addr+2] <= i_data[15:8];
        mem[w_addr+1] <= i_data[23:16];
        mem[w_addr]   <= i_data[31:24];
      end
		  else if (DatWidth == 2'b11) begin
		    mem[w_addr] <= i_data[7:0];
		  end
		  else begin
        mem[w_addr+1] <= i_data[07:00];
        mem[w_addr]   <= i_data[15:08];
		  end
		end
	end
	
	always @(*) begin
	  if (DatWidth == 2'b00) begin
      o_data[7:0]    = mem[w_addr+3];
      o_data[15:8]   = mem[w_addr+2];
      o_data[23:16]  = mem[w_addr+1];
      o_data[31:24]  = mem[w_addr];
	  end
    else if (DatWidth == 2'b11) begin
      o_data[7:0]    = mem[w_addr];
      o_data[15:8]   = 8'b0;
      o_data[23:16]  = 8'b0;
      o_data[31:24]  = 8'b0;
    end
    else begin
      o_data[7:0]    = mem[w_addr+1];
      o_data[15:8]   = mem[w_addr];
      o_data[23:16]  = 8'b0;
      o_data[31:24]  = 8'b0;
    end
  end
endmodule

//////////////////////////////////////////////////////////////////////////////////

module RF(i_clk,i_rst_n,i_Read_reg1,i_Read_reg2,i_Write_reg,i_Write_data,
          RegWrite, o_Read_data1, o_Read_data2);
	input i_clk, i_rst_n, RegWrite;                     
	input [4:0] i_Read_reg1, i_Read_reg2, i_Write_reg;
	input [31:0] i_Write_data;                        
	output [31:0] o_Read_data1, o_Read_data2;         
	reg [31:0] regs [0:31];
	
	always @(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			regs[0]  <= 32'b0; regs[1]  <= 32'bx; regs[2]  <= 32'bx; regs[3]  <= 32'bx; regs[4]  <= 32'bx; 
			regs[5]  <= 32'bx; regs[6]  <= 32'bx; regs[7]  <= 32'bx; regs[8]  <= 32'bx; regs[9]  <= 32'bx; 
			regs[10] <= 32'bx; regs[11] <= 32'bx; regs[12] <= 32'bx; regs[13] <= 32'bx; regs[14] <= 32'bx; 
			regs[15] <= 32'bx; regs[16] <= 32'bx; regs[17] <= 32'bx; regs[18] <= 32'bx; regs[19] <= 32'bx; 
			regs[20] <= 32'bx; regs[21] <= 32'bx; regs[22] <= 32'bx; regs[23] <= 32'bx; regs[24] <= 32'bx; 
			regs[25] <= 32'bx; regs[26] <= 32'bx; regs[27] <= 32'bx; regs[28] <= 32'bx; regs[29] <= 32'bx; 
			regs[30] <= 32'bx; regs[31] <= 32'bx;
		end
		else begin
			if ((RegWrite)&&(i_Write_reg!=32'b0))
				regs[i_Write_reg] <= i_Write_data;
			else
				regs[i_Write_reg] <= regs[i_Write_reg];
		end
	end
	assign o_Read_data1 = (i_Read_reg1 == 32'b0) ? 32'b0 : regs[i_Read_reg1];
	assign o_Read_data2 = (i_Read_reg2 == 32'b0) ? 32'b0 : regs[i_Read_reg2];

endmodule

//////////////////////////////////////////////////////////////////////////////////

