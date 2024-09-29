/*
By: LAKKA

Only Support OSC 25M

Freq Out from 2400Hz ~ 225MHz

Error < max(2Hz, 1ppm)

*/

module v5351#(
    parameter dif_out_en = 1'b1,
    parameter sie_out_en = 1'b1,
    parameter dif_freq = 125_000_000, // 125M
    parameter sie_freq = 100_000_000 // 100M
)(
    input clk,
    input reset_n,

    output init_done,

    output wr_req,
    output [7:0] wr_addr,
    output [7:0] wr_data,
    input wr_fin,
    input wr_ack,

    output rd_req,
    output [7:0] rd_addr,
    input [7:0] rd_data,
    input rd_fin,
    input rd_ack
);


integer calc_div1_t0;
integer calc_div1_t1;
integer calc_div1_t2;
integer calc_div1_t3;
integer calc_div1_outdiv; // OUTDIV
integer calc_div1_div; // DIV_P1

integer calc_pll1;
integer calc_pll1_af;
integer calc_pll1_p1;
integer calc_pll1_p2;
integer calc_pll1_p3 = 1024;
integer calc_pll1_t0;
integer calc_pll1_f;

integer calc_out1_f;


always_comb begin
    if(dif_freq >= 150_000_000)begin
        calc_pll1 = dif_freq * 4;
        calc_div1_outdiv = 0;
        calc_div1_div = 0;
    end else begin
        // dif_freq / 293968 = 2^calc_div1_outdiv
        calc_div1_t0 = $clog2((2343750 + (dif_freq * 8) - 1) / (dif_freq * 8));
        if(calc_div1_t0 >= 7)begin
            calc_div1_outdiv = 7;
        end else begin
            calc_div1_outdiv = calc_div1_t0;
        end
        calc_div1_t1 = dif_freq * (1 << calc_div1_outdiv);

        calc_div1_t2 = (600000000 + calc_div1_t1 - 1) / calc_div1_t1;

        if(calc_div1_t2 <= 4)begin
            calc_div1_t3 = 4;
        end else if (calc_div1_t2 >= 2048)begin
            calc_div1_t3 = 2048;
        end else begin
            calc_div1_t3 = ((calc_div1_t2 + 1)/2)*2;
        end

        calc_pll1 = calc_div1_t1 * calc_div1_t3;
        
        calc_div1_div = (calc_div1_t3-4)* 128;
    end

    if(calc_pll1 < 600_000_000)begin
        calc_pll1_af = 600_000_000;
    end else if (calc_pll1 > 900_000_000)begin
        calc_pll1_af = 900_000_000;
    end else begin
        calc_pll1_af = calc_pll1;
    end

    calc_pll1_t0 = 2*(calc_pll1_af - 100_000_000);
    calc_pll1_p1 = calc_pll1_t0 / 390625;
    calc_pll1_p2 = ((calc_pll1_t0 - calc_pll1_p1 * 390625)*calc_pll1_p3) / 390625;

    calc_pll1_f = 100000000 + calc_pll1_p1 * 390625 / 2 + calc_pll1_p2 * 390625 / calc_pll1_p3 / 2;
    calc_out1_f = calc_pll1_f / (4 * (1<<calc_div1_outdiv) + (calc_div1_div * (1<<calc_div1_outdiv) / 128));
end


integer calc_div2_t0;
integer calc_div2_t1;
integer calc_div2_t2;
integer calc_div2_t3;
integer calc_div2_outdiv; // OUTDIV
integer calc_div2_div; // DIV_P1

integer calc_pll2;
integer calc_pll2_af;
integer calc_pll2_p1;
integer calc_pll2_p2;
integer calc_pll2_p3 = 1024;
integer calc_pll2_t0;
integer calc_pll2_f;

integer calc_out2_f;


