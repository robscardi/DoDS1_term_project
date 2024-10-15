-- *****************************************************************************
-- Name:     math_utilities.vhd   
-- Created:  10.03.16 @ NTNU   
-- Author:   Jonas Eggen
-- Purpose:  Utility package with useful math functions.
--            - log2c returns ceil(log2(x))
-- *****************************************************************************

library ieee;
use ieee.math_real.all;

package math_utilities is
  function log2c(constant value : in positive) return natural; -- Try using natural here..
end math_utilities;

package body math_utilities is
  function log2c(constant value : in positive) return natural is
  begin
      return integer(ceil(log2(real(value))));
  end function;
end package body math_utilities;