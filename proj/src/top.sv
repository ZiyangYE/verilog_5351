module top(
    input clk,
    input rst_n,

    inout sda,
    inout scl,

    output observ_scl,
    output observ_sda,

    input single_end_i,
    output single_end_o,

    output init_done,

    output [2:0] twi_mux
);

assign twi_mux = 3'b100;
//assign twi_mux = 3'b011;

wire sda_out;
wire scl_out;

assign sda = sda_out? 1'bz : sda_out;
assign scl = scl_out? 1'bz : scl_out;

wire wr_req;
wire [7:0] wr_addr;
wire [7:0] wr_data;
wire wr_fin;
wire wr_ack;

wire rd_req;
wire [7:0] rd_addr;
wire [7:0] rd_data;
wire rd_fin;
wire rd_ack;


simple_iic #(
    .clk_freq(50_000_000),
    .iic_freq(200_000)
) iic(
    .clk(clk),
    .reset_n(rst_n),

    .dev_addr(7'h60),

    .scl(scl_out),
    .sda(sda_out),
    .sda_in(sda),

    .wr_req(wr_req),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .wr_fin(wr_fin),
    .wr_ack(wr_ack),

    .rd_req(rd_req),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
    .rd_fin(rd_fin),
    .rd_ack(rd_ack)
);

assign observ_scl = scl;
assign observ_sda = sda;
assign single_end_o = single_end_i;

v5351 #(
    .dif_out_en(1'b0),
    .sie_out_en(1'b1),
    .dif_freq(125_000_000),
    .sie_freq(10_000_000)
)v5351_inst(
    .clk(clk),
    .reset_n(rst_n),

    .init_done(init_done),

    .wr_req(wr_req),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .wr_fin(wr_fin),
    .wr_ack(wr_ack),

    .rd_req(rd_req),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
    .rd_fin(rd_fin),
    .rd_ack(rd_ack)
);


endmodule