module MP1000 (
	input              clk_sys,
	input              clk_vid,
	input              reset,
	
	input wire         ioctl_download,
	input wire   [7:0] ioctl_index,
	input wire         ioctl_wr,
	input       [24:0] ioctl_addr,
	input        [7:0] ioctl_dout,

	input       [10:0] ps2_key,
	input  reg         ce_pix,

	output reg         HBlank,
	output reg         HSync,
	output reg         VBlank,
	output reg         VSync,
	output reg         video_de,
	output             video
);

/*
mc6847 U11(
  .clk(clk_vid[1]),
  .clk_ena(clk_vid[2]),
  .reset(reset),
  .da0(),
  .videoaddr(vdg_addr),
  .dd(ram_dout_b),
  .an_g(U8[3]),
  .an_s(ram_dout_b[7]),
  .intn_ext(U8[0]),
  .gm({ U8[0], U8[1], U8[2] }),
  .css(U8[4]),
  .inv(ram_dout_b[6]),
  .red(red),
  .green(green),
  .blue(blue),
  .hsync(hsync),
  .vsync(vsync),
  .hblank(hblank),
  .vblank(vblank),
  .artifact_en(1'b1),
  .artifact_set(1'b0),
  .artifact_phase(1'b1),
  .cvbs(),
  .black_backgnd(1'b1),
  .pixel_clk(ce_pix)
);
*/

dpram #(8, 12) dpram
(
	.clk_sys(clk_sys),

	.ram_we(),
	.ram_ad(),
	.ram_d(),
	.ram_q(),

	.ram_we_b(),
	.ram_ad_b(),
	.ram_d_b(),
	.ram_q_b()
);


endmodule