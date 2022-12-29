-------------------------------------------------------------------------------
--
-- PIA MC6821 testbench, assertion-based tests for all PIA features
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
-- $Id: mc6821_tb.vhd 1534 2021-01-05 15:03:23Z wolfi $
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mc6821_tb is
end mc6821_tb;

architecture BEH of mc6821_tb is

  signal clk_i : STD_LOGIC;
  signal e_i : STD_LOGIC;	-- edge sampling on rising E edge
  signal e_n_i : STD_LOGIC;	-- interface samples on falling E edge
  signal rstn_i : STD_LOGIC;
  signal cs0_i : STD_LOGIC;
  signal cs1_i : STD_LOGIC;
  signal cs2n_i : STD_LOGIC;
  signal rd_wrn_i : STD_LOGIC;
  signal rs_i : STD_LOGIC_VECTOR (1 downto 0);
  signal data_i : STD_LOGIC_VECTOR (7 downto 0);
  signal data_o : STD_LOGIC_VECTOR (7 downto 0);
  signal irqan_o : STD_LOGIC;
  signal irqbn_o : STD_LOGIC;
  signal pa_i : STD_LOGIC_VECTOR (7 downto 0);
  signal pa_o : STD_LOGIC_VECTOR (7 downto 0);
  signal ca1_i : STD_LOGIC;
  signal ca2_i : STD_LOGIC;
  signal ca2_o : STD_LOGIC;
  signal pb_i : STD_LOGIC_VECTOR (7 downto 0);
  signal pb_o : STD_LOGIC_VECTOR (7 downto 0);
  signal cb1_i : STD_LOGIC;
  signal cb2_i : STD_LOGIC;
  signal cb2_o : STD_LOGIC;