always_comb begin
    if(sie_freq >= 150_000_000)begin
        calc_pll2 = sie_freq * 4;
        calc_div2_outdiv = 0;
        calc_div2_div = 0;
    end else begin
        // sie_freq / 293968 = 2^calc_div2_outdiv
        calc_div2_t0 = $clog2((2343750 + (sie_freq * 8) - 1) / (sie_freq * 8));
        if(calc_div2_t0 >= 7)begin
            calc_div2_outdiv = 7;
        end else begin
            calc_div2_outdiv = calc_div2_t0;
        end
        calc_div2_t1 = sie_freq * (1 << calc_div2_outdiv);

        calc_div2_t2 = (600000000 + calc_div2_t1 - 1) / calc_div2_t1;

        if(calc_div2_t2 <= 4)begin
            calc_div2_t3 = 4;
        end else if (calc_div2_t2 >= 2048)begin
            calc_div2_t3 = 2048;
        end else begin
            calc_div2_t3 = ((calc_div2_t2 + 1)/2)*2;
        end

        calc_pll2 = calc_div2_t1 * calc_div2_t3;
        
        calc_div2_div = (calc_div2_t3-4)* 128;
    end

    if(calc_pll2 < 600_000_000)begin
        calc_pll2_af = 600_000_000;
    end else if (calc_pll2 > 900_000_000)begin
        calc_pll2_af = 900_000_000;
    end else begin
        calc_pll2_af = calc_pll2;
    end

    calc_pll2_t0 = 2*(calc_pll2_af - 100_000_000);
    calc_pll2_p1 = calc_pll2_t0 / 390625;
    calc_pll2_p2 = ((calc_pll2_t0 - calc_pll2_p1 * 390625)*calc_pll2_p3) / 390625;

    calc_pll2_f = 100000000 + calc_pll2_p1 * 390625 / 2 + calc_pll2_p2 * 390625 / calc_pll2_p3 / 2;
    calc_out2_f = calc_pll2_f / (4 * (1<<calc_div2_outdiv) + (calc_div2_div * (1<<calc_div2_outdiv) / 128));
end

wire [7:0] i2c_addr [45:0];
wire [7:0] i2c_data [45:0];

assign i2c_addr[0] = 8'd03; assign i2c_data[0] = 8'h07;
assign i2c_addr[1] = 8'd24; assign i2c_data[1] = 8'hAA;
assign i2c_addr[2] = 8'd16; assign i2c_data[2] = 8'h5F;
assign i2c_addr[3] = 8'd17; assign i2c_data[3] = 8'h4B;
assign i2c_addr[4] = 8'd18; assign i2c_data[4] = 8'h6F;
assign i2c_addr[5] = 8'd42; assign i2c_data[5] = 8'h00;
assign i2c_addr[6] = 8'd43; assign i2c_data[6] = 8'h01;
assign i2c_addr[7] = 8'd47; assign i2c_data[7] = 8'h00;
assign i2c_addr[8] = 8'd48; assign i2c_data[8] = 8'h00;
assign i2c_addr[9] = 8'd49; assign i2c_data[9] = 8'h00;
assign i2c_addr[10] = 8'd58; assign i2c_data[10] = 8'h00;
assign i2c_addr[11] = 8'd59; assign i2c_data[11] = 8'h01;
assign i2c_addr[12] = 8'd63; assign i2c_data[12] = 8'h00;
assign i2c_addr[13] = 8'd64; assign i2c_data[13] = 8'h00;
assign i2c_addr[14] = 8'd65; assign i2c_data[14] = 8'h00;
assign i2c_addr[15] = 8'd149; assign i2c_data[15] = 8'h00;
assign i2c_addr[16] = 8'd150; assign i2c_data[16] = 8'h01;
assign i2c_addr[17] = 8'd161; assign i2c_data[17] = 8'h00;
assign i2c_addr[18] = 8'd165; assign i2c_data[18] = 8'h00;
assign i2c_addr[19] = 8'd166; assign i2c_data[19] = 8'h00;
assign i2c_addr[20] = 8'd167; assign i2c_data[20] = 8'h00;
assign i2c_addr[21] = 8'd183; assign i2c_data[21] = 8'h00;
assign i2c_addr[22] = 8'd187; assign i2c_data[22] = 8'hD2;

assign i2c_addr[23] = 8'd26; assign i2c_data[23] = calc_pll1_p3[15:8];
assign i2c_addr[24] = 8'd27; assign i2c_data[24] = calc_pll1_p3[7:0];
assign i2c_addr[25] = 8'd28; assign i2c_data[25] = {6'b0, calc_pll1_p1[17:16]};
assign i2c_addr[26] = 8'd29; assign i2c_data[26] = calc_pll1_p1[15:8];
assign i2c_addr[27] = 8'd30; assign i2c_data[27] = calc_pll1_p1[7:0];
assign i2c_addr[28] = 8'd31; assign i2c_data[28] = {calc_pll1_p3[19:16], calc_pll1_p2[19:16]};
assign i2c_addr[29] = 8'd32; assign i2c_data[29] = calc_pll1_p2[15:8];
assign i2c_addr[30] = 8'd33; assign i2c_data[30] = calc_pll1_p2[7:0];

