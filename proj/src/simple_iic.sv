module simple_iic #(
    parameter clk_freq = 100_000_000, // 100M
    parameter iic_freq = 100_000 // 100k
)(
    input clk, 
    input reset_n,

    input [6:0] dev_addr,

    output scl,
    output sda,
    input sda_in,
    
    input wr_req,
    input [7:0] wr_addr,
    input [7:0] wr_data,
    output reg wr_fin,
    output reg wr_ack,

    input rd_req,
    input [7:0] rd_addr,
    output reg [7:0] rd_data,
    output reg rd_fin,
    output reg rd_ack
);

//假装一直会ack

// I2C 工作状态
reg [2:0] status;

// I2C 数据寄存器
reg [19:0] iic_in;
reg [49:0] iic_out;
reg [99:0] iic_ck;

// I2C 时钟计数器
localparam clk_div_quad = clk_freq / (iic_freq * 4);
reg [15:0] iic_clk_cnt;
reg clk_tick;

reg [7:0] ticks;


always@(posedge clk)begin
    clk_tick <= 0;
    if(iic_clk_cnt == 0)begin
        clk_tick <= 1;
        iic_clk_cnt <= clk_div_quad;
    end else begin
        iic_clk_cnt <= iic_clk_cnt - 1;
    end
end

reg scl_reg;


reg sda_reg;

reg proc_write;


localparam START_COND = 2'b10;
localparam STOP_COND = 2'b01;
localparam WAIT_ACK = 1'b1;
localparam ACK_COND = 1'b0;
localparam NACK_COND = 1'b1;

localparam RD_IDLE = 8'hff;

localparam WR_ADR = 1'b0;
localparam RD_ADR = 1'b1;


always@(posedge clk or negedge reset_n)begin
    if(~reset_n)begin
        sda_reg <= 1;
        scl_reg <= 1;
        wr_ack <= 0;
        wr_fin <= 0;
        rd_ack <= 0;
        rd_fin <= 0;

        ticks <= 0;
    end else begin
        wr_ack <= 0;
        wr_fin <= 0;
        rd_ack <= 0;
        rd_fin <= 0;

        if(clk_tick)begin
            if(ticks != 0)begin
                ticks <= ticks - 1;

                if(ticks[0] == 1'b0)begin
                    scl_reg <= iic_ck[99];
                    iic_ck <= {iic_ck[98:0], scl_reg};
                end

                if(ticks[1:0] == 2'b00)begin
                    iic_in <= {iic_in[18:0], sda_in};
                end
                    
                if(ticks[1:0] == 2'b11)begin
                    sda_reg <= iic_out[49];
                    iic_out <= {iic_out[48:0], 1'b0};
                end

                if(ticks == 1)begin
                    if(proc_write)begin
                        wr_ack <= 1;
                        wr_fin <= 1;
                    end else begin
                        rd_ack <= 1;
                        rd_fin <= 1;
                        rd_data <= iic_in[9:2];
                    end
                end

            end

            if(ticks == 0)begin
                if(wr_req)begin
                    proc_write <= 1;
                    ticks <= 62*2;

                    iic_ck <= {>>{
                        {4{1'b1}}, {7{2'b01}}, 2'b01, 2'b01,
                        {8{2'b01}}, 2'b01, {8{2'b01}}, 2'b01, 4'b0111
                    }};

                    iic_out <= {>>{START_COND, dev_addr, WR_ADR, WAIT_ACK,
                        wr_addr, WAIT_ACK, wr_data, WAIT_ACK, STOP_COND}};


                end else if(rd_req)begin
                    proc_write <= 0;
                    ticks <= 88*2;

                    iic_ck <= {>>{
                        {4{1'b1}}, {8{2'b01}}, 2'b01,
                        {8{2'b01}}, 2'b01, 4'b0111,
                        {4{1'b1}}, {8{2'b01}}, 2'b01,
                        {8{2'b01}}, 2'b01, 4'b0111
                    }};

                    iic_out <= {>>{START_COND, dev_addr, WR_ADR, WAIT_ACK,
                        rd_addr, WAIT_ACK, STOP_COND, 
                        START_COND, dev_addr, RD_ADR, WAIT_ACK,
                        RD_IDLE, NACK_COND, STOP_COND}};
                end
            end
        end
    end
end

assign scl = scl_reg;
assign sda = sda_reg;

endmodule
