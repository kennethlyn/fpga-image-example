-- 	File: dyplo_hdl_node.vhd
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
--	1.	Dyplo is furnished on an "as is", as available basis. Topic makes no 
--	warranty, express or implied, with respect to the capability of Dyplo. All 
--	warranties of any type, express or implied, including the warranties of 
--	merchantability, fitness for a particular purpose and non-infringement of 
--	third party rights are expressly disclaimed.
--	
--	2.	Topic's maximum total liability shall be limited to general money 
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
use ieee.math_real.all;

library dyplo_hdl_node_lib;
use dyplo_hdl_node_lib.hdl_node_package.all;
use dyplo_hdl_node_lib.hdl_node_user_params.all;

library user_logic;
use user_logic.all;

entity dyplo_hdl_node is
  port(
    -- Miscellaneous
    node_id           : in std_logic_vector(c_hdl_node_id_width - 1 downto 0);
    -- DAB interface
    dab_clk           : in std_logic;
    dab_rst           : in std_logic;
    dab_addr          : in std_logic_vector(c_hdl_dab_awidth - 1 downto 0);
    dab_sel           : in std_logic;
    dab_wvalid        : in std_logic;
    dab_rvalid        : in std_logic;
    dab_wdata         : in std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
    dab_rdata         : out std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
    -- Receive data from backplane to FIFO
    b2f_tdata         : in std_logic_vector(c_hdl_backplane_bus_width - 1 downto 0);
    b2f_tstream_id    : in std_logic_vector(c_hdl_stream_id_width - 1 downto 0);
    b2f_tvalid        : in std_logic;
    b2f_tready        : out std_logic;   
    -- Send data from FIFO to backplane
    f2b_tdata         : out std_logic_vector(c_hdl_backplane_bus_width - 1 downto 0);
    f2b_tstream_id    : out std_logic_vector(c_hdl_stream_id_width - 1 downto 0);
    f2b_tvalid        : out std_logic;
    f2b_tready        : in std_logic;
    -- Serial fifo status info
    fifo_status_sync  : in std_logic;
    fifo_status_flag  : out std_logic; 
    -- fifo statuses of destination fifo's
    dest_fifo_status	: in std_logic_vector(3 downto 0); 
    -- Clock signals
    user_clocks       : in std_logic_vector(3 downto 0)
  ); 
    
  attribute secure_config : string;
  attribute secure_config of dyplo_hdl_node : entity is "PROTECT";
  attribute secure_netlist : string;
  attribute secure_netlist of dyplo_hdl_node : entity is "ENCRYPT";  
  attribute secure_net_editing : string;
  attribute secure_net_editing of dyplo_hdl_node : entity is "PROHIBIT";  
  attribute secure_net_probing : string;
  attribute secure_net_probing of dyplo_hdl_node : entity is "PROHIBIT";
    
end dyplo_hdl_node;

architecture rtl of dyplo_hdl_node is

  component dyplo_user_logic_adder is
  generic(
    INPUT_STREAMS        : integer := 4;
    OUTPUT_STREAMS       : integer := 4
  );
  port(
    -- Processor bus interface
    dab_clk             : in  std_logic;
    dab_rst             : in  std_logic;
    dab_addr            : in  std_logic_vector(15 downto 0);
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
  end component dyplo_user_logic_adder;  

  signal dab_sel_ul           : std_logic;
  signal dab_wvalid_ul        : std_logic;
  signal dab_rvalid_ul        : std_logic;
  signal dab_rdata_ul         : std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);

  signal cin_tdata_i          : cin_tdata_ul_type;
  signal cin_tvalid_i         : std_logic_vector(c_input_streams - 1 downto 0);
  signal cin_tready_i         : std_logic_vector(c_input_streams - 1 downto 0);
  signal cin_tlevel_i         : cin_tlevel_ul_type;

  signal cout_tdata_i         : cout_tdata_ul_type;
  signal cout_tvalid_i        : std_logic_vector(c_output_streams - 1 downto 0);
  signal cout_tready_i        : std_logic_vector(c_output_streams - 1 downto 0);
    
