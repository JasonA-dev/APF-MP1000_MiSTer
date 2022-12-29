-------------------------------------------------------------------------------
--
-- PIA MC6821, synchronous implementation for FPGA-based systems
--
-- (c) 2020,2021 Wolfgang Scherr, woz <at> pin4.at
-- all rights reserved, use at your own risk
-- http://www.pin4.at/ or https://blog.fh-kaernten.at/retrofusion/
--
-------------------------------------------------------------------------------
-- Redistribution and use in source and synthesized forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- The code and any derivatives must not be used for commercial purposes 
-- without specific prior written permission by the author.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS CODE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
-- $Id: mc6821.vhd 1534 2021-01-05 15:03:23Z wolfi $
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mc6821 is
	-- set the level on port outputs if port is set to "input"
	-- this avoids using tri-state signals and allows separate I/O ports
	-- use wired and/or according to your needs on port pins
    generic ( instate_a : STD_LOGIC_VECTOR (7 downto 0):="11111111";
              instate_b : STD_LOGIC_VECTOR (7 downto 0):="11111111"
			);
	-- fully synchronous interface using clock gating
    Port ( clk_i : in  STD_LOGIC;   -- overall system clock 
           e_i : in  STD_LOGIC;	    -- edge sampling on rising E edge
           e_n_i : in  STD_LOGIC;	-- interface samples on falling E edge
           rstn_i : in  STD_LOGIC;  -- async. reset (low active)

		   -- bus interface
           cs0_i : in  STD_LOGIC;
           cs1_i : in  STD_LOGIC;
           cs2n_i : in  STD_LOGIC;
           rd_wrn_i : in  STD_LOGIC;
           rs_i : in  STD_LOGIC_VECTOR (1 downto 0);
           data_i : in  STD_LOGIC_VECTOR (7 downto 0);
           data_o : out  STD_LOGIC_VECTOR (7 downto 0);

		   -- low-active interrupts (use wired and)
           irqan_o : out  STD_LOGIC;
           irqbn_o : out  STD_LOGIC;

		   -- Port A, including handshake signals
           pa_i : in  STD_LOGIC_VECTOR (7 downto 0);
           pa_o : out  STD_LOGIC_VECTOR (7 downto 0);
		   ca1_i : in  STD_LOGIC;
		   ca2_i : in  STD_LOGIC;
		   ca2_o : out  STD_LOGIC;

		   -- Port B, including handshake signals
           pb_i : in  STD_LOGIC_VECTOR (7 downto 0);
           pb_o : out  STD_LOGIC_VECTOR (7 downto 0);
		   cb1_i : in  STD_LOGIC;
		   cb2_i : in  STD_LOGIC;
		   cb2_o : out  STD_LOGIC
         );
end mc6821;

architecture RTL of mc6821 is

  -- registers
  signal reg_ioa_s      : std_logic_vector(7 downto 0) := (others => '0');
  signal reg_ddra_s     : std_logic_vector(7 downto 0) := (others => '0');
  signal reg_ctrla_s    : std_logic_vector(5 downto 0) := (others => '0');
  signal reg_iob_s      : std_logic_vector(7 downto 0) := (others => '0');
  signal reg_ddrb_s     : std_logic_vector(7 downto 0) := (others => '0');
  signal reg_ctrlb_s    : std_logic_vector(5 downto 0) := (others => '0');

  -- IRQ flags
  signal irqa1_s      : std_logic;
  signal irqa2_s      : std_logic;
  signal irqb1_s      : std_logic;
  signal irqb2_s      : std_logic;

  -- helper signal as combined chip select
  signal cs_s           : std_logic;

  -- helper signals to detect edges on CA/CB
  signal ca1_del_s      : std_logic;
  signal cb1_del_s      : std_logic;
  signal ca2_del_s      : std_logic;
  signal cb2_del_s      : std_logic;

  -- helper signal for strobes
  signal sa_s           : std_logic;
  signal sb_s           : std_logic;

