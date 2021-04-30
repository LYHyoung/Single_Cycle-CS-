`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  KWU
// Engineer: SWL
// 
// Create Date:    03/17/2021 
// Module Name:    MyControl 
// Project Name:   Single Cycle Processor
//
// Revision: 
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module MyControl(op,func,RegDst,Jump,Branch,MemtoReg,ALUop,ALUsrc,ALUctrl,MemWrite,DatWidth,RegWrite,RegDatSel,ExtMode);
	input [5:0] op, func;
	output reg MemtoReg, ExtMode, MemWrite, RegWrite;
	output reg [1:0] RegDst, RegDatSel, Jump, DatWidth, ALUsrc;
	output reg [2:0] Branch;
	output reg [4:0] ALUop; 
	output reg [3:0] ALUctrl;

	always@(*) begin
		if(op==6'b000000) begin   // R_TYPE
      if (func==6'b101010) begin    // R-type slt
  			ALUop    = 5'b10000;  
			ALUctrl  = 4'b0000;
			RegDst   = 2'b01;     
			ALUsrc   = 2'b00;
			RegWrite = 1'b1;      
			MemtoReg = 1'b0;    
			MemWrite = 1'b0;      
			DatWidth = 2'b00;
			Jump     = 2'b00;     
			Branch   = 3'b000;    
			RegDatSel= 2'b00;     
			ExtMode  = 1'bx; 
  		end
      else if (func==6'b100111) begin    // R-type nor
  			ALUop    = 5'b00010;  
			ALUctrl  = 4'b0000;
			RegDst   = 2'b01;     
			ALUsrc   = 2'b00;
			RegWrite = 1'b1;     
			MemtoReg = 1'b0;    
			MemWrite = 1'b0;      
			DatWidth = 2'b00;
			Jump     = 2'b00;     
			Branch   = 3'b000;    
			RegDatSel= 2'b00;     
			ExtMode  = 1'bx; 
  		end
		else if (func==6'b000111) begin  	// R-type SRAV
			ALUop    = 5'b01111;  
			ALUctrl  = 4'b0001;
			RegDst   = 2'b01;     
			ALUsrc   = 2'b00;
			RegWrite = 1'b1;     
			MemtoReg = 1'b0;    
			MemWrite = 1'b0;      
			DatWidth = 2'b00;
			Jump     = 2'b00;     
			Branch   = 3'b000;    
			RegDatSel= 2'b00;     
			ExtMode  = 1'bx; 
		end
		else if (func==6'b010010) begin  	// R-type mflo
			ALUop    = 5'b10011;  
			ALUctrl  = 4'b0000;
			RegDst   = 2'b01;     
			ALUsrc   = 2'b00;
			RegWrite = 1'b1;      
			MemtoReg = 1'b0;    
			MemWrite = 1'b0;      
			DatWidth = 2'b00;
			Jump     = 2'b00;     
			Branch   = 3'b000;    
			RegDatSel= 2'b01;     
			ExtMode  = 1'bx; 
		end
		else if (func==6'b011000) begin  	// R-type mult
			ALUop    = 5'b01001;  
			ALUctrl  = 4'b0000;
			RegDst   = 2'b01;     
			ALUsrc   = 2'b00;
			RegWrite = 1'b1;      
			MemtoReg = 1'b0;    
			MemWrite = 1'b0;      
			DatWidth = 2'b00;
			Jump     = 2'b00;     
			Branch   = 3'b000;    
			RegDatSel= 2'b00;     
			ExtMode  = 1'bx; 
		end
      else begin    // UNDEFINED INSTRUCTION. DO NOT MODIFY.
  			ALUop    = 5'bxxxxx; RegDst   = 2'bxx; ALUsrc   = 2'bxx;
  			RegWrite = 1'bx;     MemtoReg = 1'bx;  MemWrite = 1'bx;    
        DatWidth = 2'bxx;    Jump     = 2'bxx; Branch   = 3'bxxx;
        RegDatSel= 2'bxx;    ExtMode  = 1'bx;  ALUctrl  = 4'bxxxx;
  		end
		end
		else if(op==6'b000100) begin // beq
			ALUop    = 5'b00110;
			ALUctrl  = 4'b0000;
			RegDst   = 2'bxx;     
			ALUsrc   = 2'b00;   
			RegWrite = 1'b0;        
			MemtoReg = 1'bx;   
			MemWrite = 1'b0;        
			DatWidth = 2'b00;
			Jump     = 2'b00;       
			Branch   = 3'b100;       
			RegDatSel= 2'b00;       
			ExtMode  = 1'b0; 
		end
		else if(op==6'b000111) begin 		// bgtz
			ALUop    = 5'b00110;  
			ALUctrl  = 4'b0000;
			RegDst   = 2'bxx;     
			ALUsrc   = 2'b00;     	
			RegWrite = 1'b0;        
			MemtoReg = 1'bx;   
			MemWrite = 1'b0;        
			DatWidth = 2'b00;  
			Jump     = 2'b00;       
			Branch   = 3'b111;       
			RegDatSel= 2'b00;       
			ExtMode  = 1'b0; 
		end
		else if(op==6'b001000) begin 		// addi
			ALUop    = 5'b00100;  
			ALUctrl  = 4'b0000; 
			RegDst   = 2'b01;    
			ALUsrc   = 2'b01;     
			RegWrite = 1'b1;        
			MemtoReg = 1'b0;  
			MemWrite = 1'b0;       
			DatWidth = 2'b00; 
			Jump     = 2'b00;      
			Branch   = 3'b000;      
			RegDatSel= 2'b00;      
			ExtMode  = 1'bx; 
		end
		else if(op==6'b001010) begin 		// slti
			ALUop    = 5'b10000;   
			ALUctrl  = 4'b0000;  
			RegDst   = 2'b00;    
			ALUsrc   = 2'b01;     
			RegWrite = 1'b1;       
			MemtoReg = 1'b0;  
			MemWrite = 1'b0;        
			DatWidth = 2'b00; 
			Jump     = 2'b00;       
			Branch   = 3'b000;      
			RegDatSel= 2'b00;       
			ExtMode  = 1'bx; 
		end
		else if(op==6'b001110) begin 		// xori
			ALUop    = 5'b00011;   
			ALUctrl  = 4'b0000; 
			RegDst   = 2'b01;    
			ALUsrc   = 2'b01;     
			RegWrite = 1'b1;       
			MemtoReg = 1'b0;  
			MemWrite = 1'b0;       
			DatWidth = 2'b00;
			Jump     = 2'b00;      
			Branch   = 3'b000;      
			RegDatSel= 2'b00;      
			ExtMode  = 1'bx; 
		end
		else if(op==6'b000011) begin 		// jal
			ALUop    = 5'bxxxxx;  	
			ALUctrl  = 4'bxxxx;
			RegDst   = 2'b10;     
			ALUsrc   = 2'bxx;     		
			RegWrite = 1'b1;   			
			MemtoReg = 1'bx;   
			MemWrite = 1'b0;   			
			DatWidth = 2'bxx;	
			Jump     = 2'b01;     		
			Branch   = 3'bxxx;    
			RegDatSel= 2'bxx; 			
			ExtMode  = 1'b1; 
		end
		else if(op==6'b001000) begin 		// jr
			ALUop    = 5'bxxxxx;  	
			ALUctrl  = 4'bxxxx;	
			RegDst   = 2'bxx;     
			ALUsrc   = 2'bxx;     	
			RegWrite = 1'b0;   			
			MemtoReg = 1'bx;   
			MemWrite = 1'b0;   			
			DatWidth = 2'bxx;	
			Jump     = 2'b10;     		
			Branch   = 3'bxxx;    
			RegDatSel= 2'bxx; 			
			ExtMode  = 1'bx; 
		end
		else begin   // UNDEFINED INSTRUCTION. DO NOT MODIFY.
			ALUop    = 5'bxxxxx; RegDst   = 2'bxx; ALUsrc   = 2'bxx;  
			RegWrite = 1'bx;     MemtoReg = 1'bx;  MemWrite = 1'bx;
      DatWidth = 2'bxx;    Jump     = 2'bxx; Branch   = 3'bxxx;  
			RegDatSel= 2'bxx;    ExtMode  = 1'bx;  ALUctrl  = 4'bxxxx;
		end
	end
endmodule