begin

  -----------------------------------------------------------------------------
  -- CONTROL MEMORY MAP FOR CPU FIFO INTERFACE                               --
  -----------------------------------------------------------------------------
  -- The available memory range for the CPU fifo control is limited to       --
  -- 64Kbyte/32 = 2Kbytes or 512 words. The maximum burst transfer of the    --
  -- AXI bus is 256 words. The actual FIFO data memory range is also limited --
  -- to 64Kbytes or 16Kwords. Also, the space is divided between reading and --
  -- writing. This leaves 8Kwords per direction and with a burst length of   --
  -- 256 words, maximum 32 input streams and 32 output streams can be        --
  -- supported.                                                              --
  -----------------------------------------------------------------------------
  -- Each fifo has the following metrics:                                    --
  -- - FIFO full and FIFO empty flag                                         --
  -- - FIFO fill level compare register and compare flag                     --
  -- - Actual FIFO fill level indicator                                      --
  -- - Under/overflow detection flag when operating FIFO out of range        --
  --                                                                         --
  -- Per input FIFO (from FPGA fabric to the CPU) it is required to specify  --
  -- the stream source. Also, a maskable interrupt should be issued per      --
  -- input FIFO to signal the need to empty the FIFO by the CPU.             --  
  -----------------------------------------------------------------------------

  dyplo_hdl_node_logic_i : dyplo_hdl_node_logic
  generic map (
    INPUT_STREAMS        => c_input_streams,
    OUTPUT_STREAMS       => c_output_streams  	
  )
  port map(
    -- Miscellaneous
    node_id           =>  node_id,
    -- DAB interface
    dab_clk           =>  dab_clk,
    dab_rst           =>  dab_rst,
    dab_addr          =>  dab_addr,
    dab_sel           =>  dab_sel,
    dab_wvalid        =>  dab_wvalid,
    dab_rvalid        =>  dab_rvalid,
    dab_wdata         =>  dab_wdata,
    dab_rdata         =>  dab_rdata,
    -- Receive data from backplane to FIFO
    b2f_tdata         =>  b2f_tdata,
    b2f_tstream_id    =>  b2f_tstream_id,
    b2f_tvalid        =>  b2f_tvalid,
    b2f_tready        =>  b2f_tready,   
    -- Send data from FIFO to backplane
    f2b_tdata         =>  f2b_tdata,
    f2b_tstream_id    =>  f2b_tstream_id,
    f2b_tvalid        =>  f2b_tvalid,
    f2b_tready        =>  f2b_tready,
    -- Serial fifo status info
    fifo_status_sync  => fifo_status_sync,
    fifo_status_flag  => fifo_status_flag,
    -- fifo statuses of destination fifo's
    dest_fifo_status	=> dest_fifo_status(c_output_streams - 1 downto 0),
    -- DAB interface to user logic
    dab_sel_ul        =>  dab_sel_ul,
    dab_wvalid_ul     =>  dab_wvalid_ul,
    dab_rvalid_ul     =>  dab_rvalid_ul,
    dab_rdata_ul      =>  dab_rdata_ul,  
    -- In streams to user logic  
    cin_tdata_ul      =>  cin_tdata_i,
    cin_tvalid_ul     =>  cin_tvalid_i,
    cin_tready_ul     =>  cin_tready_i,
    cin_tlevel_ul     =>  cin_tlevel_i,
    -- Out streams from user logic
    cout_tdata_ul     =>  cout_tdata_i,
    cout_tvalid_ul    =>  cout_tvalid_i,
    cout_tready_ul    =>  cout_tready_i
  );
  
  dyplo_user_logic_i : dyplo_user_logic_adder
  generic map(
    INPUT_STREAMS        => c_input_streams,
    OUTPUT_STREAMS       => c_output_streams
  )
  port map(
    -- Processor bus interface
    dab_clk             => dab_clk,
    dab_rst             => dab_rst,
    dab_addr            => dab_addr(15 downto 0),
    dab_sel             => dab_sel_ul,
    dab_wvalid          => dab_wvalid_ul,
    dab_rvalid          => dab_rvalid_ul,
    dab_wdata           => dab_wdata,
    dab_rdata           => dab_rdata_ul,
    -- Streaming input interfaces
    cin_tdata           => cin_tdata_i,
    cin_tvalid          => cin_tvalid_i,
    cin_tready          => cin_tready_i,
    cin_tlevel          => cin_tlevel_i,
    -- Streaming output interfaces
    cout_tdata          => cout_tdata_i,
    cout_tvalid         => cout_tvalid_i,
    cout_tready         => cout_tready_i,
    -- Clock signals
    user_clocks         => user_clocks  
  );
    
end rtl;