begin

  -- chip select
  cs_s <= '1' when cs0_i='1' and cs1_i='1' and cs2n_i='0' else
          '0';

   -- Register write & handshaking & interrupts/flags
  regproc : process (clk_i, rstn_i) is
  begin
    if rstn_i='0' then
	  -- INITIALIZATION: DS page 8
      reg_ioa_s <= (others => '0');
      reg_ddra_s <= (others => '0');
      reg_ctrla_s <= (others => '0');
      reg_iob_s <= (others => '0');
      reg_ddrb_s <= (others => '0');
      reg_ctrlb_s <= (others => '0');
	  -- INITIALIZATION: DS page 10
	  irqa1_s <= '0';
	  irqa2_s <= '0';
	  irqb1_s <= '0';
	  irqb2_s <= '0';
	  -- we down't know better
	  ca1_del_s <= '0';
	  cb1_del_s <= '0';
	  ca2_del_s <= '0';
	  cb2_del_s <= '0';
	  -- we down't know better
	  ca2_o <= '1';
	  cb2_o <= '1';
	  -- we down't know better
	  sa_s <= '0';
	  sb_s <= '0';
    elsif rising_edge(clk_i) then
	  -- INTERNAL ADDRESSING: DS page 8
	   if e_n_i='1' then
	      if cs_s='1' then
		    if rd_wrn_i='0' then -- write action
			  case to_integer(unsigned(rs_i)) is
				when 0 => 
					if reg_ctrla_s(2)='1' then
						reg_ioa_s <= data_i;
					else
						reg_ddra_s <= data_i;
					end if;
				when 1 =>
					reg_ctrla_s <= data_i(5 downto 0);
					if data_i(5 downto 4)="11" then
					  ca2_o <= data_i(3); -- direct write
					else
					  ca2_o <= '1'; -- reset to high (we don't know better)
					end if;
				when 2 =>
					if reg_ctrlb_s(2)='1' then
						reg_iob_s <= data_i;
					    -- strobe set by write
					    if reg_ctrlb_s(5 downto 4)="10" then
						  sb_s <= '1'; -- strobe to low on next rising E edge
					    end if;
					else
						reg_ddrb_s <= data_i;
					end if;
				when 3 =>
					reg_ctrlb_s <= data_i(5 downto 0);
					if data_i(5 downto 4)="11" then
					  cb2_o <= data_i(3); -- direct write
					else
					  cb2_o <= '1'; -- reset to high (we don't know better)
					end if;
				when others => null;
			  end case;
            else -- read action
			  case to_integer(unsigned(rs_i)) is
				when 0 => 
					if reg_ctrla_s(2)='1' then
					  -- RESET: DS page 10
					  irqa1_s <= '0';
					  irqa2_s <= '0';
					  -- strobe set by read
					  if reg_ctrla_s(5 downto 4)="10" then
						ca2_o <= '0'; -- strobe to low
					    sa_s <= '1'; -- reset on next falling E edge
					  end if;
					end if;
				when 2 =>
					if reg_ctrlb_s(2)='1' then
					  -- RESET: DS page 10
					  irqb1_s <= '0';
					  irqb2_s <= '0';
					end if;
				when others => null;
			  end case;
		    end if;
		  end if;
  		  -- strobe CA2
		  if sa_s='1' and reg_ctrla_s(5 downto 3)="101" then
            sa_s <= '0';
		    ca2_o <= '1'; -- reset to high on falling E
		  end if;
	   end if;
	   if e_i='1' then
  		  -- strobe CB2
		  if sb_s='1' then
		    cb2_o <= '0'; -- strobe to low on rising E
			sb_s <= '0';
		  elsif reg_ctrlb_s(5 downto 3)="101" then
		    cb2_o <= '1'; -- reset to high on rising E
		  end if;
	   end if;
	   -- set CA1/CB1 interrupt on active edge
	   if (ca1_i='1' and ca1_del_s='0' and reg_ctrla_s(1)='1') or -- low->high on CA1
	      (ca1_i='0' and ca1_del_s='1' and reg_ctrla_s(1)='0') then -- high->low on CA1
		  irqa1_s <= '1';
		  if reg_ctrla_s(5 downto 3)="100" then
		    ca2_o <= '1'; -- reset to high on CA1
		  end if;
		end if;
	   if (cb1_i='1' and cb1_del_s='0' and reg_ctrlb_s(1)='1') or -- low->high on CB1
	      (cb1_i='0' and cb1_del_s='1' and reg_ctrlb_s(1)='0') then -- high->low on CB1
		  irqb1_s <= '1';
		  if reg_ctrlb_s(5 downto 3)="100" then
		    cb2_o <= '1'; -- reset to high on CB1
		  end if;
		end if;
	   -- set CA2/CB2 interrupt on active edge
	   if (ca2_i='1' and ca2_del_s='0' and reg_ctrla_s(5 downto 4)="01") or -- low->high on CA2 (when input)
	      (ca2_i='0' and ca2_del_s='1' and reg_ctrla_s(5 downto 4)="00") then -- high->low on CA2 (when input)
		  irqa2_s <= '1';
		end if;
	   if (cb2_i='1' and cb2_del_s='0' and reg_ctrlb_s(5 downto 4)="01") or -- low->high on CB2 (when input)
	      (cb2_i='0' and cb2_del_s='1' and reg_ctrlb_s(5 downto 4)="00") then -- high->low on CB2 (when input)
		  irqb2_s <= '1';
		end if;
	   -- edge detector FFs (synchronous edge detection)
	   ca1_del_s <= ca1_i;
	   cb1_del_s <= cb1_i;
	   ca2_del_s <= ca2_i;
	   cb2_del_s <= cb2_i;
    end if;
  end process regproc;

  -- Register read
  data_o <= -- read DDR A
			reg_ddra_s when cs_s='1' and rd_wrn_i='1' and reg_ctrla_s(2)='0' and rs_i="00" else
		    -- always reads from pins A
		    pa_i when cs_s='1' and rd_wrn_i='1' and reg_ctrla_s(2)='1' and rs_i="00" else
			-- read control A
		    irqa1_s & (irqa2_s and not reg_ctrla_s(5)) & reg_ctrla_s when cs_s='1' and rd_wrn_i='1' and rs_i="01" else

			-- read DDR B
			reg_ddrb_s when cs_s='1' and rd_wrn_i='1' and reg_ctrlb_s(2)='0' and rs_i="10" else
		    -- an output bit (ddr='1') reads from the output register B, otherwise reads from pins B
			(reg_ddrb_s and reg_iob_s) or (not(reg_ddrb_s) and pb_i) when cs_s='1' and rd_wrn_i='1' and reg_ctrlb_s(2)='1' and rs_i="10" else
			-- read control B
		    irqb1_s & (irqb2_s and not reg_ctrlb_s(5)) & reg_ctrlb_s when cs_s='1' and rd_wrn_i='1' and rs_i="11" else

			-- passthrough
			data_i;

  -- interrupt outputs
  irqan_o <= '0' when irqa1_s='1' and reg_ctrla_s(0)='1' else  -- irqa1 event and enabled
             '0' when irqa2_s='1' and reg_ctrla_s(3)='1' and reg_ctrla_s(5)='0' else  -- irqa2 event and enabled
             '1';
  irqbn_o <= '0' when irqb1_s='1' and reg_ctrlb_s(0)='1' else  -- irqb1 event and enabled
             '0' when irqb2_s='1' and reg_ctrlb_s(3)='1' and reg_ctrlb_s(5)='0' else  -- irqb2 event and enabled
             '1';

  -- output ports
  pa_o <= (reg_ddra_s and reg_ioa_s) or (not(reg_ddra_s) and instate_a);
  pb_o <= (reg_ddrb_s and reg_iob_s) or (not(reg_ddrb_s) and instate_b);

end RTL;