procedure idle_cycle
 ( signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= "11111111";
  rs <= "11";
  rw <= '1';
  cs <= '0';
  wait until e='1' and rising_edge(clk);
end idle_cycle;

procedure rd_da_cycle
 ( check : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= "11111111";
  rs <= "00";
  rw <= '1';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=check report "read data A mismatch" severity error;
  cs <= '0';
end rd_da_cycle;

procedure rd_db_cycle
 ( check : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= "11111111";
  rs <= "10";
  rw <= '1';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=check report "read data B mismatch" severity error;
  cs <= '0';
end rd_db_cycle;

procedure rd_ca_cycle
 ( check : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= "11111111";
  rs <= "01";
  rw <= '1';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=check report "read control A mismatch" severity error;
  cs <= '0';
end rd_ca_cycle;

procedure rd_cb_cycle
 ( check : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= "11111111";
  rs <= "11";
  rw <= '1';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=check report "read control B mismatch" severity error;
  cs <= '0';
end rd_cb_cycle;

procedure wr_da_cycle
 ( newval : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= newval;
  rs <= "00";
  rw <= '0';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=newval report "write data A mismatch" severity error;
  cs <= '0';
end wr_da_cycle;

procedure wr_db_cycle
 ( newval : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= newval;
  rs <= "10";
  rw <= '0';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=newval report "write data B mismatch" severity error;
  cs <= '0';
end wr_db_cycle;

procedure wr_ca_cycle
 ( newval : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= newval;
  rs <= "01";
  rw <= '0';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=newval report "write control A mismatch" severity error;
  cs <= '0';
end wr_ca_cycle;

procedure wr_cb_cycle
 ( newval : in STD_LOGIC_VECTOR (7 downto 0);
   signal clk : in STD_LOGIC;
   signal e   : in STD_LOGIC;
   signal do  : out STD_LOGIC_VECTOR (7 downto 0);
   signal rs  : out STD_LOGIC_VECTOR (1 downto 0);
   signal rw  : out STD_LOGIC;
   signal cs  : out STD_LOGIC;
   signal di  : in STD_LOGIC_VECTOR (7 downto 0)
   ) is
begin
  do <= newval;
  rs <= "11";
  rw <= '0';
  cs <= '1';
  wait until e='1' and rising_edge(clk);
  assert di=newval report "write control B mismatch" severity error;
  cs <= '0';
end wr_cb_cycle;

begin

  -- PIA device under test
   DUT : entity work.mc6821 port map (
	   clk_i  => clk_i,
	   e_i  => e_i,
	   e_n_i  => e_n_i,
	   rstn_i  => rstn_i,
	   cs0_i  => cs0_i,
	   cs1_i  => cs1_i,
	   cs2n_i  => cs2n_i,
	   rd_wrn_i  => rd_wrn_i,
	   rs_i  => rs_i,
	   data_i  => data_i,
	   data_o  => data_o,
	   irqan_o  => irqan_o,
	   irqbn_o  => irqbn_o,
	   pa_i  => pa_i,
	   pa_o  => pa_o,
	   ca1_i  => ca1_i,
	   ca2_i  => ca2_i,
	   ca2_o  => ca2_o,
	   pb_i  => pb_i,
	   pb_o  => pb_o,
	   cb1_i  => cb1_i,
	   cb2_i  => cb2_i,
	   cb2_o  => cb2_o
   );

   -- reset cycle, low-active
   res : process is
   begin
	 rstn_i <= '0';
	 wait for 100 ns;
	 rstn_i <= '1';
	 wait;
   end process;

   -- clock and clock gates
   -- (emulates E clock of a 68xx MCU system)
   clk : process is
   begin
	 e_i <= '0';
	 e_n_i <= '0';
	 clk_i <= '0';
	 wait for 5 ns;
	 clk_i <= '1';
	 wait for 5 ns;
	 clk_i <= '0';
	 wait for 5 ns;
	 clk_i <= '1';
	 wait for 5 ns;
	 clk_i <= '0';
	 e_i <= '1';
	 wait for 5 ns;
	 clk_i <= '1';
	 wait for 5 ns;
	 e_i <= '0';
	 e_n_i <= '0';
	 clk_i <= '0';
	 wait for 5 ns;
	 clk_i <= '1';
	 wait for 5 ns;
	 clk_i <= '0';
	 wait for 5 ns;
	 clk_i <= '1';
	 wait for 5 ns;
	 clk_i <= '0';
	 e_n_i <= '1';
	 wait for 5 ns;
	 clk_i <= '1';
	 wait for 5 ns;
   end process;

   -- all tests, will cause an ERROR on assertion failure
   -- final FAILURE assertion indicates that all tests are done (no error)
   stim : process is
   begin
	 rd_wrn_i <= '1';
	 cs0_i <= '1';
	 cs1_i <= '0';
	 cs2n_i <= '0';
	 rs_i <= "00";
     data_i <= "11111111";
     pa_i <= "11111111";
     pb_i <= "11111111";
	 ca1_i <= '0';
	 ca2_i <= '0';
	 cb1_i <= '0';
	 cb2_i <= '0';
	 wait until rstn_i='1';
     pa_i <= "00000000";
     pb_i <= "00000000";
	 wait until e_n_i='1' and rising_edge(clk_i);
     pa_i <= "10100101";
     pb_i <= "01011010";
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check reset values and other CS
     assert false report "Check reset values and other CS" severity note;
     assert pa_o="11111111" report "port A mismatch" severity error;
     assert pb_o="11111111" report "port b mismatch" severity error;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 rd_da_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cs0_i <= '0';
	 cs2n_i <= '0';
	 rd_da_cycle("11111111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cs0_i <= '1';
	 cs2n_i <= '1';
	 rd_da_cycle("11111111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cs0_i <= '1';
	 cs2n_i <= '0';
	 rd_da_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check port A / B readback
     assert false report "Check port A/B readback as input" severity note;
	 wr_ca_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_cb_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("01011010",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 -- set back and check again
	 wr_ca_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_cb_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check A / B direction and readback
     assert false report "Check A/B direction and readback" severity note;
	 wr_da_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
     assert pa_o="11000011" report "port A mismatch" severity error;
     assert pb_o="11111111" report "port B mismatch" severity error;
	 rd_da_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_db_cycle("11000011",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
     assert pa_o="11000011" report "port A mismatch" severity error;
     assert pb_o="00111100" report "port B mismatch" severity error;
	 rd_db_cycle("11000011",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_da_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
     assert pa_o="11111111" report "port A mismatch" severity error;
     assert pb_o="00111100" report "port B mismatch" severity error;
	 rd_da_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_db_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
     assert pa_o="11111111" report "port A mismatch" severity error;
     assert pb_o="11111111" report "port B mismatch" severity error;
	 rd_db_cycle("00000000",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check port A / B readback
     assert false report "Check port A/B readback /w direction" severity note;
	 wr_da_cycle("11000011",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("11000011",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_db_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
     assert pa_o="00111100" report "port A mismatch" severity error;
     assert pb_o="11000011" report "port B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_ca_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_cb_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("01000010",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_da_cycle("01011010",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_db_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("01100110",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
     assert pa_o="01111110" report "port A mismatch" severity error;
     assert pb_o="11100111" report "port B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check port A flags
     assert false report "Check port A flags" severity note;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 ca1_i <= '1';
	 rd_ca_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 ca1_i <= '0';
	 rd_ca_cycle("10000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 ca2_i <= '1';
	 rd_ca_cycle("10000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 ca2_i <= '0';
	 rd_ca_cycle("11000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check port A interrupt
     assert false report "Check port A interrupt" severity note;
	 wr_ca_cycle("00000101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='0' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 wr_ca_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 wr_ca_cycle("00001100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='0' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 wr_ca_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='0' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check falling edge detect A1
     assert false report "Check falling edge detect A1" severity note;
	 ca1_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 ca1_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='0' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("10001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
     
	 -- check falling edge detect A2
     assert false report "Check falling edge detect A2" severity note;
	 ca2_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 ca2_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='0' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("01001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check rising edge detect A1
     assert false report "Check rising edge detect A1" severity note;
	 wr_ca_cycle("00000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 ca1_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='0' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("10000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("00000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 ca1_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
     
	 -- check rising edge detect A2
     assert false report "Check rising edge detect A2" severity note;
	 wr_ca_cycle("00011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 ca2_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='0' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("01011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 ca2_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_ca_cycle("00011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check port B flags
     assert false report "Check port B flags" severity note;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 cb1_i <= '1';
	 rd_cb_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 cb1_i <= '0';
	 rd_cb_cycle("10000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 cb2_i <= '1';
	 rd_cb_cycle("10000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 cb2_i <= '0';
	 rd_cb_cycle("11000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check port B interrupt
     assert false report "Check port B interrupt" severity note;
	 wr_cb_cycle("00000101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='0' report "irq B mismatch" severity error;
	 wr_cb_cycle("00000100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 wr_cb_cycle("00001100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='0' report "irq B mismatch" severity error;
	 wr_cb_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='0' report "irq B mismatch" severity error;
	 rd_db_cycle("01100110",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_cb_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- check falling edge detect B1
     assert false report "Check falling edge detect B1" severity note;
	 cb1_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cb1_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='0' report "irq B mismatch" severity error;
	 rd_cb_cycle("10001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("01100110",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_cb_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
     
	 -- check falling edge detect B2
     assert false report "Check falling edge detect B2" severity note;
	 cb2_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cb2_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='0' report "irq B mismatch" severity error;
	 rd_cb_cycle("01001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("01100110",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_cb_cycle("00001101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
     
	 -- check rising edge detect B1
     assert false report "Check rising edge detect B1" severity note;
	 wr_cb_cycle("00000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cb1_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='0' report "irq B mismatch" severity error;
	 rd_cb_cycle("10000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("01100110",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_cb_cycle("00000111",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cb1_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
     
	 -- check rising edge detect B2
     assert false report "Check rising edge detect B2" severity note;
	 wr_cb_cycle("00011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cb2_i <= '1';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='0' report "irq B mismatch" severity error;
	 rd_cb_cycle("01011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_db_cycle("01100110",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 cb2_i <= '0';
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert irqan_o='1' report "irq A mismatch" severity error;
	 assert irqbn_o='1' report "irq B mismatch" severity error;
	 rd_cb_cycle("00011100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- set/clear A2/B2
     assert false report "Set/clear A2/B2" severity note;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wr_ca_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wr_ca_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_ca_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wr_cb_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='0' report "CB2 mismatch" severity error;
	 wr_cb_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00111100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wr_ca_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wr_cb_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='0' report "CB2 mismatch" severity error;
	 rd_ca_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00110100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- read A2 / write B2 strobe with E
     assert false report "Read A2 / write B2 strobe with E" severity note;
	 wr_ca_cycle("00101100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='0' report "CB2 mismatch" severity error;
	 rd_ca_cycle("00101100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_cb_cycle("00101100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 rd_cb_cycle("00101100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 --
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 --
	 wr_db_cycle("01010101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wait until e_i='1' and rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='0' report "CB2 mismatch" severity error;
	 wait until e_i='1' and rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wait until e_n_i='1' and rising_edge(clk_i);
	 rd_ca_cycle("00101100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_cb_cycle("00101100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);

	 -- read A2 / write B2 strobe with E+CA1/CB1
     assert false report "Read A2 / write B2 strobe with E+CA1/CB1" severity note;
	 wr_ca_cycle("00100100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wr_cb_cycle("00100100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 rd_ca_cycle("00100100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 rd_cb_cycle("00100100",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 --
	 rd_da_cycle("10100101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wait until e_n_i='1' and rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wait until e_n_i='1' and rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 ca1_i <= '1';
	 wait until rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='0' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 ca1_i <= '0';
	 wait until rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wait until e_n_i='1' and rising_edge(clk_i);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 --
	 wr_db_cycle("01010101",clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wait until e_i='1' and rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='0' report "CB2 mismatch" severity error;
	 wait until e_i='1' and rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='0' report "CB2 mismatch" severity error;
	 cb1_i <= '1';
	 wait until rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='0' report "CB2 mismatch" severity error;
	 cb1_i <= '0';
	 wait until rising_edge(clk_i);
	 wait for 1 ns;
	 assert ca2_o='1' report "CA2 mismatch" severity error;
	 assert cb2_o='1' report "CB2 mismatch" severity error;
	 wait until e_n_i='1' and rising_edge(clk_i);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);


	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
	 idle_cycle(clk_i,e_n_i,data_i,rs_i,rd_wrn_i,cs1_i,data_o);
     assert false report "Simulation finished" severity failure;
	 wait;
   end process;

end BEH;

