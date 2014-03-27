-- 	File: backplane_simulator.vhd
--	
--	© COPYRIGHT 2014 TOPIC EMBEDDED PRODUCTS B.V. ALL RIGHTS RESERVED.
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library tb_lib;
use tb_lib.tb_env_pkg.all;

library std;
use std.env.all;
use std.textio.all;

library dyplo_hdl_node_lib;
use dyplo_hdl_node_lib.hdl_node_package.all;

library dyplo_hdl_node_lib;
use dyplo_hdl_node_lib.hdl_node_user_params.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity backplane_simulator is
end backplane_simulator;

architecture rtl of backplane_simulator is

  -- clock and reset for testbench
  signal dab_clk          : std_logic := '0';
  signal dab_rst          : std_logic := '1';

  --Internal signals for HDL node
  signal dab_clk_i        : std_logic;
  signal dab_rst_i        : std_logic;
  signal dab_addr_i      : std_logic_vector(c_hdl_dab_awidth - 1 downto 0);
  signal dab_sel_i       : std_logic;
  signal dab_wvalid_i     : std_logic;
  signal dab_rvalid_i     : std_logic;
  signal dab_wdata_i      : std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
  signal dab_rdata_i      : std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
  -- Receive data from backplane to FIFO
  signal b2f_tdata_i      : std_logic_vector(c_hdl_backplane_bus_width - 1 downto 0);
  signal b2f_tstream_id_i : std_logic_vector(c_hdl_stream_id_width - 1 downto 0);
  signal b2f_tvalid_i     : std_logic;
  signal b2f_tready_i     : std_logic;
  -- Send data from FIFO to backplane
  signal f2b_tdata_i      : std_logic_vector(c_hdl_backplane_bus_width - 1 downto 0);
  signal f2b_tstream_id_i : std_logic_vector(c_hdl_stream_id_width - 1 downto 0);
  signal f2b_tnode_id_i   : std_logic_vector(c_hdl_node_id_width - 1 downto 0);
  signal f2b_tvalid_i     : std_logic;
  signal f2b_tready_i     : std_logic;
  -- Clock signals
  signal user_clocks_i    : std_logic_vector(3 downto 0); 
  
  --internal signals for stim_reader
  signal cmd_i            : cmd_record;
  signal cmd_accept_i     : std_logic;
  signal eof_i            : std_logic;
  
  --stream signals for datain stream processes
  type streams_in_tdata_type is array (0 to c_input_streams - 1) of std_logic_vector(c_hdl_backplane_bus_width - 1 downto 0); 
  type streams_in_tstream_id_type is array (0 to c_input_streams - 1) of std_logic_vector(c_hdl_stream_id_width - 1 downto 0); 
  signal streams_in_tdata         : streams_in_tdata_type;
  signal streams_in_tstream_id    : streams_in_tstream_id_type;
  signal streams_in_tvalid        : std_logic_vector(c_input_streams - 1 downto 0);
  signal streams_in_tready        : std_logic_vector(c_input_streams - 1 downto 0);   
  
  --tready signals for dataout stream processes
  signal streams_out_tready       : std_logic_vector(c_output_streams - 1 downto 0);  
  --tready signals for dataout combinatoric combined with tstream_id
  signal streams_out_tready_c     : std_logic_vector(c_output_streams - 1 downto 0);   
  
  --data signal for storing stream parameters for each stream
  type data_in_streams_type is array (0 to c_input_streams - 1) of data_stream;
  signal data_in_streams          : data_in_streams_type;
  type data_out_streams_type is array (0 to c_input_streams - 1) of data_stream;
  signal data_out_streams         : data_out_streams_type;    
 
  --type definition of type for state machine
  type sm_control_type is (IDLE, PARSE_CMD, DAB_DELAY_WRITE, DAB_DELAY_READ);
  signal sm_control               : sm_control_type := IDLE;
  
  signal schedule_in_streams      : integer := 0;
  
  signal dab_delay_cnt            : unsigned(1 downto 0);    --delay for dab r/w
  
  signal out_streams_enabled      : std_logic_vector(c_output_streams - 1 downto 0);
  signal out_streams_finished     : std_logic_vector(c_output_streams - 1 downto 0);
  
  signal in_streams_enabled      : std_logic_vector(c_input_streams - 1 downto 0);
  signal in_streams_finished     : std_logic_vector(c_input_streams - 1 downto 0);  

  --component declaration HDL_node
  component dyplo_hdl_node is
  port(
    -- Miscellaneous
    node_id           : in std_logic_vector(c_hdl_node_id_width - 1 downto 0);
    -- DAB interface
    dab_clk             : in  std_logic;
    dab_rst             : in  std_logic;
    dab_addr            : in  std_logic_vector(c_hdl_dab_awidth - 1 downto 0);
    dab_sel             : in  std_logic;
    dab_wvalid          : in  std_logic;
    dab_rvalid          : in  std_logic;
    dab_wdata           : in  std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
    dab_rdata           : out std_logic_vector(c_hdl_dab_dwidth - 1 downto 0);
    -- Receive data from backplane to FIFO
    b2f_tdata           : in std_logic_vector(c_hdl_backplane_bus_width - 1 downto 0);
    b2f_tstream_id      : in std_logic_vector(c_hdl_stream_id_width - 1 downto 0);
    b2f_tvalid          : in std_logic;
    b2f_tready          : out std_logic;   
    -- Send data from FIFO to backplane
    f2b_tdata           : out std_logic_vector(c_hdl_backplane_bus_width - 1 downto 0);
    f2b_tstream_id      : out std_logic_vector(c_hdl_stream_id_width - 1 downto 0);
    f2b_tnode_id        : out std_logic_vector(c_hdl_node_id_width - 1 downto 0);
    f2b_tvalid          : out std_logic;
    f2b_tready          : in std_logic;
    -- Serial fifo status info
    fifo_status_sync    : in std_logic;
    fifo_status_flag    : out std_logic;  
    -- Clock signals
    user_clocks         : in std_logic_vector(3 downto 0)
  );
  end component;
  
  --component declaration stim_reader
  component tb_stim_reader is
  generic(
    STIM_FILE_NAME  : string := ""
  );
  port (
    cmd_out         : out   cmd_record;
    cmd_accept_in   : in    std_logic;
    eof             : out   std_logic
  );
  end component;      

