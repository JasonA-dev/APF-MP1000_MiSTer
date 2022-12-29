//
// Fdc1771.v
//
// Copyright (c) 2015 Till Harbaum <till@harbaum.org>
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

// June 2012 - Stephen Eddy
//	Rewritten to work for TRS-80 FDC1771 interface and support SD disks
//
// Supported Disk Formats
//	- JV1
//	Density	Tracks	Size
//	Single	35		80k
//	Single	40		100k
//	Single	77		180k
//	Single	80		200k

module fdc1771 (
	input            clk_sys, // system cpu clock.
	input            clk_cpu,
	input	[7:0]	 clk_div,

	// external set signals
	input      [3:0] floppy_drive,
	input            floppy_side, 
	input            floppy_reset,
	input			 motor_on,

	// interrupts
	output reg       irq,
	output reg       drq, // data request

	input      [1:0] cpu_addr,
	input            cpu_sel,
	input            cpu_rd,
	input            cpu_wr,
	input      [7:0] cpu_din,
	output reg [7:0] cpu_dout,

	// place any signals that need to be passed up to the top after here.
	input      [1:0] img_mounted, // signaling that new image has been mounted
	input      [1:0] img_wp,      // write protect
	input     [31:0] img_size,    // size of image in bytes
	output reg[31:0] sd_lba,
	output reg [1:0] sd_rd,
	output reg [1:0] sd_wr,
	input            sd_ack,
	input      [8:0] sd_buff_addr,
	input      [7:0] sd_dout,
	output     [7:0] sd_din,
	input            sd_dout_strobe,

	output	         fdc_new_command,
	// debugging
	output     [7:0] cmd_out,
	output     [7:0] track_out,
	output     [7:0] sector_out,
	output     [7:0] data_in_out,
	output     [7:0] status_out

);

parameter SYS_CLK = 42578000;

localparam SECTOR_BASE = 1'b0; // number of first sector on track (archie 0, dos 1)
localparam MAX_TRACK = 8'd250;	// A seek for a track above this will throw RNF

wire [31:0] CLK_EN = (SYS_CLK / 1000)/clk_div;	// Clock in Khz adjusted for CPU speed
// -------------------------------------------------------------------------
// --------------------- IO controller image handling ----------------------
// -------------------------------------------------------------------------