assign i2c_addr[31] = 8'd34; assign i2c_data[31] = calc_pll2_p3[15:8];
assign i2c_addr[32] = 8'd35; assign i2c_data[32] = calc_pll2_p3[7:0];
assign i2c_addr[33] = 8'd36; assign i2c_data[33] = {6'b0, calc_pll2_p1[17:16]};
assign i2c_addr[34] = 8'd37; assign i2c_data[34] = calc_pll2_p1[15:8];
assign i2c_addr[35] = 8'd38; assign i2c_data[35] = calc_pll2_p1[7:0];
assign i2c_addr[36] = 8'd39; assign i2c_data[36] = {calc_pll2_p3[19:16], calc_pll2_p2[19:16]};
assign i2c_addr[37] = 8'd40; assign i2c_data[37] = calc_pll2_p2[15:8];
assign i2c_addr[38] = 8'd41; assign i2c_data[38] = calc_pll2_p2[7:0];

assign i2c_addr[39] = 8'd44; assign i2c_data[39] = {1'b0, calc_div1_outdiv[2:0], calc_div1_div == 0 ? 2'b11 : 2'b00, calc_div1_div[17:16]};
assign i2c_addr[40] = 8'd45; assign i2c_data[40] = calc_div1_div[15:8];
assign i2c_addr[41] = 8'd46; assign i2c_data[41] = calc_div1_div[7:0];

assign i2c_addr[42] = 8'd60; assign i2c_data[42] = {1'b0, calc_div2_outdiv[2:0], calc_div2_div == 0 ? 2'b11 : 2'b00, calc_div2_div[17:16]};
assign i2c_addr[43] = 8'd61; assign i2c_data[43] = calc_div2_div[15:8];
assign i2c_addr[44] = 8'd62; assign i2c_data[44] = calc_div2_div[7:0];

assign i2c_addr[45] = 8'd177; assign i2c_data[45] = 8'hAC;



reg [15:0] power_up_cnt;
reg power_up_flag;

reg [3:0] status;

reg reg_init_done;

wire [7:0] i2c_status_addr = 8'd0;

wire [7:0] i2c_oe_addr = 8'd3;
wire [7:0] i2c_oe_data = {5'b11111, sie_freq ? 1'b0 : 1'b1, dif_out_en ? 1'b0 : 1'b1, dif_out_en ? 1'b0 : 1'b1};


reg i2c_req_wr;
reg i2c_req_rd;

reg [7:0] i2c_wr_addr;
reg [7:0] i2c_wr_data;

reg [7:0] i2c_rd_addr;

reg [7:0] i2c_action_addr;

reg [15:0] wait_tick;

// do not check i2c fail, just use i2c fin

always@(posedge clk or negedge reset_n) begin
    if(~reset_n)begin
        power_up_cnt <= 16'h0000;
        power_up_flag <= 1'b0;

        status <= 4'h0;
        i2c_action_addr <= 8'h00;

        i2c_req_wr <= 1'b0;
        i2c_req_rd <= 1'b0;

        reg_init_done <= 1'b0;
    end else begin
        if(power_up_cnt < 16'hFFFF)begin
            power_up_cnt <= power_up_cnt + 1;
        end else begin
            power_up_flag <= 1'b1;
        end


        if(power_up_flag)begin
            case(status)
                0:begin
                    i2c_req_wr <= 1'b1;
                    i2c_wr_addr <= i2c_addr[i2c_action_addr];
                    i2c_wr_data <= i2c_data[i2c_action_addr];
                    status <= 1;
                end
                1:begin
                    if(wr_fin)begin
                        i2c_req_wr <= 1'b0;

                        if(i2c_action_addr == 45)begin
                            status <= 7;
                            wait_tick <= 16'h0000;
                        end else begin
                            i2c_action_addr <= i2c_action_addr + 1;
                            status <= 0;
                        end
                    end
                end
                2:begin
                    i2c_rd_addr <= i2c_status_addr;
                    i2c_req_rd <= 1'b1;
                    status <= 3;
                end
                3:begin
                    if(rd_fin)begin
                        i2c_req_rd <= 1'b0;
                        
                        if(rd_data[6:5] == 2'b00)begin
                            status <= 4;
                        end else begin
                            status <= 2;
                        end
                    end
                end
                4:begin
                    i2c_req_wr <= 1'b1;
                    i2c_wr_addr <= i2c_oe_addr;
                    i2c_wr_data <= i2c_oe_data;
                    status <= 5;
                end
                5:begin
                    if(wr_fin)begin
                        i2c_req_wr <= 1'b0;
                        reg_init_done <= 1'b1;
                        status <= 6;
                    end
                end
                7:begin
                    if(wait_tick < 16'hFFFF)begin
                        wait_tick <= wait_tick + 1;
                    end else begin
                        status <= 2;
                    end
                end
            endcase
        end
    end
end

assign init_done = reg_init_done;
assign wr_req = i2c_req_wr;
assign wr_addr = i2c_wr_addr;
assign wr_data = i2c_wr_data;
assign rd_req = i2c_req_rd;
assign rd_addr = i2c_rd_addr;


endmodule

