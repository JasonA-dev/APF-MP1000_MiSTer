// File pia6821.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2017 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

//===========================================================================--
//
//  S Y N T H E Z I A B L E    I/O Port   C O R E
//
//  www.OpenCores.Org - May 2004
//  This core adheres to the GNU public license  
//
// File name      : pia6821.vhd
//
// Purpose        : Implements 2 x 8 bit parallel I/O ports
//                  with programmable data direction registers
//                  
// Dependencies   : ieee.Std_Logic_1164
//                  ieee.std_logic_unsigned
//
// Author         : John E. Kent      
//
//===========================================================================----
//
// Revision History:
//
// Date:          Revision         Author
// 1 May 2004     0.0              John Kent
// Initial version developed from ioport.vhd
//
//
// Unkown date     0.0.1 found at Pacedev repository
// remove High Z output and and oe signal
//
// 18 October 2017 0.0.2           DarFpga
// Set output to low level when in data is in input mode 
// (to avoid infered latch warning)
//
//===========================================================================----
//
// Memory Map
//
// IO + $00 - Port A Data & Direction register
// IO + $01 - Port A Control register
// IO + $02 - Port B Data & Direction Direction Register
// IO + $03 - Port B Control Register
//
// no timescale needed

module pia6821(
input wire clk,
input wire rst,
input wire cs,
input wire rw,
input wire [1:0] addr,
input wire [7:0] data_in,
output reg [7:0] data_out,
output reg irqa,
output reg irqb,
input wire [7:0] pa_i,
output reg [7:0] pa_o,
output reg [7:0] pa_oe,
input wire ca1,
input wire ca2_i,
output reg ca2_o,
output reg ca2_oe,
input wire [7:0] pb_i,
output reg [7:0] pb_o,
output reg [7:0] pb_oe,
input wire cb1,
input wire cb2_i,
output reg cb2_o,
output reg cb2_oe
);




