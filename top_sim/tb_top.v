//                              -*- Mode: Verilog -*-
// Filename        : tb_prove_top.v
// Description     : testbeach
// Author          : Chen ZhiJie
// Created On      : Tue Sep 17 17:44:10 2013
// Last Modified By: Chen ZhiJie
// Last Modified On: Tue Sep 17 17:44:10 2013
// Update Count    : 0
// Status          : Unknown, Use with caution!
`timescale  1ns/1ps


module tb_top;
  reg local_clk_50m;
  reg reset_n;

  
   ddr2_top uut_ddr2_top(
    // Outputs
    .err				(err),
    .mem_cs_n			(mem_cs_n),
    .mem_cke			(mem_cke),
    .mem_addr			(mem_addr[12:0]),
    .mem_ba				(mem_ba[2:0]),
    .mem_ras_n			(mem_ras_n),
    .mem_cas_n			(mem_cas_n),
    .mem_we_n			(mem_we_n),
    .mem_dm				(mem_dm[3:0]),
    .mem_odt			(mem_odt),
    // Inouts
    .mem_clk			(mem_clk),
    .mem_clk_n			(mem_clk_n),
    .mem_dq				(mem_dq[31:0]),
    .mem_dqs			(mem_dqs[3:0]),
    // Inputs
    .local_clk_50m		(local_clk_50m),
    .reset_n			(reset_n));
       
   ddr2_mem_model mem (
    .mem_dq      		(mem_dq),
    .mem_dqs     		(mem_dqs),
    .mem_dqs_n   		(mem_dqs_n),
    .mem_addr   		(a_delayed),
    .mem_ba      		(ba_delayed),
    .mem_clk     		(clk_to_ram),
    .mem_clk_n   		(clk_to_ram_n),
    .mem_cke     		(cke_delayed),
    .mem_cs_n    		(cs_n_delayed),
    .mem_ras_n   		(ras_n_delayed),
    .mem_cas_n   		(cas_n_delayed),
    .mem_we_n    		(we_n_delayed),
    .mem_dm      		(dm_delayed),
    .mem_odt     		(odt_delayed)
    );
    assign a_delayed = a[13 - 1:0] ;
    assign ba_delayed = ba ;
    assign cke_delayed = cke ;
    assign odt_delayed = odt ;
    assign cs_n_delayed = cs_n ;
    assign ras_n_delayed = ras_n ;
    assign cas_n_delayed = cas_n ;
    assign we_n_delayed = we_n ;
    assign dm_delayed = dm ;
   /*
    * clock and reset make
    */
   parameter PERIOD_50 = 10;
   parameter PERIOD_PIX = 20;
   parameter PERIOD_DAT = 125000;

   initial begin
      clk_100m = 0;
      forever
        #(PERIOD_50/2) local_clk_50m = ~local_clk_50m;
   end

      initial begin
      reset_n = 1;

      #30;
      reset_n = 0;
      #600;
   end
   

   
//-----------------------------------------------------------------------

   initial begin 
      $fsdbDumpfile("wave.fsdb");
      $fsdbDumpvars; 
   end
  
endmodule // tb_prove_top
