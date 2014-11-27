-- 	File: dyplo_user_logic_stub.vhd
--	
--	� COPYRIGHT 2014 TOPIC EMBEDDED PRODUCTS B.V. ALL RIGHTS RESERVED.
--	
--	This file contains confidential and proprietary information of 
--	Topic Embedded Products B.V. and is protected under Dutch and 
--	International copyright and other international intellectual property laws.
--	
--	Disclaimer
--	
--	This disclaimer is not a license and does not grant any rights to the 
--	materials distributed herewith. Except as otherwise provided in a valid 
--	license issued to you by Topic Embedded Products B.V., and to the maximum 
--	extend permitted by applicable law:
--
--	1.	Dyplo is furnished on an �as is�, as available basis. Topic makes no 
--	warranty, express or implied, with respect to the capability of Dyplo. All 
--	warranties of any type, express or implied, including the warranties of 
--	merchantability, fitness for a particular purpose and non-infringement of 
--	third party rights are expressly disclaimed.
--	
--	2.	Topic�s maximum total liability shall be limited to general money 
--	damages in an amount not to exceed the total amount paid for in the year 
--	in which the damages have occurred.  Under no circumstances including 
--	negligence shall Topic be liable for direct, indirect, incidental, special, 
--	consequential or punitive damages, or for loss of profits, revenue, or data, 
--	that are directly or indirectly related to the use of, or the inability to 
--	access and use Dyplo and related services, whether in an action in contract, 
--	tort, product liability, strict liability, statute or otherwise even if 
--	Topic has been advised of the possibility of those damages. 
--	
--	This copyright notice and disclaimer must be retained as part of this file at all times.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

library dyplo_hdl_node_lib;
use dyplo_hdl_node_lib.hdl_node_package.all;
use dyplo_hdl_node_lib.hdl_node_user_params.all;

entity dyplo_user_logic_adder is
  generic(
    INPUT_STREAMS        : integer := 4;
    OUTPUT_STREAMS       : integer := 4
  );
  port(
    -- Processor bus interface
    dab_clk             : in  std_logic;
    dab_rst             : in  std_logic;
    dab_addr            : in  std_logic_vector(15 DOWNTO 0);
    dab_sel             : in  std_logic;
    dab_wvalid          : in  std_logic;
    dab_rvalid          : in  std_logic;
    dab_wdata           : in  std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
    dab_rdata           : out std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
    -- Streaming input interfaces
    cin_tdata           : in cin_tdata_ul_type;
    cin_tvalid          : in std_logic_vector(INPUT_STREAMS - 1 downto 0);
    cin_tready          : out std_logic_vector(INPUT_STREAMS - 1 downto 0);
    cin_tlevel          : in cin_tlevel_ul_type;
    -- Streaming output interfaces
    cout_tdata          : out cout_tdata_ul_type;
    cout_tvalid         : out std_logic_vector(OUTPUT_STREAMS - 1 downto 0);
    cout_tready         : in std_logic_vector(OUTPUT_STREAMS - 1 downto 0);
    -- Clock signals
    user_clocks         : in std_logic_vector(3 downto 0)   
  );
end dyplo_user_logic_adder;

architecture rtl of dyplo_user_logic_adder is
  type signed_matrix_4x32 is array (0 to INPUT_STREAMS - 1) of signed(31 downto 0);
  signal value_to_add     : signed_matrix_4x32;
  signal cin_tdata_i      : signed_matrix_4x32;
  signal cout_tdata_i     : signed_matrix_4x32;
begin

  config_reg : process (dab_clk)
    variable index : integer;
  begin
    if rising_edge(dab_clk) then
      if (dab_rst = '1') then
        value_to_add <= (others => (others => '0'));
      else
        index := to_integer(unsigned(dab_addr(3 downto 2)));
        if (dab_sel = '1') and (dab_wvalid = '1') then
          value_to_add(index) <= signed(dab_wdata);
        end if;
      dab_rdata <= std_logic_vector(value_to_add(index));
      end if;
    end if;
  end process config_reg;
    
  adders : for i in 0 to 3 generate
  
      type sm_calc_states is (S_FETCH, S_CALC, S_SEND, S_FINISH);
      signal sm_calc : sm_calc_states;
      signal tdata   : signed(31 downto 0);
  
  begin    

    calc_data : process (dab_clk)
    begin
      if rising_edge(dab_clk) then
        if (dab_rst = '1') then
          cout_tdata_i(i)   <= (others => '0');
          cout_tvalid(i)    <= '0';
          cin_tready(i)     <= '0';
          sm_calc           <= S_FETCH;
          tdata             <= (others => '0');
        else
          case sm_calc is
            when S_FETCH =>
              if (cin_tvalid(i) = '1') and (conv_integer(cin_tlevel(i)) /= 0) then
                cin_tready(i)  <= '1';
                tdata <= to_signed(conv_integer(cin_tdata(i)),32);
                sm_calc <= S_CALC;
              end if;
            when S_CALC =>
              cin_tready(i)  <= '0';
              cout_tdata_i(i) <= tdata + value_to_add(i);
              cout_tvalid(i) <= '1';
              
              sm_calc <= S_SEND;
            when S_SEND =>
              if (cout_tready(i) = '1') then
                cout_tvalid(i) <= '0';
                sm_calc <= S_FINISH;
              end if;
            when S_FINISH =>
              sm_calc <= S_FETCH;
          end case;
        end if;
      end if;
    end process calc_data;
    
  end generate adders;
  
  cout_tdata(0)    <= std_logic_vector(cout_tdata_i(0));
  cout_tdata(1)    <= std_logic_vector(cout_tdata_i(1));
  cout_tdata(2)    <= std_logic_vector(cout_tdata_i(2));
  cout_tdata(3)    <= std_logic_vector(cout_tdata_i(3));
end rtl;
