-- 	File: dyplo_hdl_node_user_params.vhd
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

package hdl_node_user_params is

  constant c_vendor_id                  : integer range 0 to 255 := 1;
  constant c_product_id                 : integer range 0 to 255 := 4;
  constant c_version_id                 : integer range 0 to 255 := 1;
  constant c_revision_id                : integer range 0 to 255 := 1;
  
  constant c_input_streams              : integer range 0 to 4 := 2;
  constant c_hdl_in_fifo_depth          : integer range 7 to 12 := 8;  -- specify power of 2. FIFO size = 2^x. 7 = 128, 12 = 4096 
  constant c_hdl_in_fifo_type           : string := "DISTRIBUTED";
  
  constant c_output_streams             : integer range 0 to 4 := 1; 
  
end hdl_node_user_params;
