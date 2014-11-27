-- 	File: dyplo_user_logic_adder_2_to_1.vhd
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library dyplo_hdl_node_lib;
use dyplo_hdl_node_lib.hdl_node_package.all;
use dyplo_hdl_node_lib.hdl_node_user_params.all;

entity dyplo_user_logic_adder_2_to_1 is
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
end dyplo_user_logic_adder_2_to_1;

architecture rtl of dyplo_user_logic_adder_2_to_1 is

  type sm_calc_type is (RECEIVE, SEND);
  signal sm_calc  : sm_calc_type; 

begin      
  process(dab_clk)
  begin
    if(rising_edge(dab_clk)) then
      if(dab_rst = '1') then
        cout_tdata    <= (others => (others => '0'));
        cout_tvalid   <= (others => '0');
        cin_tready    <= (others => '0');
        
        sm_calc       <= RECEIVE;
      else
      
        case(sm_calc) is
          when RECEIVE =>
            if(cin_tvalid(0) = '1' and cin_tvalid(1) = '1') then
              cin_tready(1 downto 0)  <= "11";
              cout_tdata(0)           <= cin_tdata(0) + cin_tdata(1);
              cout_tvalid(0)          <= '1'; 
              
              sm_calc                 <= SEND;
            end if;
              
          when SEND =>
            cin_tready(1 downto 0)  <= "00";
            
            if(cout_tready(0) = '1') then
              cout_tvalid(0)  <= '0';
              
              sm_calc         <= RECEIVE;
            end if;
        end case;

      end if;
    end if;
  end process;   

end rtl;