reg [7:0] porta_ddr;
reg [7:0] porta_data;
reg [5:0] porta_ctrl;
reg porta_read;
reg [7:0] portb_ddr;
reg [7:0] portb_data;
reg [5:0] portb_ctrl;
reg portb_read;
reg portb_write;
reg ca1_del;
reg ca1_rise;
reg ca1_fall;
reg ca1_edge;
reg irqa1;
reg ca2_del;
reg ca2_rise;
reg ca2_fall;
reg ca2_edge;
reg irqa2;
reg ca2_out;
reg cb1_del;
reg cb1_rise;
reg cb1_fall;
reg cb1_edge;
reg irqb1;
reg cb2_del;
reg cb2_rise;
reg cb2_fall;
reg cb2_edge;
reg irqb2;
reg cb2_out;

  //------------------------------
  //
  // read I/O port
  //
  //------------------------------
  always @(addr, cs, irqa1, irqa2, irqb1, irqb2, porta_ddr, portb_ddr, porta_data, portb_data, porta_ctrl, portb_ctrl, pa_i, pb_i) begin : P3
    reg [31:0] count;

    case(addr)
    2'b00 : begin
      for (count=0; count <= 7; count = count + 1) begin
        if(porta_ctrl[2] == 1'b0) begin
          data_out[count] <= porta_ddr[count];
          porta_read <= 1'b0;
        end
        else begin
          if(porta_ddr[count] == 1'b1) begin
            data_out[count] <= porta_data[count];
          end
          else begin
            data_out[count] <= pa_i[count];
          end
          porta_read <= cs;
        end
      end
      portb_read <= 1'b0;
    end
    2'b01 : begin
      data_out <= {irqa1,irqa2,porta_ctrl};
      porta_read <= 1'b0;
      portb_read <= 1'b0;
    end
    2'b10 : begin
      for (count=0; count <= 7; count = count + 1) begin
        if(portb_ctrl[2] == 1'b0) begin
          data_out[count] <= portb_ddr[count];
          portb_read <= 1'b0;
        end
        else begin
          if(portb_ddr[count] == 1'b1) begin
            data_out[count] <= portb_data[count];
          end
          else begin
            data_out[count] <= pb_i[count];
          end
          portb_read <= cs;
        end
      end
      porta_read <= 1'b0;
    end
    2'b11 : begin
      data_out <= {irqb1,irqb2,portb_ctrl};
      porta_read <= 1'b0;
      portb_read <= 1'b0;
    end
    default : begin
      data_out <= 8'b00000000;
      porta_read <= 1'b0;
      portb_read <= 1'b0;
    end
    endcase
  end

  //-------------------------------
  //
  // Write I/O ports
  //
  //-------------------------------
  always @(posedge clk) begin //, posedge rst, posedge addr, posedge cs, posedge rw, posedge data_in, posedge porta_ctrl, posedge portb_ctrl, posedge porta_data, posedge portb_data, posedge porta_ddr, posedge portb_ddr) begin
    if(rst == 1'b1) begin
      porta_ddr <= 8'b00000000;
      porta_data <= 8'b00000000;
      porta_ctrl <= 6'b000000;
      portb_ddr <= 8'b00000000;
      portb_data <= 8'b00000000;
      portb_ctrl <= 6'b000000;
      portb_write <= 1'b0;
    end else begin
      if(cs == 1'b1 && rw == 1'b0) begin
        case(addr)
        2'b00 : begin
          if(porta_ctrl[2] == 1'b0) begin
            porta_ddr <= data_in;
            porta_data <= porta_data;
          end
          else begin
            porta_ddr <= porta_ddr;
            porta_data <= data_in;
          end
          porta_ctrl <= porta_ctrl;
          portb_ddr <= portb_ddr;
          portb_data <= portb_data;
          portb_ctrl <= portb_ctrl;
          portb_write <= 1'b0;
        end
        2'b01 : begin
          porta_ddr <= porta_ddr;
          porta_data <= porta_data;
          porta_ctrl <= data_in[5:0];
          portb_ddr <= portb_ddr;
          portb_data <= portb_data;
          portb_ctrl <= portb_ctrl;
          portb_write <= 1'b0;
        end
        2'b10 : begin
          porta_ddr <= porta_ddr;
          porta_data <= porta_data;
          porta_ctrl <= porta_ctrl;
          if(portb_ctrl[2] == 1'b0) begin
            portb_ddr <= data_in;
            portb_data <= portb_data;
            portb_write <= 1'b0;
          end
          else begin
            portb_ddr <= portb_ddr;
            portb_data <= data_in;
            portb_write <= 1'b1;
          end
          portb_ctrl <= portb_ctrl;
        end
        2'b11 : begin
          porta_ddr <= porta_ddr;
          porta_data <= porta_data;
          porta_ctrl <= porta_ctrl;
          portb_ddr <= portb_ddr;
          portb_data <= portb_data;
          portb_ctrl <= data_in[5:0];
          portb_write <= 1'b0;
        end
        default : begin
          porta_ddr <= porta_ddr;
          porta_data <= porta_data;
          porta_ctrl <= porta_ctrl;
          portb_ddr <= portb_ddr;
          portb_data <= portb_data;
          portb_ctrl <= portb_ctrl;
          portb_write <= 1'b0;
        end
        endcase
      end
      else begin
        porta_ddr <= porta_ddr;
        porta_data <= porta_data;
        porta_ctrl <= porta_ctrl;
        portb_data <= portb_data;
        portb_ddr <= portb_ddr;
        portb_ctrl <= portb_ctrl;
        portb_write <= 1'b0;
      end
    end
  end

  //-------------------------------
  //
  // direction control port a
  //
  //-------------------------------
  always @(porta_data, porta_ddr) begin : P2
    reg [31:0] count;

    for (count=0; count <= 7; count = count + 1) begin
      if(porta_ddr[count] == 1'b1) begin
        pa_o[count] <= porta_data[count];
        pa_oe[count] <= 1'b1;
      end
      else begin
        pa_o[count] <= 1'b0;
        pa_oe[count] <= 1'b0;
      end
    end
  end

  //-------------------------------
  //
  // CA1 Edge detect
  //
  //-------------------------------
  always @(negedge clk) begin //, negedge rst, negedge ca1, negedge ca1_del, negedge ca1_rise, negedge ca1_fall, negedge ca1_edge, negedge irqa1, negedge porta_ctrl, negedge porta_read) begin
    if(rst == 1'b1) begin
      ca1_del <= 1'b0;
      ca1_rise <= 1'b0;
      ca1_fall <= 1'b0;
      ca1_edge <= 1'b0;
      irqa1 <= 1'b0;
    end else begin
      ca1_del <= ca1;
      ca1_rise <= ( ~ca1_del) & ca1;
      ca1_fall <= ca1_del & ( ~ca1);
      if(ca1_edge == 1'b1) begin
        irqa1 <= 1'b1;
      end
      else if(porta_read == 1'b1) begin
        irqa1 <= 1'b0;
      end
      else begin
        irqa1 <= irqa1;
      end
    end

    if(porta_ctrl[1] == 1'b0)
	    ca1_edge <= ca1_fall;
    else
	    ca1_edge <= ca1_rise;

  end

  //-------------------------------
  //
  // CA2 Edge detect
  //
  //-------------------------------
  always @(negedge clk) begin //, negedge rst, negedge ca2_i, negedge ca2_del, negedge ca2_rise, negedge ca2_fall, negedge ca2_edge, negedge irqa2, negedge porta_ctrl, negedge porta_read) begin
    if(rst == 1'b1) begin
      ca2_del <= 1'b0;
      ca2_rise <= 1'b0;
      ca2_fall <= 1'b0;
      ca2_edge <= 1'b0;
      irqa2 <= 1'b0;
    end else begin
      ca2_del <= ca2_i;
      ca2_rise <= ( ~ca2_del) & ca2_i;
      ca2_fall <= ca2_del & ( ~ca2_i);
      if(porta_ctrl[5] == 1'b0 && ca2_edge == 1'b1) begin
        irqa2 <= 1'b1;
      end
      else if(porta_read == 1'b1) begin
        irqa2 <= 1'b0;
      end
      else begin
        irqa2 <= irqa2;
      end
    end

    if(porta_ctrl[4] == 1'b0) 
	    ca2_edge <= ca2_fall;
    else
	    ca2_edge <= ca2_rise;

  end

  //-------------------------------
  //
  // CA2 output control
  //
  //-------------------------------
  always @(negedge clk) begin // , negedge rst, negedge porta_ctrl, negedge porta_read, negedge ca1_edge, negedge ca2_out) begin
    if(rst == 1'b1) begin
      ca2_out <= 1'b0;
    end else begin
      case(porta_ctrl[5:3])
      3'b100 : begin
        // read PA clears, CA1 edge sets
        if(porta_read == 1'b1) begin
          ca2_out <= 1'b0;
        end
        else if(ca1_edge == 1'b1) begin
          ca2_out <= 1'b1;
        end
        else begin
          ca2_out <= ca2_out;
        end
      end
      3'b101 : begin
        // read PA clears, E sets
        ca2_out <=  ~porta_read;
      end
      3'b110 : begin
        // set low
        ca2_out <= 1'b0;
      end
      3'b111 : begin
        // set high
        ca2_out <= 1'b1;
      end
      default : begin
        // no change
        ca2_out <= ca2_out;
      end
      endcase
    end
  end

  //-------------------------------
  //
  // CA2 direction control
  //
  //-------------------------------
  always @(porta_ctrl, ca2_out) begin
    if(porta_ctrl[5] == 1'b0) begin
      ca2_oe <= 1'b0;
      ca2_o <= 1'b0;
    end
    else begin
      ca2_o <= ca2_out;
      ca2_oe <= 1'b1;
    end
  end

  //-------------------------------
  //
  // direction control port b
  //
  //-------------------------------
  always @(portb_data, portb_ddr) begin : P1
    reg [31:0] count;

    for (count=0; count <= 7; count = count + 1) begin
      if(portb_ddr[count] == 1'b1) begin
        pb_o[count] <= portb_data[count];
        pb_oe[count] <= 1'b1;
      end
      else begin
        pb_o[count] <= 1'b0;
        pb_oe[count] <= 1'b0;
      end
    end
  end

  //-------------------------------
  //
  // CB1 Edge detect
  //
  //-------------------------------
  always @(negedge clk) begin // , negedge rst, negedge cb1, negedge cb1_del, negedge cb1_rise, negedge cb1_fall, negedge cb1_edge, negedge irqb1, negedge portb_ctrl, negedge portb_read) begin
    if(rst == 1'b1) begin
      cb1_del <= 1'b0;
      cb1_rise <= 1'b0;
      cb1_fall <= 1'b0;
      cb1_edge <= 1'b0;
      irqb1 <= 1'b0;
    end else begin
      cb1_del <= cb1;
      cb1_rise <= ( ~cb1_del) & cb1;
      cb1_fall <= cb1_del & ( ~cb1);
      if(cb1_edge == 1'b1) begin
        irqb1 <= 1'b1;
      end
      else if(portb_read == 1'b1) begin
        irqb1 <= 1'b0;
      end
      else begin
        irqb1 <= irqb1;
      end
    end

    if(portb_ctrl[1] == 1'b0) 
	    cb1_edge <= cb1_fall;
    else
	    cb1_edge <= cb1_rise;

  end

  //-------------------------------
  //
  // CB2 Edge detect
  //
  //-------------------------------
  always @(negedge clk) begin //, negedge rst, negedge cb2_i, negedge cb2_del, negedge cb2_rise, negedge cb2_fall, negedge cb2_edge, negedge irqb2, negedge portb_ctrl, negedge portb_read) begin
    if(rst == 1'b1) begin
      cb2_del <= 1'b0;
      cb2_rise <= 1'b0;
      cb2_fall <= 1'b0;
      cb2_edge <= 1'b0;
      irqb2 <= 1'b0;
    end else begin
      cb2_del <= cb2_i;
      cb2_rise <= ( ~cb2_del) & cb2_i;
      cb2_fall <= cb2_del & ( ~cb2_i);
      if(portb_ctrl[5] == 1'b0 && cb2_edge == 1'b1) begin
        irqb2 <= 1'b1;
      end
      else if(portb_read == 1'b1) begin
        irqb2 <= 1'b0;
      end
      else begin
        irqb2 <= irqb2;
      end
    end

    if(portb_ctrl[4] == 1'b0) 
	    cb2_edge <= cb2_fall;
    else
	    cb2_edge <= cb2_rise;

  end

  //-------------------------------
  //
  // CB2 output control
  //
  //-------------------------------
  always @(negedge clk) begin //, negedge rst, negedge portb_ctrl, negedge portb_write, negedge cb1_edge, negedge cb2_out) begin
    if(rst == 1'b1) begin
      cb2_out <= 1'b0;
    end else begin
      case(portb_ctrl[5:3])
      3'b100 : begin
        // write PB clears, CA1 edge sets
        if(portb_write == 1'b1) begin
          cb2_out <= 1'b0;
        end
        else if(cb1_edge == 1'b1) begin
          cb2_out <= 1'b1;
        end
        else begin
          cb2_out <= cb2_out;
        end
      end
      3'b101 : begin
        // write PB clears, E sets
        cb2_out <=  ~portb_write;
      end
      3'b110 : begin
        // set low
        cb2_out <= 1'b0;
      end
      3'b111 : begin
        // set high
        cb2_out <= 1'b1;
      end
      default : begin
        // no change
        cb2_out <= cb2_out;
      end
      endcase
    end
  end

  //-------------------------------
  //
  // CB2 direction control
  //
  //-------------------------------
  always @(portb_ctrl, cb2_out) begin
    if(portb_ctrl[5] == 1'b0) begin
      cb2_oe <= 1'b0;
      cb2_o <= 1'b0;
    end
    else begin
      cb2_o <= cb2_out;
      cb2_oe <= 1'b1;
    end
  end

  //-------------------------------
  //
  // IRQ control
  //
  //-------------------------------
  always @(irqa1, irqa2, irqb1, irqb2, porta_ctrl, portb_ctrl) begin
    irqa <= (irqa1 & porta_ctrl[0]) | (irqa2 & porta_ctrl[3]);
    irqb <= (irqb1 & portb_ctrl[0]) | (irqb2 & portb_ctrl[3]);
  end


endmodule