begin

  hdl_node : dyplo_hdl_node
  port map(
    -- Miscellaneous
    node_id           => "00010", -- don't change, because of address range in simulation
    -- DAB interface
    dab_clk           => dab_clk_i,
    dab_rst           => dab_rst_i,
    dab_addr          => dab_addr_i,
    dab_sel           => dab_sel_i,
    dab_wvalid        => dab_wvalid_i,
    dab_rvalid        => dab_rvalid_i,
    dab_wdata         => dab_wdata_i,
    dab_rdata         => dab_rdata_i,
    -- Receive data from backplane to FIFO
    b2f_tdata         => b2f_tdata_i,
    b2f_tstream_id    => b2f_tstream_id_i,
    b2f_tvalid        => b2f_tvalid_i,
    b2f_tready        => b2f_tready_i, 
    -- Send data from FIFO to backplane
    f2b_tdata         => f2b_tdata_i,
    f2b_tstream_id    => f2b_tstream_id_i,
    f2b_tnode_id      => f2b_tnode_id_i,
    f2b_tvalid        => f2b_tvalid_i,
    f2b_tready        => f2b_tready_i,
    -- Serial fifo status info
    fifo_status_sync  => '0',
    fifo_status_flag  => open,     
    -- Clock signals  
    user_clocks       => user_clocks_i
  );
  
  stim_reader : tb_stim_reader
  generic map(
      STIM_FILE_NAME  =>      "../../stimuli/control_stimuli.txt"
  )
  port map(
      cmd_out         =>  cmd_i,
      cmd_accept_in   =>  cmd_accept_i,
      eof             =>  eof_i
  );  
  
  dab_clk <= not dab_clk after 5 ns; -- 100MHz clock

  dab_rst <= '0' after 50 ns; -- Synchronous, active high reset

  dab_clk_i <= dab_clk;
  dab_rst_i <= dab_rst;
    
  control : process(dab_clk)
    variable stream_no                  : integer := 0;
    
    variable v_value_int                : integer;   
    variable v_value_slv                : std_logic_vector(31 downto 0);
    variable v_result                   : boolean;
    variable v_result_len               : integer;
    variable v_string                   : string(1 to CMD_WORD_SIZE); 
  begin
    if(rising_edge(dab_clk)) then
      if(dab_rst = '1') then
        dab_addr_i        <= (others => '0');
        dab_sel_i         <= '0';
        dab_wvalid_i      <= '0';
        dab_rvalid_i      <= '0';
        dab_wdata_i       <= (others => '0');
        
        dab_delay_cnt     <= "11";

        sm_control        <= IDLE;   
        
        data_in_streams   <= (others => ((others => NUL), 0, '0'));  
        data_out_streams  <= (others => ((others => NUL), 0, '0'));           
      else
      
        case(sm_control) is
        
          when IDLE =>  
          
            dab_sel_i       <= '0';
            dab_wvalid_i    <= '0';
            dab_rvalid_i    <= '0';
        
            if(cmd_i.valid = true) then
              sm_control      <= PARSE_CMD;
            else
              cmd_accept_i    <= '0'; --release command
            end if;
                
          when PARSE_CMD =>
            if (cmd_i.word(0)(1 to 12) = "write_config") then  -- dab write_control (hdl_node) command
                                                                     
              --read arguments          
              for i in 1 to (cmd_i.cnt-1) loop
                v_string(1 to cmd_i.size(i))  := cmd_i.word(i)(1 to cmd_i.size(i));
                proc_get_value (
                  str           => v_string(1 to cmd_i.size(i)),
                  slv           => v_value_slv,
                  result        => v_result,
                  len           => v_result_len
                );
                if not(v_result) then
                  report "ERROR: Unknown value!";
                  report "Found: " & cmd_i.word(i)(1 to cmd_i.size(i));
                  report "Expected: hexadecimal or binary value e.g. 0xABCD or 0b1011010000100100 or X1011010000HLL100"
                  severity failure;
                end if;
                
                if (i=1) then                                     --address
                    dab_addr_i    <= "00000" & ( X"1000" + v_value_slv(15 downto 0));
                elsif (i=2) then                                  --data
                    dab_wdata_i   <= v_value_slv(31 downto 0);                    
                end if;  
              end loop;  
              
              dab_sel_i       <= '1';
              
              dab_delay_cnt   <= "11";
              sm_control      <= DAB_DELAY_WRITE;  
              
            elsif (cmd_i.word(0)(1 to 10) = "write_data") then  -- dab write_data (user_logic) command
                                                                       
              --read arguments          
              for i in 1 to (cmd_i.cnt-1) loop
                v_string(1 to cmd_i.size(i))  := cmd_i.word(i)(1 to cmd_i.size(i));
                proc_get_value (
                  str           => v_string(1 to cmd_i.size(i)),
                  slv           => v_value_slv,
                  result        => v_result,
                  len           => v_result_len
                );
                if not(v_result) then
                  report "ERROR: Unknown value!";
                  report "Found: " & cmd_i.word(i)(1 to cmd_i.size(i));
                  report "Expected: hexadecimal or binary value e.g. 0xABCD or 0b1011010000100100 or X1011010000HLL100"
                  severity failure;
                end if;
                
                if (i=1) then                                     --address
                    dab_addr_i     <= "00010" & v_value_slv(15 downto 0);
                elsif (i=2) then                                  --data
                    dab_wdata_i     <= v_value_slv(31 downto 0);                    
                end if;  
              end loop;  
              
              dab_sel_i       <= '1';
              
              dab_delay_cnt   <= "11";
              sm_control      <= DAB_DELAY_WRITE;   
                
            elsif (cmd_i.word(0)(1 to 11) = "read_config") then  -- dab read_control (hdl_node) command
                                                                     
              --read arguments          
              for i in 1 to (cmd_i.cnt-1) loop
                v_string(1 to cmd_i.size(i))  := cmd_i.word(i)(1 to cmd_i.size(i));
                proc_get_value (
                  str           => v_string(1 to cmd_i.size(i)),
                  slv           => v_value_slv,
                  result        => v_result,
                  len           => v_result_len
                );
                if not(v_result) then
                  report "ERROR: Unknown value!";
                  report "Found: " & cmd_i.word(i)(1 to cmd_i.size(i));
                  report "Expected: hexadecimal or binary value e.g. 0xABCD or 0b1011010000100100 or X1011010000HLL100"
                  severity failure;
                end if;
                
                if (i=1) then                                     --address
                    dab_addr_i     <= "00000" & ( X"1000" + v_value_slv(15 downto 0));                  
                end if;  
              end loop;  
              
              dab_sel_i       <= '1';
              
              dab_delay_cnt   <= "11";
              sm_control      <= DAB_DELAY_READ;  
              
            elsif (cmd_i.word(0)(1 to 9) = "read_data") then  -- dab read_data (user_logic) command
                                                                       
              --read arguments          
              for i in 1 to (cmd_i.cnt-1) loop
                v_string(1 to cmd_i.size(i)) := cmd_i.word(i)(1 to cmd_i.size(i));
                proc_get_value (
                  str           => v_string(1 to cmd_i.size(i)),
                  slv           => v_value_slv,
                  result        => v_result,
                  len           => v_result_len
                );
                if not(v_result) then
                  report "ERROR: Unknown value!";
                  report "Found: " & cmd_i.word(i)(1 to cmd_i.size(i));
                  report "Expected: hexadecimal or binary value e.g. 0xABCD or 0b1011010000100100 or X1011010000HLL100"
                  severity failure;
                end if;
                
                if (i=1) then                                     --address
                    dab_addr_i     <= "00010" & v_value_slv(15 downto 0);                  
                end if;  
              end loop;  
              
              dab_sel_i       <= '1';
              
              dab_delay_cnt   <= "11";
              sm_control      <= DAB_DELAY_READ;                              
                
            elsif (cmd_i.word(0)(1 to 9) = "stream_in") then  -- stream settings
            
              --read arguments          
              for i in 1 to (cmd_i.cnt-1) loop      
                v_string  := (others => NUL);     
                v_string(1 to cmd_i.size(i)) := cmd_i.word(i)(1 to cmd_i.size(i));
                
                if(i /= 3) then
                  proc_str_to_int (
                    str           => v_string(1 to cmd_i.size(i)),
                    int           => v_value_int,
                    result        => v_result
                  );  
                  if not(v_result) then
                    report "ERROR: Unknown value!";
                    report "Found: " & cmd_i.word(i)(1 to cmd_i.size(i));
                    report "Expected: hexadecimal or binary value e.g. 0xABCD or 0b1011010000100100 or X1011010000HLL100"
                    severity failure;
                  end if;                                    
                end if;                              

                if (i=1) then                                     --stream_no
                  stream_no                                   := v_value_int;
                  if(stream_no >= c_input_streams) then
                    report "ERROR: stream_in command: Stream nr " & integer'image(stream_no) & " invalid, valid stream nrs are 0 to " & integer'image(c_input_streams - 1)
                    severity failure;  
                  else
                    data_in_streams(stream_no).enable          <= '1';  
                  end if; 
                elsif (i=2) then                                  --length
                  data_in_streams(stream_no).length           <= v_value_int;          
                elsif (i=3) then                                  --filename
                  if(v_string(1) /= NUL) then
                    data_in_streams(stream_no).filename         <= v_string;  
                  else
                    report "ERROR: stream_in command: Filename cannot be empty"
                    severity failure;   
                  end if;                                                                          
                end if;  
              end loop;  
              
              sm_control  <= IDLE;
                
            elsif (cmd_i.word(0)(1 to 10) = "stream_out") then  -- stream settings
            
              --read arguments          
              for i in 1 to (cmd_i.cnt-1) loop
                v_string  := (others => NUL); 
                v_string(1 to cmd_i.size(i)) := cmd_i.word(i)(1 to cmd_i.size(i));
                
                if(i /= 3) then
                  proc_str_to_int (
                    str           => v_string(1 to cmd_i.size(i)),
                    int           => v_value_int,
                    result        => v_result
                  );  
                  if not(v_result) then
                    report "ERROR: Unknown value!";
                    report "Found: " & cmd_i.word(i)(1 to cmd_i.size(i));
                    report "Expected: hexadecimal or binary value e.g. 0xABCD or 0b1011010000100100 or X1011010000HLL100"
                    severity failure;
                  end if;                                    
                end if;                              

                if (i=1) then                                     --stream_no
                  stream_no                                   := v_value_int;
                  if(stream_no >= c_output_streams) then
                    report "ERROR: stream_out command: Stream nr " & integer'image(stream_no) & " invalid, valid stream nrs are 0 to " & integer'image(c_output_streams - 1)
                    severity failure;  
                  else
                    data_out_streams(stream_no).enable          <= '1';  
                  end if;          
                elsif (i=2) then                                  --length
                  data_out_streams(stream_no).length          <= v_value_int;          
                elsif (i=3) then                                  --filename
                  data_out_streams(stream_no).filename        <= v_string;                                                                                
                end if;  
                
              end loop;  
              
              sm_control  <= IDLE;                            
                
            else
              report "ERROR: Unknown command!";
              report "Found: " & cmd_i.word(0)
              severity failure;
            end if;
            
            cmd_accept_i        <= '1';  -- do accept command
              
          when DAB_DELAY_WRITE =>
            if (dab_delay_cnt /= 0) then
              dab_delay_cnt <= dab_delay_cnt - 1;
            else
              dab_wvalid_i  <= '1';
              sm_control    <= IDLE;  
            end if;

          when DAB_DELAY_READ =>
            if (dab_delay_cnt /= 0) then
              dab_delay_cnt <= dab_delay_cnt - 1;
            else
              dab_rvalid_i  <= '1';
              sm_control    <= IDLE;  
            end if;   
                                           
        end case;             
          
      end if;
    end if;
  end process;
    
  -- Data in streams
  data_streams_in : for i in 0 to c_input_streams - 1 generate

    signal words_send       : integer := 0;
            
    type sm_stream_type is (START_BURST, INTERRUPT_BURST, BURST);
    signal sm_stream        : sm_stream_type := START_BURST;
    
    signal burst_cnt        : integer := 0;
  
  begin  

    stream_x : process(dab_clk)
      file datafile               : text;
      variable v_file_opened      : boolean := false;
      variable v_data_file_status : file_open_status; 
      variable v_data_line        : line; 
      variable v_data_word        : string(1 to 10);

    begin
      if(rising_edge(dab_clk)) then
        if(dab_rst = '1') then
          streams_in_tdata(i)       <= (others => '0');
          streams_in_tstream_id(i)  <= (others => '0');
          streams_in_tvalid(i)      <= '0';
          
          in_streams_finished(i)    <= '0';
          
          sm_stream                 <= START_BURST;
        else
      
          streams_in_tstream_id(i)   <= std_logic_vector(to_unsigned(i,5));
          
          if(data_in_streams(i).enable = '1' and words_send < data_in_streams(i).length) then
              
            case(sm_stream) is
            
              when START_BURST =>
                if(v_file_opened = false) then
                  file_open(v_data_file_status, datafile, (string'("../../data/") & data_in_streams(i).filename), read_mode);
                  if not(v_data_file_status = OPEN_OK) then
                    report "ERROR: Unable to open data file: " & string'(data_in_streams(i).filename)
                    severity failure;
                  else
                    v_file_opened := true;
                  end if; 
                end if;
                
                --read line from data file
                if(not endfile(datafile)) then
                  str_read(datafile, v_data_word);
                  streams_in_tdata(i)     <= hstr_to_slv(v_data_word(3 to 10)); 
                  streams_in_tvalid(i)    <= '1';
                else
                  report "ERROR: End of file!"
                  severity failure;
                end if;
                  
                burst_cnt   <= 0;  
                sm_stream   <= BURST;
               
              when BURST =>
                if(streams_in_tready(i) = '1' and streams_in_tvalid(i) = '1') then
                  words_send  <= words_send + 1;
                  burst_cnt   <= burst_cnt + 1;

                  if( (words_send + 1) < data_in_streams(i).length) then
                    --read line from data file
                    if(not endfile(datafile)) then
                      str_read(datafile, v_data_word);
                      streams_in_tdata(i)     <= hstr_to_slv(v_data_word(3 to 10));
                      
                      if(burst_cnt = 63) then
                        streams_in_tvalid(i)    <= '0';
                        
                        burst_cnt <= 0;
                        sm_stream <= INTERRUPT_BURST;
                      else
                        streams_in_tvalid(i)    <= '1'; 
                      end if;
                    else
                      file_close(datafile);
                      report "ERROR: End of file!"
                      severity failure;
                    end if;
                  else
                    streams_in_tvalid(i)    <= '0';
                    in_streams_finished(i)  <= '1';
                    
                    file_close(datafile);
                  end if;
                end if;
                
              when INTERRUPT_BURST =>
                streams_in_tvalid(i)    <= '1';  
                sm_stream <= BURST;
                
            end case;
          end if;                    
        end if;
      end if;
    end process;
  end generate;
    
  b2f_tdata_i                             <= streams_in_tdata(schedule_in_streams);
  b2f_tstream_id_i                        <= streams_in_tstream_id(schedule_in_streams);
  b2f_tvalid_i                            <= streams_in_tvalid(schedule_in_streams);
  streams_in_tready                       <= (schedule_in_streams => b2f_tready_i, others => '0');
    
  -- Data in streams
  data_streams_out : for i in 0 to c_output_streams - 1 generate
  
    signal words_received       : integer := 0;
            
    type sm_stream_type is (WAITING, BURST, END_BURST);
    signal sm_stream            : sm_stream_type := WAITING;
       
  begin  
  
    stream_x : process(dab_clk)
      file datafile               : text;
      variable v_file_opened      : boolean := false;
      variable v_data_file_status : file_open_status; 
      variable v_data_line        : line; 
      variable v_data_word        : string(1 to 10);
                  
      variable v_expected_data    : std_logic_vector(31 downto 0);
      
    begin
      if(rising_edge(dab_clk)) then
        if(dab_rst = '1') then
          streams_out_tready(i)   <= '0';
            
          out_streams_finished(i) <= '0';
        else
          
          if(data_out_streams(i).enable = '1' and words_received < data_out_streams(i).length) then

            streams_out_tready(i)   <= '1';

            if(data_out_streams(i).filename(1) /= NUL) then 
              if(v_file_opened = false) then
                file_open(v_data_file_status, datafile, (string'("../../data/") & data_out_streams(i).filename), read_mode);
                if not(v_data_file_status = OPEN_OK) then
                  report "ERROR: Unable to open data file: " & string'(data_out_streams(i).filename)
                  severity failure;
                else
                  v_file_opened := true;
                end if; 
              end if;
            end if;
                
            if(f2b_tvalid_i = '1' and streams_out_tready(i) = '1' and conv_integer(f2b_tstream_id_i) = i) then

                words_received <= words_received + 1;
                
                if(data_out_streams(i).filename(1) /= NUL) then
                  --read line from data file
                  if(not endfile(datafile)) then
                    str_read(datafile, v_data_word);
                    v_expected_data   := hstr_to_slv(v_data_word(3 to 10));
                  else
                    report "ERROR: End of file!"
                    severity failure; 
                  end if;
                  
                  assert f2b_tdata_i = v_expected_data
                    report "ERROR: Received data does not match expected data"
                    severity failure;
                end if;
                    
                --read from file and data bus and check (assert)
                if( (words_received + 1) = data_out_streams(i).length) then
                  streams_out_tready(i)   <= '0';  
                  out_streams_finished(i) <= '1';
                  
                  if(data_out_streams(i).filename(1) /= NUL) then
                    file_close(datafile);
                  end if;
                end if;   
            end if;
          end if;                    
        end if;
      end if;
    end process;
      
    streams_out_tready_c(i) <=  '1' when (streams_out_tready(i) = '1' and conv_integer(f2b_tstream_id_i) = i) else '0';   
    
  end generate;    
   
  f2b_tready_i <=  '1' when (streams_out_tready_c /= std_logic_vector(to_unsigned(0,4))) else '0';
   
  schedule : process(dab_clk)
    variable schedule_in_next   : integer := 0;
  begin
    if(rising_edge(dab_clk)) then
      if(dab_rst_i = '1') then
        schedule_in_streams     <= 0;
      else 
        if(streams_in_tvalid(schedule_in_streams) = '0') then
          --Schedule, next lane
          schedule_in_next := schedule_in_streams;
          for s in 0 to c_input_streams - 1 loop
            if(schedule_in_next = c_input_streams - 1) then
              schedule_in_next := 0;
            else
              schedule_in_next := schedule_in_next + 1;
            end if;
            if(streams_in_tvalid(schedule_in_next) = '1') then
              exit;
            end if;
          end loop;
          schedule_in_streams <= schedule_in_next;
          --Schedule, next lane
        end if;          
      end if;
    end if;      
  end process;
    
  user_clock_0 : process
  begin
    user_clocks_i(0) <= '0';
    wait for 20 ns;
    user_clocks_i(0) <= '1';
    wait for 20 ns;
  end process;
  
  user_clock_1 : process
  begin
    user_clocks_i(1) <= '0';
    wait for 15 ns;
    user_clocks_i(1) <= '1';
    wait for 15 ns;
  end process;
  
  user_clock_2 : process
  begin
    user_clocks_i(2) <= '0';
    wait for 10 ns;
    user_clocks_i(2) <= '1';
    wait for 10 ns;
  end process;
  
  user_clock_3 : process
  begin
    user_clocks_i(3) <= '0';
    wait for 5 ns;
    user_clocks_i(3) <= '1';
    wait for 5 ns;
  end process;  
  
  enabled_in: for i in 0 to c_input_streams - 1 generate
  begin
    in_streams_enabled(i)   <= data_in_streams(i).enable;
  end generate enabled_in;
  
  enabled_out: for i in 0 to c_output_streams - 1 generate
  begin
    out_streams_enabled(i)  <= data_out_streams(i).enable;
  end generate enabled_out;  
  
  p_finished: process(dab_clk)
  begin
    if (rising_edge(dab_clk)) then
      if dab_rst_i = '0' then
        if(eof_i = '1' and (out_streams_finished = out_streams_enabled and in_streams_finished = in_streams_enabled) ) then
          report "*** End of simulation ***";
          finish(0);
        end if;
      end if;  
    end if;     
  end process p_finished;       
    
end rtl;
