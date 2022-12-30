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

wire [7:0] KR, kb_rows;
wire rw;
reg [15:0] address;
wire [12:0] vdg_addr;
reg [7:0]  ram_din_a;
reg [7:0]  ram_dout_a;
reg [7:0]  ram_din_b;
reg [7:0]  ram_dout_b;
wire E_CLK;

// CPU
mc6801_core mc6801
(
	.clk(clk_sys), 			// I
	.rst(reset),			// I
	.rw(rw),				// O
	.vma(),					// O
	.address(address),		// O [15:0]
	.data_in(ram_dout_a),	// I [7:0]
	.data_out(ram_din_a),	// O [7:0]
	.hold(0),				// I
	.halt(0),				// I
	.irq(0),				// I
	.nmi(),					// I
	.irq_icf(),				// I
	.irq_ocf(),				// I
	.irq_tof(),				// I
	.irq_sci(),				// I
	.test_alu(),			// O [15:0]
	.test_cc()				// O [7:0]
);

/*
// CPU
MC6803_gen2 mc6803gen2
(
  .clk(clk_sys), 		// I
  .RST(reset),			// I
  .hold(0),				// I
  .halt(0),				// I
  .irq(0),				// I
  .nmi(),				// I exp_nmi
  .PORT_A_IN(),			// I [7:0] empty
  .PORT_B_IN(reset),	// I [4:0] { cin, rs232_a, rs232_b|reset, shift, reset }
  .DATA_IN(ram_dout_b),	// I [7:0] data_bus
  .PORT_A_OUT(KR),		// O [7:0] KR
  .PORT_B_OUT(),		// O [4:0] empty
  .ADDRESS(address),	// O [15:0] cpu_addr
  .DATA_OUT(ram_din_b),	// O [7:0] cpu_dout
  .E_CLK(E_CLK),		// O E_CLK
  .rw(rw)				// O cpu_rw
);
*/

// VDG
mc6847 mc6847
(
  .clk(clk_sys),			// I
  .clk_ena(1'b1), 	// I clk_vid[2]
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
  .cvbs(),					// O [7:0] empty
  .black_backgnd(1'b1),		// I
  .pixel_clk(ce_pix)		// O
);

wire pia_cs, pia_rw;
assign pia_cs = (address[14:12] == 3'b000 && address[10] == 1'b1) ? 1'b1 : 1'b0;
assign pia_rw = (rw == 1'b0 && pia_cs == 1'b1) ? 1'b1 : 1'b0;

// PIA
pia6821 pia6821
(
	.clk(clk_sys), 	// I
	.rst(reset), 	// I
	.cs(pia_cs), 	// I
	.rw(pia_rw), 	// I
	.addr(address[1:0]), // I [1:0]
	.data_in(ram_din_a), // I [7:0] 
	.data_out(),	// O [7:0] 
	.irqa(), 		// O
	.irqb(), 		// O
	.pa_i(),  		// I [7:0]
	.pa_o(), 		// O [7:0]
	.pa_oe(), 		// O [7:0] empty
	.ca1(1'b1), 	// I
	.ca2_i(1'b0), 	// I
	.ca2_o(), 		// O empty
	.ca2_oe(), 		// O empty
	.pb_i(),		// I [7:0] 
	.pb_o(), 		// O [7:0] empty
	.pb_oe(),		// O [7:0] empty
	.cb1(), 		// I
	.cb2_i(1'b0), 	// I
	.cb2_o(), 		// O empty
	.cb2_oe() 		// O empty
);

/*
// probably not needed if rom and ram are in the same module
ttl_74153 #() ttl_74153   //AL12-AL17, used for ROM and RAM address decoding
(
	.Enable_bar(), 	// I [BLOCKS-1:0]
	.Select(), 		// I [WIDTH_SELECT-1:0]
	.A_2D(), 		// I [BLOCKS*WIDTH_IN-1:0]
	.Y() 			// I [BLOCKS-1:0]
);
*/

wire  [7:0]  romDo_apf4000;
wire [10:0]  romA;
rom #(.AW(11), .FN("../bios/mame/apf_4000.hex")) Rom_APF4000
(
	.clock      (clk_sys        ),
	.ce         (1'b1           ),
	.data_out   (romDo_apf4000  ),
	.a          (romA[10:0]     )
);

//64k BRAM covering the Imagination Engine Memory Map fully
dpram #(8, 16) dpram
(
	.clk_sys(clk_sys),

	.ram_we(ioctl_wr | rw),
	.ram_ad(ioctl_download ? ioctl_addr[11:0] + 'h4000 : address),  
	.ram_d(ioctl_download ? ioctl_dout : ram_din_a),
	.ram_q(ram_dout_a),

	.ram_we_b(),
	.ram_ad_b(vdg_addr[11:0]),
	.ram_d_b(),
	.ram_q_b(ram_dout_b)
);

keyboard keyboard(
  .clk_sys(clk_sys),
  .reset(reset),
  .ps2_key(ps2_key),
  .addr(KR),
  .kb_rows(kb_rows),
  .kblayout(1'b0)
);

endmodule