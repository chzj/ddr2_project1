module mem_burst(
	input rst_n,
	input mem_clk,
	input rd_burst_req,
	input wr_burst_req,
	input[9:0] rd_burst_len,
	input[9:0] wr_burst_len,
	input[23:0] rd_burst_addr,
	input[23:0] wr_burst_addr,
	output rd_burst_data_valid,
	output wr_burst_data_req,
	output[63:0] rd_burst_data,
	input[63:0] wr_burst_data,
	output burst_finish,
	
	///////////////////
	input local_initial_done,
	input local_ready,
	input local_wdata_req,
	output[63:0] local_wdata,
	input local_rdata_valid,
	input[63:0] local_rdata,
	output local_write_req,
	output local_read_req,
	output reg[23:0] local_address,
	output[7:0] local_be,
	output [1:0] local_size
);
parameter IDLE = 3'd0;
parameter MEM_READ = 3'd1;
parameter MEM_READ_WAIT = 3'd2;
parameter MEM_WRITE  = 3'd3;
parameter MEM_WRITE_WAIT = 3'd4;
reg[2:0] state;
reg[2:0] next_state;	
reg[9:0] rd_addr_cnt;
reg[9:0] rd_data_cnt;
reg[9:0] wr_addr_cnt;
reg[9:0] wr_data_cnt;
reg[9:0] length;
wire wr_addr_gen_finish;
assign wr_addr_gen_finish = (wr_addr_cnt + 10'd2 >= length) && local_write_req && local_ready;
always@(posedge	mem_clk)
	begin
		if(~local_initial_done || ~rst_n)
			state <= IDLE;
		else	
			state <= next_state;
	end
always@(*)
	begin
		case(state)
			IDLE:
				begin
					if(rd_burst_req)
						next_state <= MEM_READ;
					else if(wr_burst_req)
						next_state <= MEM_WRITE;
					else
						next_state <= IDLE;
				end
			MEM_READ:
				begin
					if( (rd_addr_cnt + 10'd2 >= length) && local_read_req && local_ready)
						next_state <= MEM_READ_WAIT;
					else
						next_state <= MEM_READ;
				end
			MEM_READ_WAIT:
				begin 
					if(rd_data_cnt == length - 10'd1 && local_rdata_valid)
						next_state <= IDLE;
					else
						next_state <= MEM_READ_WAIT;
				end
			MEM_WRITE:
				begin
					if(wr_addr_gen_finish)
						next_state <= MEM_WRITE_WAIT;
					else
						next_state <= MEM_WRITE;
				end
			MEM_WRITE_WAIT:
				begin
					if(wr_data_cnt == length - 10'd1 && local_wdata_req)
						next_state <= IDLE;
					else
						next_state <= MEM_WRITE_WAIT;
				end
			default:
				next_state <= IDLE;
		endcase
	end
always@(posedge	mem_clk)
	begin
		case(state)
			IDLE:
				begin
					if(rd_burst_req)
						begin
							local_address <= rd_burst_addr;
							rd_addr_cnt <= 10'd0;
							wr_addr_cnt <= 10'd0;
						end
					else if(wr_burst_req)
						begin
							local_address <= wr_burst_addr;
							rd_addr_cnt <= 10'd0;
							wr_addr_cnt <= 10'd0;
						end
					else
						begin
							local_address <= local_address;
							rd_addr_cnt <= 10'd0;
							wr_addr_cnt <= 10'd0;
						end
				end
			MEM_READ:
				begin
					if(local_ready)
						begin
							local_address <= local_address + 24'd2;
							rd_addr_cnt <= rd_addr_cnt + 10'd2;
							wr_addr_cnt <= 10'd0;
						end
					else
						begin
							local_address <= local_address;
							rd_addr_cnt <= rd_addr_cnt;
							wr_addr_cnt <= 10'd0;
						end		
				end
			MEM_WRITE:
				begin
					if(local_ready)
						begin
							local_address <= local_address + 24'd2;
							wr_addr_cnt <= wr_addr_cnt + 10'd2;
							rd_addr_cnt <= 10'd0;
						end
					else
						begin
							local_address <= local_address;
							wr_addr_cnt <= wr_addr_cnt;
							rd_addr_cnt <= 10'd0;
						end	
				end
			default:
				begin
					local_address <= local_address;
					rd_addr_cnt <= 10'd0;
					wr_addr_cnt <= 10'd0;
				end
		endcase
	end
always@(posedge	mem_clk)
	begin
		if(state == IDLE && rd_burst_req)
			length <= rd_burst_len;
		else if(state == IDLE && wr_burst_req)
			length <= wr_burst_len;
		else
			length <= length;
	end

always@(posedge	mem_clk)
	begin
		if(state == MEM_READ || state == MEM_READ_WAIT)
			if(local_rdata_valid)
				rd_data_cnt <= rd_data_cnt + 10'd1;
			else
				rd_data_cnt <= rd_data_cnt;
		else
			rd_data_cnt <= 10'd0;
	end
	
always@(posedge	mem_clk)
	begin
		if(state == MEM_WRITE || state == MEM_WRITE_WAIT)
			if(local_wdata_req)
				wr_data_cnt <= wr_data_cnt + 10'd1;
			else
				wr_data_cnt <= wr_data_cnt;
		else
			wr_data_cnt <= 10'd0;
	end
assign rd_burst_data_valid = local_rdata_valid;
assign wr_burst_data_req = local_wdata_req;
assign rd_burst_data = local_rdata;
assign local_wdata = wr_burst_data;
assign local_read_req = (state == MEM_READ);
assign local_write_req = (state == MEM_WRITE);
assign burst_finish = (state == MEM_WRITE_WAIT || state == MEM_READ_WAIT) && (next_state == IDLE);
assign local_be = 8'hff;
assign local_size = ((length - rd_addr_cnt == 10'd1) || (length - wr_addr_cnt == 10'd1)) ? 2'd1 : 2'd2;
endmodule 