// Percom and TRS-80 DD handler
logic controller_type; // 0=1771(SD), 1=1791(DD)
logic old_trsdd_enable;
always @(posedge clk_sys) begin
	if(!floppy_reset) begin
		controller_type <= 1'b0;
	end else begin
		// CMD switching (Percom Doubler)
		if(cmd == 8'hFE) controller_type <= 1'b0; 	// SD
		if(cmd == 8'hFF) controller_type <= 1'b1;	// DD
		// Sector switching (TRS Disk Doubler)
		old_trsdd_enable <= trsdd_enable;
		if(old_trsdd_enable != trsdd_enable) controller_type <= trsdd_enable;
	end
end

// Sector size handler
logic [1:0] sector_size_code = 2'd1; // sec size 0=128, 1=256, 2=512, 3=1024
always @(*) begin
	if(controller_type==0) sector_size_code = 2'b01; // 256 bytes
	else sector_size_code = 2'b10;	// 512 bytes
end
logic [10:0] sector_size;
assign sector_size = 11'd128 << sector_size_code;

// Detect changes to floppy select
logic [3:0] old_select;
logic select_change = 1'b0;
always @(posedge clk_sys) begin
	old_select <= floppy_drive;
	if(old_select != floppy_drive) select_change <= 1'b1;
	else select_change <= 1'b0;
end

// Rework this to be generic
always @(*) begin
	case(sector_size_code)
		// TRS-80 - 256 bytes
		2'b01: sd_lba = (((fd_spt*track[6:0]) << fd_doubleside) + (floppy_side ? 5'd0 : fd_spt) + sector[4:0] >> 1);
		// Atari ST - 1024 bytes
		2'b11: sd_lba = {(16'd0 + (fd_spt*track[6:0]) << fd_doubleside) + (floppy_side ? 5'd0 : fd_spt) + sector[4:0], s_odd };
		// Other
		default: sd_lba = ((fd_spt*track[6:0]) << fd_doubleside) + (floppy_side ? 5'd0 : fd_spt) + sector[4:0];
	endcase
end

reg [1:0] floppy_ready = 0;

wire         floppy_present = (floppy_drive == 4'b1110)?floppy_ready[0]:
                              (floppy_drive == 4'b1101)?floppy_ready[1]:1'b0;

wire floppy_write_protected = (floppy_drive == 4'b1110)?img_wp[0]:
                              (floppy_drive == 4'b1101)?img_wp[1]:1'b1;

//wire floppy_write_protected = 1'b1 /* synthesis keep */;

reg  [10:0] sector_len[2];
reg   [4:0] spt[2];     // sectors/track
reg   [9:0] gap_len[2]; // gap len/sector
reg   [1:0] doubleside;
reg   [3:0] hd;

wire [11:0] image_sectors = controller_type ? {img_size[19:8], 1'b0} : img_size[19:8] /* synthesis keep */; // SE - Adjusted for 256 byte sectors
reg  [11:0] image_sps; // sectors/side
reg   [4:0] image_spt; // sectors/track
reg   [9:0] image_gap_len;
reg         image_doubleside;
wire [1:0] image_hd = 2'b00; //img_size[20];

always @(*) begin
	if (sector_size_code == 3) begin
		// archie
		image_doubleside = 1'b1;
		image_spt = image_hd ? 5'd10 : 5'd5;
		image_gap_len = 10'd220;
		image_sps = 10'd350;
	end else begin
		// this block is valid for the .st format (or similar arrangement)
		image_doubleside = 1'b0;
		image_sps = image_sectors;
		if (image_sectors > (80*10)) begin
			image_doubleside = 1'b1;
			image_sps = image_sectors >> 1'b1;
		end
		//if (image_hd) image_sps = image_sps >> 1'b1;

		// spt : 10
		case (image_sps)
			350 : image_spt = 5'd10;	// SD Floppy - 35 tracks
			400 : image_spt = 5'd10;	// SD Floppy - 40 tracks
			770 : image_spt = 5'd10;	// SD Floppy - 77 tracks
			800 : image_spt = 5'd10;	// SD Floppy - 80 tracks
			default : image_spt = 5'd10;
		endcase;

		//if (image_hd) image_spt = image_spt << 1'b1;

		// SECTOR_GAP_LEN = BPT/SPT - (SECTOR_LEN + SECTOR_HDR_LEN) = 6250/SPT - (512+6)
		case (image_spt)
			//5'd9, 5'd18: image_gap_len = 10'd176;
			//5'd10,5'd20: image_gap_len = 10'd107;
			//5'd11,5'd22: image_gap_len = 10'd50;
			default : image_gap_len = 10'd1;
		endcase;
	end
end

always @(posedge clk_sys) begin
	reg [1:0] img_mountedD;

	img_mountedD <= img_mounted;
	if (~img_mountedD[0] && img_mounted[0]) begin
		floppy_ready[0] <= |img_size;
		sector_len[0] <= sector_size;
		spt[0] <= image_spt;
		gap_len[0] <= image_gap_len;
		doubleside[0] <= image_doubleside;
		hd[1:0] <= image_hd;
	end
	if (~img_mountedD[1] && img_mounted[1]) begin
		floppy_ready[1] <= |img_size;
		sector_len[1] <= sector_size;
		spt[1] <= image_spt;
		gap_len[1] <= image_gap_len;
		doubleside[1] <= image_doubleside;
		hd[3:2] <= image_hd;
	end
end

// -------------------------------------------------------------------------
// ---------------------------- IRQ/DRQ handling ---------------------------
// -------------------------------------------------------------------------
reg cpu_selD;
always @(posedge clk_sys) cpu_selD <= cpu_sel;
wire cpu_we = ~cpu_selD & cpu_sel & ~cpu_wr;

reg irq_set;

// floppy_reset and read of status register/write of command register clears irq
reg cpu_rw_cmdstatus;
always @(posedge clk_sys)
  cpu_rw_cmdstatus <= ~cpu_selD && cpu_sel && cpu_addr == FDC_REG_CMDSTATUS;

wire irq_clr = !floppy_reset || cpu_rw_cmdstatus || set_irq_clr;

reg old_irq_set=1'b0;
reg old_irq_clr=1'b0;

// Changed to only trigger on rising edge
always @(posedge clk_sys) begin
	old_irq_clr <= irq_clr;
	old_irq_set <= irq_set;
	if(~old_irq_clr & irq_clr) irq <= 1'b0;
	if(~old_irq_set & irq_set) irq <= 1'b1;
end

reg drq_set;

reg cpu_rw_data;
always @(posedge clk_sys)
	cpu_rw_data <= ~cpu_selD && cpu_sel && cpu_addr == FDC_REG_DATA;

wire drq_clr = !floppy_reset || cpu_rw_data;

always @(posedge clk_sys) begin
	if(drq_clr) drq <= 1'b0;
	else if(drq_set) drq <= 1'b1;
end

// -------------------------------------------------------------------------
// -------------------- virtual floppy drive mechanics ---------------------
// -------------------------------------------------------------------------

// -------------------------------------------------------------------------
// ------------------------------- floppy 0 --------------------------------
// -------------------------------------------------------------------------
wire fd0_index;
wire fd0_ready;
wire [7:0] fd0_track;
wire [4:0] fd0_sector;
wire fd0_sector_hdr;
wire fd0_sector_data;
wire fd0_dclk;

floppy #(.SYS_CLK(SYS_CLK)) floppy0 (
	.clk         ( clk_sys          ),

	// control signals into floppy
	.select      (!floppy_drive[0] ),
	.motor_on    ( motor_on        ),
	.step_in     ( step_in         ),
	.step_out    ( step_out        ),
	.step_delay_ms ( step_delay_ms ),
	.clk_div 	 ( clk_div		   ),

	// physical parameters
	.sector_len  ( sector_len[0]   ),
	.spt         ( spt[0]          ),
	.sector_gap_len ( gap_len[0]   ),
	.sector_base ( SECTOR_BASE     ),
	.density     ( hd[1:0]           ),

	// status signals generated by floppy
	.dclk_en     ( fd0_dclk        ),
	.track       ( fd0_track       ),
	.sector      ( fd0_sector      ),
	.sector_hdr  ( fd0_sector_hdr  ),
	.sector_data ( fd0_sector_data ),
	.ready       ( fd0_ready       ),
	.index       ( fd0_index       )
);

// -------------------------------------------------------------------------
// ------------------------------- floppy 1 --------------------------------
// -------------------------------------------------------------------------
wire fd1_index;
wire fd1_ready;
wire [7:0] fd1_track;
wire [4:0] fd1_sector;
wire fd1_sector_hdr;
wire fd1_sector_data;
wire fd1_dclk;

floppy #(.SYS_CLK(SYS_CLK)) floppy1 (
	.clk         ( clk_sys          ),

	// control signals into floppy
	.select      (!floppy_drive[1] ),
	.motor_on    ( motor_on        ),
	.step_in     ( step_in         ),
	.step_out    ( step_out        ),
	.step_delay_ms ( step_delay_ms ),
	.clk_div 	 ( clk_div		   ),

	// physical parameters
	.sector_len  ( sector_len[1]   ),
	.spt         ( spt[1]          ),
	.sector_gap_len ( gap_len[1]   ),
	.sector_base ( SECTOR_BASE     ),
	.density     ( hd[3:2]           ),

	// status signals generated by floppy
	.dclk_en     ( fd1_dclk        ),
	.track       ( fd1_track       ),
	.sector      ( fd1_sector      ),
	.sector_hdr  ( fd1_sector_hdr  ),
	.sector_data ( fd1_sector_data ),
	.ready       ( fd1_ready       ),
	.index       ( fd1_index       )
);

// -------------------------------------------------------------------------
// ----------------------------- floppy demux ------------------------------
// -------------------------------------------------------------------------

wire fd_index =        (!floppy_drive[0])?fd0_index:
                       (!floppy_drive[1])?fd1_index:
                       1'b0;

wire fd_ready =        (!floppy_drive[0])?fd0_ready:
                       (!floppy_drive[1])?fd1_ready:
                       1'b0;

wire [7:0] fd_track =  (!floppy_drive[0])?fd0_track:
                       (!floppy_drive[1])?fd1_track:
                       7'd0;

wire [4:0] fd_sector = (!floppy_drive[0])?fd0_sector:
                       (!floppy_drive[1])?fd1_sector:
                       4'd0;

wire fd_sector_hdr =   (!floppy_drive[0])?fd0_sector_hdr:
                       (!floppy_drive[1])?fd1_sector_hdr:
                       1'b0;
/*
wire fd_sector_data =  (!floppy_drive[0])?fd0_sector_data:
                       (!floppy_drive[1])?fd1_sector_data:
                       1'b0;
*/

wire fd_dclk_en =      (!floppy_drive[0])?fd0_dclk:
                       (!floppy_drive[1])?fd1_dclk:
                       1'b0;

wire fd_doubleside =   (!floppy_drive[0])?doubleside[0]:doubleside[1];
wire [4:0]  fd_spt =   (!floppy_drive[0])?spt[0]:spt[1];

wire fd_track0 = (fd_track == 0);

// -------------------------------------------------------------------------
// ----------------------- internal state machines -------------------------
// -------------------------------------------------------------------------

// --------------------------- Motor handling ------------------------------

// if motor is off and type 1 command with "spin up sequnce" bit 3 set
// is received then the command is executed after the motor has
// reached full speed for 5 rotations (800ms spin-up time + 5*200ms =
// 1.8sec) If the floppy is idle for 10 rotations (2 sec) then the
// motor is switched off again
//localparam MOTOR_IDLE_COUNTER = 4'd15;
//reg [3:0] motor_timeout_index /* verilator public */;
reg indexD;
reg busy /* verilator public */;
reg step_in, step_out;
//reg [3:0] motor_spin_up_sequence /* verilator public */;

// consider spin up done either if the motor is not supposed to spin at all or
// if it's supposed to run and has left the spin up sequence
//wire motor_spin_up_done = (!motor_on) || (motor_on && (motor_spin_up_sequence == 0));

// ---------------------------- step handling ------------------------------
// Moved to Floppy.v
// the step rate is only valid for command type I
wire [15:0] step_delay_ms = 
           (cmd[1:0]==2'b00) ? 16'd6:   // 12ms
           (cmd[1:0]==2'b01) ? 16'd6:   // 12ms
           (cmd[1:0]==2'b10) ? 16'd12:   // 20ms
           16'd20;                      //  40ms

reg [31:0] delay_cnt;

// flag indicating that a delay is in progress
(* preserve *) wire delaying = (delay_cnt != 0);
wire seeking = (cmd[7:4] == 4'b0001);

reg [7:0] step_to;
reg RNF;
reg sector_inc_strobe;
reg track_inc_strobe;
reg track_dec_strobe;
reg track_clear_strobe;
reg sector_not_found;
// Status fields that change based on DAM and 
wire sector_read = cmd[7:5] == 3'b100 ? 1'b1 : 1'b0;
wire sector_write = cmd[7:5] == 3'b101 ? 1'b1 : 1'b0;
reg set_irq_clr;
reg notready_wait;
reg [1:0] seek_state /* synthesis keep */;
reg read_bf_write;
reg reset_cpuptr;

always @(posedge clk_sys) begin
	reg data_transfer_can_start;
	
	
	reg irq_at_index;

	sector_inc_strobe <= 1'b0;
	track_inc_strobe <= 1'b0;
	track_dec_strobe <= 1'b0;
	track_clear_strobe <= 1'b0;
	irq_set <= 1'b0;
	set_irq_clr <=1'b0;

	if(!floppy_reset) begin
//		motor_on <= 1'b0;
		busy <= 1'b0;
		step_in <= 1'b0;
		step_out <= 1'b0;
		sd_card_read <= 0;
		sd_card_write <= 0;
		data_transfer_start <= 1'b0;
		data_transfer_can_start <= 0;
		seek_state <= 0;
		notready_wait <= 1'b0;
		sector_not_found <= 1'b0;
		irq_at_index <= 1'b0;
		read_bf_write <= 1'b0;
		reset_cpuptr <= 1'b0;
	end else if (clk_cpu) begin
		sd_card_read <= 0;
		sd_card_write <= 0;
		data_transfer_start <= 1'b0;

		step_in <= 1'b0;
		step_out <= 1'b0;
		reset_cpuptr <= 1'b0;

		// delay timer
		if(delay_cnt != 0) 
			delay_cnt <= delay_cnt - 1'd1;

		// just received a new command
		if(cmd_rx) begin
			busy <= 1'b1;
			notready_wait <= 1'b0;
			sector_not_found <= 1'b0;
			read_bf_write <= 1'b0;

			if(cmd_type_1 || cmd_type_2 || cmd_type_3) begin
				//motor_on <= 1'b1;
				// 'h' flag '0' -> wait for spin up
				// (!motor_on && !cmd[3]) motor_spin_up_sequence <= 6;   // wait for 6 full rotations
			end

			// handle "forced interrupt"
			if(cmd_type_4) begin
				busy <= 1'b0;
				if(cmd[3]) irq_set <= 1'b1;
				else set_irq_clr <= 1'b1;	// Else clear interrupt
				if(cmd[3:2] == 2'b01) irq_at_index <= 1'b1;
			end
		end

		// Disable busy mode if select changes
		if(select_change) busy <= 1'b0;
		else begin		
			// execute command if motor is not supposed to be running or
			// wait for motor spinup to finish
			if(busy && fd_ready && !delaying) begin

				// ------------------------ TYPE I -------------------------
				if(cmd_type_1) begin
					// evaluate command
					case (seek_state)
					0: begin
						// restore
						if(cmd[7:4] == 4'b0000) begin
							if (fd_track0) begin
								track_clear_strobe <= 1'b1;
								seek_state <= 2;
							end else begin
								step_dir <= 1'b1;
								seek_state <= 1;
							end
						end

						// seek
						if(cmd[7:4] == 4'b0001) begin
							if (track == step_to) seek_state <= 2;
							else begin
								step_dir <= (step_to < track);
								seek_state <= 1;
							end
						end

						// step
						if(cmd[7:5] == 3'b001) seek_state <= 1;

						// step-in
						if(cmd[7:5] == 3'b010) begin
							step_dir <= 1'b0;
							seek_state <= 1;
						end

						// step-out
						if(cmd[7:5] == 3'b011) begin
							step_dir <= 1'b1;
							seek_state <= 1;
						end
					end

					// do the step
					1: begin
						if (step_dir) begin
							step_in <= 1'b1;
							step_out <= 1'b0;
						end else begin
							step_out <= 1'b1;
							step_in <= 1'b0;
						end

						// update the track register if seek/restore or the update flag set
						if( (!cmd[6] && !cmd[5]) || ((cmd[6] || cmd[5]) && cmd[4]))
						begin
							if (step_dir)
								track_dec_strobe <= 1'b1;
							else
								track_inc_strobe <= 1'b1;
						end

						seek_state <= (!cmd[6] && !cmd[5]) ? 0 : 2; // loop for seek/restore
					end

					// verify
					2: begin
						if (cmd[2]) begin
							delay_cnt <= 16'd3*CLK_EN; // TODO: implement verify, now just delay one more step
							RNF <= 1'b0;
						end
						seek_state <= 3;
					end

					// finish
					3: begin
						begin
							busy <= 1'b0;
							//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
							irq_set <= 1'b1; // emit irq when command done
							seek_state <= 0;
						end
					end
					endcase
				end // if (cmd_type_1)

				// ------------------------ TYPE II -------------------------
				if(cmd_type_2) begin
					if(!floppy_present) begin
						// no image selected -> send irq after 6 ms
						if (!notready_wait) begin
							delay_cnt <= 16'd6*CLK_EN;
							notready_wait <= 1'b1;
						end else begin
							RNF <= 1'b1;
							busy <= 1'b0;
							//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
							irq_set <= 1'b1; // emit irq when command done
						end
					end else if (sector_not_found) begin
						busy <= 1'b0;
						//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
						irq_set <= 1'b1; // emit irq when command done
						RNF <= 1'b1;
					end else if (cmd[2] && !notready_wait) begin
						// e flag: 15 ms settling delay
						delay_cnt <= 16'd15*CLK_EN;
						notready_wait <= 1'b1;
						// read sector
					end else begin
						if(cmd[7:5] == 3'b100) begin
							if ((sector - SECTOR_BASE) >= fd_spt) begin
								// wait 5 rotations (1 sec) before setting RNF
								sector_not_found <= 1'b1;
								delay_cnt <= 24'd1000 * CLK_EN;
							end else begin
								if (fifo_cpuptr == 0) sd_card_read <= 1;
								// we are busy until the right sector header passes under 
								// the head and the sd-card controller indicates the sector
								// is in the fifo
								if(sd_card_done) data_transfer_can_start <= 1;
	//							if(fd_ready && fd_sector_hdr && (fd_sector == sector) && data_transfer_can_start) begin
								if(fd_ready && data_transfer_can_start) begin
									data_transfer_can_start <= 0;
									data_transfer_start <= 1;
								end

								if(data_transfer_done) begin
									if (cmd[4]) sector_inc_strobe <= 1'b1; // multiple sector transfer
									else begin
										busy <= 1'b0;
										//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
										irq_set <= 1'b1; // emit irq when command done
										RNF <= 1'b0;
									end
								end
							end
						end

						// write sector
						if(cmd[7:5] == 3'b101) begin
							if ((sector - SECTOR_BASE) >= fd_spt) begin
								// wait 5 rotations (1 sec) before setting RNF
								sector_not_found <= 1'b1;
								delay_cnt <= 24'd1000 * CLK_EN;
							end else begin
								// Read before write handling for 256 byte sectors
								if (sector_size_code == 2'b01) begin
									// Stage 0, read SD card
									if (fifo_cpuptr == 0 && read_bf_write==1'b0 && !sd_card_done) sd_card_read <= 1'b1;
									// Stage 1, read SD card done
									if (sd_card_done && read_bf_write==1'b0) begin
										read_bf_write <= 1'b1;
										reset_cpuptr <= 1'b1;
									end
								end
								// Read data from CPU into dpram
								if (sector_size_code != 2'b01 || read_bf_write==1'b1) begin									
									if (fifo_cpuptr==0) data_transfer_start <= 1'b1;
									if (data_transfer_done) sd_card_write <= 1;
									if (sd_card_done) begin
										if (cmd[4]) sector_inc_strobe <= 1'b1; // multiple sector transfer
										else begin
											busy <= 1'b0;
											//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
											irq_set <= 1'b1; // emit irq when command done
											RNF <= 1'b0;
										end
									end
								end
							end
						end
					end
				end

				// ------------------------ TYPE III -------------------------
				if(cmd_type_3) begin
					if(!floppy_present) begin
						// no image selected -> send irq immediately
						busy <= 1'b0; 
						//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
						irq_set <= 1'b1; // emit irq when command done
					end else begin
						// read track TODO: fake
						if(cmd[7:4] == 4'b1110) begin
							busy <= 1'b0;
							//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
							irq_set <= 1'b1; // emit irq when command done
						end else

						// write track TODO: fake - also catches 0xFE/0xFF Percom Doubler command handled elsewhere
						if(cmd[7:4] == 4'b1111) begin
							busy <= 1'b0;
							//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
							irq_set <= 1'b1; // emit irq when command done
						end else

						// read address
						if(cmd[7:4] == 4'b1100) begin
							// we are busy until the next setor header passes under the head
							if(fd_ready && fd_sector_hdr)
								data_transfer_start <= 1'b1;

							if(data_transfer_done) begin
								busy <= 1'b0;
								//motor_timeout_index <= MOTOR_IDLE_COUNTER - 1'd1;
								irq_set <= 1'b1; // emit irq when command done
							end
						end
					end
				end
			end
		end

		// stop motor if there was no command for 10 index pulses
		indexD <= fd_index;
		if(indexD && !fd_index) begin
			irq_at_index <= 1'b0;
			if (irq_at_index) irq_set <= 1'b1;

			// led motor timeout run once fdc is not busy anymore
			//if(!busy) begin
				//if(motor_timeout_index != 0)
				//	motor_timeout_index <= motor_timeout_index - 4'd1;
				//else
					//motor_on <= 1'b0;
			//end

			//if(motor_spin_up_sequence != 0)
				//motor_spin_up_sequence <= motor_spin_up_sequence - 4'd1;
		end
	end
end

// floppy delivers data at a floppy generated rate (usually 250kbit/s), so the start and stop
// signals need to be passed forth and back from cpu clock domain to floppy data clock domain
reg data_transfer_start;
reg data_transfer_done;

// ==================================== FIFO ==================================

// 0.5/1 kB buffer used to receive a sector as fast as possible from from the io
// controller. The internal transfer afterwards then runs at 250000 Bit/s
reg  [9:0] fifo_cpuptr;
wire [7:0] fifo_q;
reg        s_odd; //odd sector
reg  [8:0] fifo_sdptr;

always @(*) begin
	if (sector_size_code == 3)
		fifo_sdptr = { s_odd, sd_buff_addr };
	else
		fifo_sdptr = sd_buff_addr;
end

wire writing_mem = cmd[7:5] == 3'b101 && data_in_strobe ? 1'b1 : 1'b0;
// Have to be able to accommodate 512 byte FAT sectors on the SD
// so force ADDR width to 10, even though only reading first 256 bytes 
dpram #(.ADDR(9), .DATA(8)) fifo
(
	.a_clk(clk_sys),
	.a_wr(sd_dout_strobe & sd_ack),
	.a_addr(fifo_sdptr),
	.a_din(sd_dout),
	.a_dout(sd_din),

	.b_clk(clk_sys),
	.b_wr(writing_mem),
	.b_addr({controller_type ? fifo_cpuptr[8] : sector[0], fifo_cpuptr[7:0]}),
	.b_din(data_in),
	.b_dout(fifo_q)
);

// ------------------ SD card control ------------------------
localparam SD_IDLE = 0;
localparam SD_READ = 1;
localparam SD_WRITE = 2;

reg [1:0] sd_state;
reg       sd_card_write;
reg       sd_card_read;
reg       sd_card_done;

always @(posedge clk_sys) begin
	reg sd_ackD;
	reg sd_card_readD;
	reg sd_card_writeD;

	sd_card_readD <= sd_card_read;
	sd_card_writeD <= sd_card_write;
	sd_ackD <= sd_ack;
	if (sd_ack) {sd_rd, sd_wr} <= 0;
	if (clk_cpu) sd_card_done <= 0;

	case (sd_state)
	SD_IDLE:
	begin
		s_odd <= 1'b0;
		if (~sd_card_readD & sd_card_read) begin
			sd_rd <= ~{ floppy_drive[1], floppy_drive[0] };
			sd_state <= SD_READ;
		end
		else if (~sd_card_writeD & sd_card_write) begin
			sd_wr <= ~{ floppy_drive[1], floppy_drive[0] };
			sd_state <= SD_WRITE;
		end
	end

	SD_READ:
	if (sd_ackD & ~sd_ack) begin
		sd_state <= SD_IDLE;
		sd_card_done <= 1; // to be on the safe side now, can be issued earlier
	end

	SD_WRITE:
	if (sd_ackD & ~sd_ack) begin
		sd_state <= SD_IDLE;
		sd_card_done <= 1;
	end

	default: ;
	endcase
end

// -------------------- CPU data read/write -----------------------
reg [10:0] data_transfer_cnt /* synthesis keep */;

always @(posedge clk_sys) begin
	reg        data_transfer_startD;
	

	// reset fifo read pointer on reception of a new command or 
	// when multi-sector transfer increments the sector number
	if(cmd_rx || sector_inc_strobe || reset_cpuptr) begin
		data_transfer_cnt <= 11'd0;
		fifo_cpuptr <= 10'd0;
	end

	drq_set <= 1'b0;
	if (clk_cpu) data_transfer_done <= 0;
	data_transfer_startD <= data_transfer_start;
	// received request to read data
	if(~data_transfer_startD & data_transfer_start) begin

		// read_address command has 6 data bytes
		if(cmd[7:4] == 4'b1100)
			data_transfer_cnt <= 11'd6+11'd1;

		// read/write sector has sector_size data bytes
		if(cmd[7:6] == 2'b10 || read_bf_write)
			data_transfer_cnt <= sector_size + 1'd1;
	end

	// write sector data arrived from CPU
	if(cmd[7:5] == 3'b101 && data_in_strobe) fifo_cpuptr <= fifo_cpuptr + 1'd1;

	if(fd_dclk_en) begin
		if(data_transfer_cnt != 0) begin
			if(data_transfer_cnt != 1) begin
				data_lost <= 1'b0;
				if (drq) data_lost <= 1'b1;
				drq_set <= 1'b1;

				// read_address
				if(cmd[7:4] == 4'b1100) begin
					case(data_transfer_cnt)
						7: data_out <= fd_track;
						6: data_out <= 8'b00000000;
						5: data_out <= fd_sector;
						4: data_out <= sector_size_code; // TODO: sec size 0=128, 1=256, 2=512, 3=1024
						3: data_out <= 8'ha5;
						2: data_out <= 8'h5a;
					endcase // case (data_read_cnt)
				end

				// read sector
				if(cmd[7:5] == 3'b100) begin
					if(fifo_cpuptr != sector_size) begin
						data_out <= fifo_q;
						fifo_cpuptr <= fifo_cpuptr + 1'd1;
					end
				end
			end

			// count down and stop after last byte
			data_transfer_cnt <= data_transfer_cnt - 11'd1;
			if(data_transfer_cnt == 1)
				data_transfer_done <= 1'b1;
		end
	end
end

// Different logic for fdc1771 status register
logic s6, s5, s4, s2, s1;
always_comb
begin
	if(!floppy_present) begin		// Pull-ups if no disk attached
		s6 = 1'b0;
		s5 = 1'b1;
		s4 = 1'b0;
		s2 = 1'b1;
		s1 = 1'b1;
	end
	else begin
		if(cmd_type_2) begin
			if(sector_read) begin
				s6 = 1'b0;
				s5 = (fd_track==8'd17 ? 1'b1 : 1'b0);	// DIR=F8, NORM=FB
			end 
			else begin	// else sector write
				s6 = floppy_write_protected;
				s5 = 1'b0;
			end
			s4 = !floppy_present; //s4 = RNF;
			s2 = data_lost;
			s1 = drq;
		end 
		else if(cmd_type_3) begin //cmd_type_3 or unknown state
			if(cmd[7:4] == 4'b1111) s6 = floppy_write_protected;	// write track
			else s6 = 1'b0;
			s5 = 1'b0;
			s4 = !floppy_present; //1'b0;
			s2 = data_lost;
			s1 = drq;
		end
		else begin //cmd_type_1,4 or unknown state
			s6 = floppy_write_protected;
			s5 = fd_ready; 	// LDOS fix
			s4 = !floppy_present; //s4 = RNF;
			s2 = fd_track0;
			s1 = ~fd_index;
		end
	end
end

//wire s6 = cmd_type_1 ? floppy_write_protected : sector_read ? 1'b0 : floppy_write_protected;
//wire s5 = cmd_type_1 ? ~&floppy_drive : sector_read ? (track==8'd17 ? 1'b1 : 1'b0) : motor_on;
//wire s4 = sector_not_found;
// the status byte
wire [7:0] status = {!motor_on | notready_wait, 
		      s6,              
		      s5,  				
		      s4,               // record not found
		      1'b0,                                // crc error
		      s2,
		      s1,
		      busy }; /* synthesis keep */

reg [7:0] track; /* verilator public */
reg [7:0] sector;
reg [7:0] data_in;
reg [7:0] data_out;

reg step_dir;
//reg motor_on /* verilator public */ = 1'b0;
reg data_lost;

// ---------------------------- command register -----------------------   
reg [7:0] cmd /* verilator public */;
wire cmd_type_1 = (cmd[7] == 1'b0);
wire cmd_type_2 = (cmd[7:6] == 2'b10);
wire cmd_type_3 = (cmd[7:5] == 3'b111) || (cmd[7:4] == 4'b1100);
wire cmd_type_4 = (cmd[7:4] == 4'b1101);
assign fdc_new_command = cmd_rx_i;

// output debugging info
assign cmd_out = cmd;
assign track_out = track;
assign sector_out = sector;
assign data_in_out = data_in;
assign status_out = status;

localparam FDC_REG_CMDSTATUS    = 0;
localparam FDC_REG_TRACK        = 1;
localparam FDC_REG_SECTOR       = 2;
localparam FDC_REG_DATA         = 3;

// CPU register read
reg fake_index;
always @(posedge clk_sys) begin
	if(cpu_sel && !cpu_rd && cpu_addr==FDC_REG_CMDSTATUS) begin
		fake_index = ~fake_index;
	end
end

always @(*) begin
	cpu_dout = 8'h00;

	if(cpu_sel && !cpu_rd) begin
		case(cpu_addr)
			FDC_REG_CMDSTATUS: cpu_dout = status;
			FDC_REG_TRACK:     cpu_dout = track;
			FDC_REG_SECTOR:    cpu_dout = sector;
			FDC_REG_DATA:      cpu_dout = data_out;
		endcase
	end
end

// cpu register write
reg cmd_rx /* verilator public */;
reg cmd_rx_i;
reg data_in_strobe;
reg trsdd_enable;	// TRS-Disk Doubler

always @(posedge clk_sys) begin
	if(!floppy_reset) begin
		// clear internal registers
		cmd <= 8'h00;
		track <= 8'h00;
		sector <= 8'h00;

		// reset state machines and counters
		cmd_rx_i <= 1'b0;
		cmd_rx <= 1'b0;
		data_in_strobe <= 0;
		trsdd_enable <= 1'b0;
	end else begin
		data_in_strobe <= 0;

		// cmd_rx is delayed to make sure all signals (the cmd!) are stable when
		// cmd_rx is evaluated
		cmd_rx <= cmd_rx_i;

		// command reception is ack'd by fdc going busy
		if((!cmd_type_4 && busy) || (clk_cpu && cmd_type_4 && !busy)) cmd_rx_i <= 1'b0;

		// only react if stb just raised
		if(cpu_we) begin
			if(cpu_addr == FDC_REG_CMDSTATUS) begin       // command register
				cmd <= cpu_din;
				cmd_rx_i <= 1'b1;
				// ------------- TYPE I commands -------------
				if(cpu_din[7:4] == 4'b0000) begin               // RESTORE
					step_to <= 8'd0;
					track <= 8'hff;
				end

				if(cpu_din[7:4] == 4'b0001) begin               // SEEK
					step_to <= data_in;
				end

				if(cpu_din[7:5] == 3'b001) begin                // STEP
				end

				if(cpu_din[7:5] == 3'b010) begin                // STEP-IN
				end

				if(cpu_din[7:5] == 3'b011) begin                // STEP-OUT
				end

				// ------------- TYPE II commands -------------
				if(cpu_din[7:5] == 3'b100) begin                // read sector
				end

				if(cpu_din[7:5] == 3'b101) begin                // write sector
				end

				// ------------- TYPE III commands ------------
				if(cpu_din[7:4] == 4'b1100) begin               // read address
				end

				if(cpu_din[7:4] == 4'b1110) begin               // read track
				end

				if(cpu_din[7:4] == 4'b1111) begin               // write track
				end

				// ------------- TYPE IV commands -------------
				if(cpu_din[7:4] == 4'b1101) begin               // force intrerupt
				end
			end

			if(cpu_addr == FDC_REG_TRACK)                    // track register
				track <= cpu_din;

			if(cpu_addr == FDC_REG_SECTOR) begin
				if(cpu_din == 8'h80) trsdd_enable=1'b1;	// Enable DD
				if(cpu_din == 8'ha0) trsdd_enable=1'b0;	// Enable SD
				// ignore codes to enable / disable precomp
				sector <= {1'b0, cpu_din[6:0]};	// Strip top bit
			end                  // sector register

			if(cpu_addr == FDC_REG_DATA) begin               // data register
				data_in_strobe <= 1;
				data_in <= cpu_din;
			end
		end

		if (sector_inc_strobe) sector <= sector + 1'd1;
		if (track_inc_strobe) track <= track + 8'd1;
		if (track_dec_strobe) track <= track - 8'd1;
		if (track_clear_strobe) track <= 8'd0;
	end
end

endmodule
