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
	input       [31:0] joy0,
	input       [31:0] joy1,
	output  reg        ce_pix,

	output reg         HBlank,
	output reg         HSync,
	output reg         VBlank,
	output reg         VSync,
	output wire [7:0]  red,
	output wire [7:0]  green,
	output wire [7:0]  blue
);

reg cart_loaded;

assign cart_loaded = 0; //for now

reg [1:0] div_cpu;
reg clk_cpu;
always @(posedge clk_sys) begin
	if(reset) div_cpu <= 2'b00;
	else div_cpu <= div_cpu + 1'b1;
end
assign clk_cpu = div_cpu[1];

wire [7:0] KR, kb_rows;
wire cpu_rw,ram_we;
reg [15:0] address, ram_addr;
wire [12:0] vdg_addr;
reg [7:0]  ram_din_a;
reg [7:0]  ram_dout_a, cpu_data_i;
reg [7:0]  ram_din_b;
reg [7:0]  ram_dout_b;
wire E_CLK;

// CPU
mc6801_core mc6801
(
	.clk(clk_cpu), 			// I
	.rst(reset),			// I
	.rw(cpu_rw),				// O
	.vma(),					// O
	.address(address),		// O [15:0]
	.data_in(cpu_data_i),	// I [7:0]
	.data_out(ram_din_a),	// O [7:0]
	.hold(0),				// I
	.halt(0),				// I
	.irq(pia_irqa || pia_irqb),				// I
	.nmi(),					// I
	.irq_icf(),				// I
	.irq_ocf(),				// I
	.irq_tof(),				// I
	.irq_sci(),				// I
	.test_alu(),			// O [15:0]
	.test_cc()				// O [7:0]
);

