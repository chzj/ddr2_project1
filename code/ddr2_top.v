module ddr2_top(
	input  wire  local_clk_50m,
	input reset_n,
	output err,
	output  wire  mem_cs_n,
	output  wire  mem_cke,
	output  wire[12: 0]  mem_addr,
	output  wire[2 : 0]  mem_ba,
	output  wire  mem_ras_n,
	output  wire  mem_cas_n,
	output  wire  mem_we_n, 
	inout  wire  mem_clk,
	inout  wire  mem_clk_n,
	output  wire[3 : 0]  mem_dm,
	inout  wire[31: 0]  mem_dq, 
	inout  wire[3 : 0]  mem_dqs, 
	
	output	mem_odt
);
parameter MEM_DATA_BITS = 128;
parameter IDLE = 3'd0;
parameter MEM_READ = 3'd1;
parameter MEM_WRITE  = 3'd2;
reg[2:0] state;
reg[2:0] next_state;
//assign mem_odt = 1'b0;
reg[31:0] rst_cnt;
reg rst_n;
always@(posedge	local_clk_50m)
	begin
		if(rst_cnt != 32'hfffff)
			rst_cnt <= rst_cnt + 32'd1;
	end
always@(posedge	local_clk_50m)
	begin
		rst_n <= rst_cnt == 32'hfffff;
	end
always@(posedge	phy_clk)
	begin
		if(~local_init_done)
			state <= IDLE;
		else	
			state <= next_state;
	end
always@(*)
	begin
		case(state)
			IDLE:
				next_state <= MEM_WRITE;
			MEM_WRITE:
				if(burst_finish)
					next_state <= MEM_READ;
				else
					next_state <= MEM_WRITE;
			MEM_READ:
				if(burst_finish)
					next_state <= MEM_WRITE;
				else
					next_state <= MEM_READ;
			default: 
				next_state <= IDLE;
		endcase
end
reg[23:0] wr_burst_addr;
wire[23:0] rd_burst_addr;
wire wr_burst_data_req;
wire rd_burst_data_valid;
reg[9:0] wr_burst_len;
reg[9:0] rd_burst_len;
reg wr_burst_req;
reg rd_burst_req;
reg[9:0] wr_cnt;
reg[9:0] rd_cnt;
wire[MEM_DATA_BITS - 1:0] wr_burst_data;
wire[MEM_DATA_BITS - 1:0] rd_burst_data;
always@(posedge phy_clk)
	begin
		if(state == IDLE && next_state == MEM_WRITE)
			wr_burst_addr <= 24'd0;
		else if(state == MEM_READ && next_state == MEM_WRITE)
			wr_burst_addr <= wr_burst_addr + 24'd128;
		else
			wr_burst_addr <= wr_burst_addr;
	end
assign rd_burst_addr = wr_burst_addr;
assign wr_burst_data = {MEM_DATA_BITS/8{wr_cnt[7:0]}};
always@(posedge phy_clk)
	begin
		if(next_state == MEM_WRITE && state != MEM_WRITE)
			begin
				wr_burst_req <= 1'b1;
				wr_burst_len <= 10'd128;
				wr_cnt <= 10'd0;
			end
		else if(wr_burst_data_req)
			begin
				wr_burst_req <= 1'b0;
				wr_burst_len <= 10'd128;
				wr_cnt <= wr_cnt + 10'd1;
			end
		else
			begin
				wr_burst_req <= wr_burst_req;
				wr_burst_len <= 10'd128;
				wr_cnt <= wr_cnt;
			end
	end
	
always@(posedge phy_clk)
	begin
		if(next_state == MEM_READ && state != MEM_READ)
			begin
				rd_burst_req <= 1'b1;
				rd_burst_len <= 10'd128;
				rd_cnt <= 10'd1;
			end
		else if(rd_burst_data_valid )
			begin
				rd_burst_req <= 1'b0;
				rd_burst_len <= 10'd128;
				rd_cnt <= rd_cnt + 10'd1;
			end
		else
			begin
				rd_burst_req <= rd_burst_req;
				rd_burst_len <= 10'd128;
				rd_cnt <= rd_cnt;
			end
	end
assign err = rd_burst_data_valid &(rd_burst_data != {MEM_DATA_BITS/8{rd_cnt[7:0]}});
wire	[23:0]	local_address;
wire		local_write_req;
wire		local_read_req;
wire	[MEM_DATA_BITS - 1:0]	local_wdata;
wire	[MEM_DATA_BITS/8 - 1:0]	local_be;
wire	[2:0]	local_size;
wire		local_ready;
wire local_burstbegin;
wire	[MEM_DATA_BITS - 1:0]	local_rdata;
wire		local_rdata_valid;
wire		local_refresh_ack;
wire		local_wdata_req;
wire		local_init_done;
wire		phy_clk;
wire		aux_full_rate_clk;
wire		aux_half_rate_clk;
wire burst_finish;
mem_burst_v2#(.MEM_DATA_BITS(MEM_DATA_BITS)) mem_burst_m0(
	.rst_n(1'b1),
	.mem_clk(phy_clk),
	.rd_burst_req(rd_burst_req),
	.wr_burst_req(wr_burst_req),
	.rd_burst_len(rd_burst_len),
	.wr_burst_len(wr_burst_len),
	.rd_burst_addr(rd_burst_addr),
	.wr_burst_addr(wr_burst_addr),
	.rd_burst_data_valid(rd_burst_data_valid),
	.wr_burst_data_req(wr_burst_data_req),
	.rd_burst_data(rd_burst_data),
	.wr_burst_data(wr_burst_data),
	.burst_finish(burst_finish),
	///////////////////
	.local_init_done(local_init_done),
	.local_ready(local_ready),
	.local_burstbegin(local_burstbegin),
	.local_wdata(local_wdata),
	.local_rdata_valid(local_rdata_valid),
	.local_rdata(local_rdata),
	.local_write_req(local_write_req),
	.local_read_req(local_read_req),
	.local_address(local_address),
	.local_be(local_be),
	.local_size(local_size)
); 
wire reset_request_n; 
//assign reset_request_n = 1'b1;
ddr2 ddr_m0(
	.local_address(local_address),
	.local_write_req(local_write_req),
	.local_read_req(local_read_req),
	.local_wdata(local_wdata),
	.local_be(local_be),
	.local_size(local_size),
	.global_reset_n(rst_n),
	//.local_refresh_req(1'b0), 
	//.local_self_rfsh_req(1'b0),
	.pll_ref_clk(local_clk_50m),
	.soft_reset_n(1'b1),
	.local_ready(local_ready),
	.local_rdata(local_rdata),
	.local_rdata_valid(local_rdata_valid),
	.reset_request_n(),
	.mem_cs_n(mem_cs_n),
	.mem_cke(mem_cke),
	.mem_addr(mem_addr),
	.mem_ba(mem_ba),
	.mem_ras_n(mem_ras_n),
	.mem_cas_n(mem_cas_n),
	.mem_we_n(mem_we_n),
	.mem_dm(mem_dm),
	.local_refresh_ack(),
	.local_burstbegin(local_burstbegin),
	.local_init_done(local_init_done),
	.reset_phy_clk_n(),
	.phy_clk(phy_clk),
	.aux_full_rate_clk(),
	.aux_half_rate_clk(),
	.mem_clk(mem_clk),
	.mem_clk_n(mem_clk_n),
	.mem_dq(mem_dq),
	.mem_dqs(mem_dqs),
	.mem_odt(mem_odt)
	);
endmodule 