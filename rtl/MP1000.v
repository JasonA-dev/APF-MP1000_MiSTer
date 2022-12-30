module MP1000 (
	input              clk_sys,
	input              reset,
	
	input wire         ioctl_download,
	input wire   [7:0] ioctl_index,
	input wire         ioctl_wr,
	input       [24:0] ioctl_addr,
	input        [7:0] ioctl_dout,

	input       [10:0] ps2_key,
	output  reg        ce_pix,

	output reg         HBlank,
	output reg         HSync,
	output reg         VBlank,
	output reg         VSync,
	output reg         video_de,
	output wire [7:0]  red,
	output wire [7:0]  green,
	output wire [7:0]  blue
);

reg [3:0] clk_vid;
always @(posedge clk_sys)
  clk_vid <= clk_vid + 4'd1;

wire rw;
reg [15:0] address;

mc6801_core mc6801
(
	.clk(clk_sys), 			// I
	.rst(reset),			// I
	.rw(rw),				// O
	.vma(),					// O
	.address(address),		// O [15:0]
	.data_in(ram_dout_b),	// I [7:0]
	.data_out(ram_din_b),	// O [7:0]
	.hold(),				// I
	.halt(),				// I
	.irq(),					// I
	.nmi(),					// I
	.irq_icf(),				// I
	.irq_ocf(),				// I
	.irq_tof(),				// I
	.irq_sci(),				// I
	.test_alu(),			// O [15:0]
	.test_cc()				// O [7:0]
);

reg [12:0] vdg_addr;
reg [7:0]  ram_din_b;
reg [7:0]  ram_dout_b;

mc6847 mc6847
(
  .clk(clk_sys),			// I
  .clk_ena(clk_vid[2]), 	// I clk_vid[2]
  .reset(reset),			// I
  .da0(),					// O
  .videoaddr(vdg_addr), 	// O [12:0] vdg_addr
  .dd(ram_dout_b), 			// I [7:0] ram_dout_b
  .an_g(), 					// I U8[3]
  .an_s(ram_dout_b[7]), 	// I ram_dout_b[7]
  .intn_ext(), 				// I U8[0]
  .gm(), 					// I [2:0] { U8[0], U8[1], U8[2] }
  .css(), 					// I U8[4]
  .inv(ram_dout_b[6]), 		// I ram_dout_b[6]
  .red(red),  				// O [7:0]
  .green(green), 			// O [7:0]
  .blue(blue), 				// O [7:0]
  .hsync(HSync),			// O
  .vsync(VSync),			// O
  .hblank(HBlank),			// O
  .vblank(VBlank),			// O
  .artifact_en(1'b1),		// I
  .artifact_set(1'b0),		// I
  .artifact_phase(1'b1),	// I
  .cvbs(),					// O [7:0]
  .black_backgnd(1'b1),		// I
  .pixel_clk(ce_pix)		// O
);

pia6821 pia6821
(
	.clk(clk_sys), 	// I
	.rst(reset), 	// I
	.cs(), 			// I
	.rw(), 			// I
	.addr(),  		// I [1:0]
	.data_in(), 	// I [7:0] 
	.data_out(),	// O [7:0] 
	.irqa(), 		// O
	.irqb(), 		// O
	.pa_i(),  		// I [7:0]
	.pa_o(), 		// O [7:0]
	.pa_oe(), 		// O [7:0]
	.ca1(), 		// I
	.ca2_i(), 		// I
	.ca2_o(), 		// O
	.ca2_oe(), 		// O
	.pb_i(),		// I [7:0] 
	.pb_o(), 		// O [7:0]
	.pb_oe(),		// O [7:0] 
	.cb1(), 		// I
	.cb2_i(), 		// I
	.cb2_o(), 		// O
	.cb2_oe() 		// O
);

wire  [7:0]  romDo_apf4000;
wire [10:0]  romA;
rom #(.AW(11), .FN("../bios/mame/apf_4000.hex")) Rom_APF4000
(
	.clock      (clk_sys        ),
	.ce         (1'b1           ),
	.data_out   (romDo_apf4000  ),
	.a          (romA[10:0]     )
);
/*
wire  [7:0]  romDo_modbios;
wire [11:0]  romB;
rom #(.AW(16), .FN("../bios/mame/mod-bios.hex")) Rom_modbios
(
	.clock      (clk_sys        ),
	.ce         (1'b1           ),
	.data_out   (romDo_modbios  ),
	.a          (romB[10:0]     )
);

wire  [7:0]  romDo_trashii;
wire [11:0]  romC;
rom #(.AW(16), .FN("../bios/mame/trash-ii.hex")) Rom_trashii
(
	.clock      (clk_sys        ),
	.ce         (1'b1           ),
	.data_out   (romDo_trashii  ),
	.a          (romC[10:0]     )
);
*/

reg  [15:0]  ram_a;  // RAM address

//64k BRAM covering the Imagination Engine Memory Map fully
dpram #(8, 16) dpram
(
	.clk_sys(clk_sys),

	.ram_we(ioctl_wr | cpu_wr),
	.ram_ad(ioctl_download ? ioctl_addr[11:0] + 'h4000 : ram_a),  
	.ram_d(ioctl_download ? ioctl_dout : ram_d),
	.ram_q(ram_q),

	.ram_we_b(rw),
	.ram_ad_b(address),
	.ram_d_b(ram_din_b),
	.ram_q_b(ram_dout_b)
);

endmodule