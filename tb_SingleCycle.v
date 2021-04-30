`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:  KWU
// Engineer: SWL
// 
// Create Date:    03/17/2021 
// Module Name:    Testbench 
// Project Name:   Single Cycle Processor
//
// Revision: 
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module tb_SingleCycle;

	reg tb_i_clk;
	reg tb_i_rst_n;
	wire [31:0] tb_out_pc;
	
	integer fp, idx;

	always #5 tb_i_clk = ~tb_i_clk;  // clock assign

	SingleCycle SC_CPU(tb_i_clk, tb_i_rst_n, tb_out_pc);

  always @(posedge tb_i_clk) begin
    if (tb_out_pc==32'b0) begin
  	  fp = $fopen("mem_dump.txt","w");
      for (idx = 0; idx < 256; idx = idx + 4) begin
        $fwrite(fp,"%b ", SC_CPU.U6_DM.mem[idx]);
        $fwrite(fp,"%b ", SC_CPU.U6_DM.mem[idx+1]);
        $fwrite(fp,"%b ", SC_CPU.U6_DM.mem[idx+2]);
        $fwrite(fp,"%b : ", SC_CPU.U6_DM.mem[idx+3]);
        $fwrite(fp,"%h", SC_CPU.U6_DM.mem[idx]);
        $fwrite(fp,"%h", SC_CPU.U6_DM.mem[idx+1]);
        $fwrite(fp,"%h", SC_CPU.U6_DM.mem[idx+2]);
        $fwrite(fp,"%h\n", SC_CPU.U6_DM.mem[idx+3]);
      end
      $fclose(fp);
  	  fp = $fopen("reg_dump.txt","w");
      for (idx = 0; idx < 32; idx = idx + 1) begin
        $fwrite(fp,"%b ", SC_CPU.U2_RF.regs[idx][31:24]);
        $fwrite(fp,"%b ", SC_CPU.U2_RF.regs[idx][23:16]);
        $fwrite(fp,"%b ", SC_CPU.U2_RF.regs[idx][15:8]);
        $fwrite(fp,"%b : ", SC_CPU.U2_RF.regs[idx][7:0]);
        $fwrite(fp,"%h\n", SC_CPU.U2_RF.regs[idx]);
      end
      $fclose(fp);
      end
  end

	initial	begin
    $dumpfile("tb_SC.vcd");
    $dumpvars(0,SC_CPU);
  
		tb_i_clk = 1'b0;
		tb_i_rst_n = 1'b0;

		#7; 		tb_i_rst_n=1'b1;

		#300;   // simulation wrap up here


		$finish;
	end 
endmodule 

