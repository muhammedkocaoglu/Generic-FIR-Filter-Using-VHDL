----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/08/2022 04:29:51 PM
-- Design Name: 
-- Module Name: tb_Generic_FIR_Filter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE std.textio.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY tb_Generic_FIR_Filter IS
    GENERIC (
        FIR_tab : INTEGER := 63
    );
END tb_Generic_FIR_Filter;

ARCHITECTURE Behavioral OF tb_Generic_FIR_Filter IS

    COMPONENT Generic_FIR_Filter IS
        GENERIC (
            FIR_tab : INTEGER := 20
        );
        PORT (
            CLK        : IN STD_LOGIC;
            FIR_enable : IN STD_LOGIC;
            FIR_Din    : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            FIR_Dout   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            FIR_ready  : OUT STD_LOGIC
        );
    END COMPONENT;
    SIGNAL CLK              : STD_LOGIC                     := '1';
    SIGNAL FIR_enable       : STD_LOGIC                     := '0';
    SIGNAL FIR_Din          : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL FIR_Dout         : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL FIR_ready        : STD_LOGIC                     := '0';
    CONSTANT C_FILE_NAME_RD : STRING                        := "C:\Users\Muhammed\OneDrive\FPGA_Projects\VivadoProjects\v2_Generic_FIR_Filter\v2_Generic_FIR_Filter.srcs\sources_1\new\FIR_Raw.txt";

BEGIN
    CLK <= NOT CLK AFTER 5 ns;

    dut : PROCESS
        VARIABLE VEC_LINE_RD : line;
        VARIABLE VEC_VAR_RD  : STD_LOGIC_VECTOR (31 DOWNTO 0);
        FILE VEC_FILE_RD     : text OPEN read_mode IS C_FILE_NAME_RD;
    BEGIN
        WAIT FOR 50 ns;
        WHILE NOT endfile(VEC_FILE_RD) LOOP
            readline (VEC_FILE_RD, VEC_LINE_RD);
            hread (VEC_LINE_RD, VEC_VAR_RD);
            WAIT UNTIL falling_edge(clk);
            FIR_Din    <= VEC_VAR_RD;
            FIR_enable <= '1';
            WAIT UNTIL falling_edge(CLK);
            FIR_enable <= '0';
            WAIT UNTIL rising_edge(FIR_ready);
            WAIT UNTIL falling_edge(clk);
        END LOOP;

        WAIT FOR 500 ns;
        std.env.finish;
    END PROCESS;
    Generic_FIR_Filter_Inst : Generic_FIR_Filter
    GENERIC MAP(
        FIR_tab => FIR_tab
    )
    PORT MAP(
        CLK        => CLK,
        FIR_enable => FIR_enable,
        FIR_Din    => FIR_Din,
        FIR_Dout   => FIR_Dout,
        FIR_ready  => FIR_ready
    );
END Behavioral;