//assign ram_addr = address[15:13] == 3'h7 ? {4'h4 , address[11:0] } :                  // If we are accessing xE000 - FFFF, then read x4000 - 4FFF
assign ram_addr = address[15:13] == 3'h7 || address[15:12] == 4'h4 ? {4'hF , address[11:0] } :                  // If we are accessing xE000 - FFFF, then read x4000 - 4FFF
                  address[15:10] >= 6'h0 && address[15:10]<= 6'h7 ? {6'h0, address[9:0]} :
                  address;

assign ram_we = ~cpu_rw && address[15:13] == 3'h0 ? 1'b1 : 1'b0; //only allow writes to ram if below x2000

assign cpu_data_i = pia_cs && cpu_rw ? pia0_data_out : ram_dout_a;
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
reg vdg_en ;
reg [1:0] div_vid;


always @(posedge clk_vid) begin
	if (reset) div_vid <= 0;
	else	begin
		vdg_en <= 0;
		if (div_vid == 2'd2) begin
		  vdg_en <= 1;
        div_vid <= 0;
		end
		else div_vid <= div_vid + 1'b1;
	end
end
// VDG
mc6847 mc6847
(
  .clk(clk_vid),			// I
  .clk_ena(vdg_en), 	// I clk_vid[2]
  .reset(reset),			// I
  .da0(),					// O
  .videoaddr(vdg_addr), 	// O [12:0] vdg_addr
  .dd(ram_dout_b), 			// I [7:0] ram_dout_b
  .fs_n(fs_n),
  .hs_n(),
  .an_g(ag), 					// I U8[3]
  .an_s(ram_dout_b[7]), 	// I ram_dout_b[7]
  .intn_ext(), 				// I U8[0]
  .gm(gm), 					// I [2:0] { U8[0], U8[1], U8[2] }
  .css(ag? latch_data[6] : ram_dout_b[6]), 					// I U8[4]
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
reg ag, as, fs_n;
reg [2:0] gm;
reg [7:0] vram_data;
reg [12:0] vram_addr;
reg [12:0] latch_addr;
reg [7:0] latch_data;

reg [4:0] ag_sampler;
reg [12:0] vdg_addrD;
always @(posedge clk_vid) begin
	vdg_addrD <= vdg_addr;
	if(reset) ag_sampler <= 13'h0000;
	else ag_sampler <= {ag_sampler[3:0], (vdg_addrD==vdg_addr && ag)};
end

always @(posedge clk_vid) begin
	if(ag_sampler[1:0] == 2'b01) begin
		latch_addr <= {vdg_addr[12:9], vdg_addr[4:0]};
	end
	else if(ag_sampler[3:0] == 4'b0111) begin
		latch_data = ram_dout_b;
	end
	else if(ag_sampler[4:0] == 4'b01111) begin
		latch_addr <= {5'h0,latch_data[4:0],4'h0} | vdg_addr[8:5] | 13'h200;
	end
end
		

assign gm = {2'b11,pia0_portb_o[6]};
assign ag = pia0_portb_o[7];
assign vram_addr = ag ? latch_addr : vdg_addr | 13'h200;
//assign vram_addr = vdg_addr + 13'h200;

wire pia_cs, pia_rw, pia_ca2, pia_irqa, pia_irqb;
reg [7:0] pia0_data_out, pia0_porta_o,pia0_portb_o;
assign pia_cs = (address[15:13] == 3'b001) ? 1'b1 : 1'b0;
assign pia_rw = (cpu_rw == 1'b0 && pia_cs == 1'b1) ? 1'b0 : 1'b1;

// PIA
pia6821 pia6821
(
	.clk(clk_sys), 	// I
	.rst(reset), 	// I
	.cs(pia_cs), 	// I
	.rw(pia_rw), 	// I
	.addr(address[1:0]), // I [1:0]
	.data_in(ram_din_a), // I [7:0] 
	.data_out(pia0_data_out),	// O [7:0] 
	.irqa(pia_irqa), 		// O
	.irqb(pia_irqb), 		// O
	.pa_i(pad_data),  		// I [7:0] //Keypad data - Temporary returning FF/no-input
//	.pa_i(8'hFF),  		// I [7:0] //Keypad data - Temporary returning FF/no-input
	.pa_o(), 		// O [7:0]
	.pa_oe(), 		// O [7:0] empty
	.ca1(1'b1), 	// I
	.ca2_i(1'b1), 	// I
	.ca2_o(pia_ca2), 		// O empty
	.ca2_oe(), 		// O empty
	.pb_i(),		// I [7:0] 
	.pb_o(pia0_portb_o), 		// O [7:0] empty
	.pb_oe(),		// O [7:0] empty
	.cb1(fs_n), 		// I
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
//
//wire  [7:0]  romDo_apf4000;
//wire [10:0]  romA;
//rom #(.AW(11), .FN("../bios/mame/apf_4000.hex")) Rom_APF4000
//(
//	.clock      (clk_sys        ),
//	.ce         (1'b1           ),
//	.data_out   (romDo_apf4000  ),
//	.a          (romA[10:0]     )
//);

//64k BRAM covering the Imagination Engine Memory Map fully
dpram #(16, 8) dpram
(
	.clk_sys(clk_vid),

	.ram_we(ioctl_wr | ram_we),
//	.ram_ad(ioctl_download ? ioctl_addr[11:0] + 'h4000 : ram_addr),  
	.ram_ad(ioctl_download ? ioctl_addr[11:0] + 16'hF000 : ram_addr),  
	.ram_d(ioctl_download ? ioctl_dout : ram_din_a),
	.ram_q(ram_dout_a),

	.ram_we_b(),
//	.ram_ad_b(vdg_addr[11:0]),
	.ram_ad_b({3'd0,vram_addr}),
	.ram_d_b(),
	.ram_q_b(ram_dout_b)
);

reg [7:0] pad_data;
assign pad_data = 8'hFF & (pad_data_sel[0] ? 8'hFF : key_row[0]) & (pad_data_sel[1] ? 8'hFF : key_row[1]) & (pad_data_sel[2] ? 8'hFF : key_row[2]) & (pad_data_sel[3] ? 8'hFF : key_row[3]);

//Joystick/Keypad
reg [3:0] pad_data_sel;
assign pad_data_sel = pia0_portb_o[3:0];

//Keyboard
wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
//
//123     123
//QWE     456
//ASD     789
//ZXC     *0-

always @(posedge clk_vid) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code[7:0])
//Left Controller
			'h16: btn_L1     <= ~pressed; // 1
			'h1E: btn_L2     <= ~pressed; // 2
			'h26: btn_L3     <= ~pressed; // 3
			'h15: btn_L4     <= ~pressed; // q
			'h1D: btn_L5     <= ~pressed; // w
			'h24: btn_L6     <= ~pressed; // e
			'h1C: btn_L7     <= ~pressed; // a
			'h1B: btn_L8     <= ~pressed; // s
			'h23: btn_L9     <= ~pressed; // d
			'h1A: btn_LCL    <= ~pressed; // z
			'h22: btn_L0     <= ~pressed; // x
			'h21: btn_LEN    <= ~pressed; // c
			'h25: btn_L4     <= ~pressed; // 4
			'h2E: btn_L5     <= ~pressed; // 5
			'h36: btn_L6     <= ~pressed; // 6
			'h3D: btn_L7     <= ~pressed; // 7
			'h3E: btn_L8     <= ~pressed; // 8
			'h46: btn_L9     <= ~pressed; // 9
			'h45: btn_L0     <= ~pressed; // 0
			'h4E: btn_LCL    <= ~pressed; // -
			'h55: btn_LEN    <= ~pressed; // =

//Right Controller - Num Pad
			'h69: btn_R1     <= ~pressed; // 1
			'h72: btn_R2     <= ~pressed; // 2
			'h7A: btn_R3     <= ~pressed; // 3
			'h6B: btn_R4     <= ~pressed; // 4
			'h73: btn_R5     <= ~pressed; // 5
			'h74: btn_R6     <= ~pressed; // 6
			'h6C: btn_R7     <= ~pressed; // 7
			'h75: btn_R8     <= ~pressed; // 8
			'h7D: btn_R9     <= ~pressed; // 9
			'h71: btn_RCL    <= ~pressed; // .
			'h70: btn_R0     <= ~pressed; // 0
			'h5A: btn_REN    <= ~pressed; // Enter
		endcase
	end
end

wire [7:0] key_row[4];
assign key_row[0] = { btn_L7 , btn_L4 , btn_L0 , btn_L1 , btn_R7 , btn_R4 , btn_R0 , btn_R1 };
assign key_row[1] = { ~joy1[1] , ~joy1[3] , ~joy1[0] , ~joy1[2] , ~joy0[1] , ~joy0[3] , ~joy0[0] , ~joy0[2] };
assign key_row[2] = { btn_L9 , btn_L6 , btn_LCL , btn_L3 , btn_R9 , btn_R6 , btn_RCL , btn_R3 };
assign key_row[3] = { btn_L8 , btn_L5 , btn_LEN & ~joy1[4] , btn_L2 , btn_R8 , btn_R5 , btn_REN & ~joy0[4] , btn_R2 };

// Left Keypad
reg btn_L1 = 1;
reg btn_L2 = 1;
reg btn_L3 = 1;
reg btn_L4 = 1;
reg btn_L5 = 1;
reg btn_L6 = 1;
reg btn_L7 = 1;
reg btn_L8 = 1;
reg btn_L9 = 1;
reg btn_L0 = 1;
reg btn_LCL = 1; //*
reg btn_LEN = 1; //#


// Left Keypad
reg btn_R1 = 1;
reg btn_R2 = 1;
reg btn_R3 = 1;
reg btn_R4 = 1;
reg btn_R5 = 1;
reg btn_R6 = 1;
reg btn_R7 = 1;
reg btn_R8 = 1;
reg btn_R9 = 1;
reg btn_R0 = 1;
reg btn_RCL = 1; //*
reg btn_REN = 1; //#

endmodule