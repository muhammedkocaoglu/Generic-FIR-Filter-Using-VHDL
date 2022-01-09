----------------------------------------------------------------------------------
-- Company: 
-- Engineer: MUHAMMED KOCAOGGLU
-- 
-- Create Date: 01/08/2022 04:37:06 PM
-- Design Name: 
-- Module Name: Generic_FIR_Filter - Behavioral
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
USE work.ram_pkg.ALL;
USE work.my_data_types.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY Generic_FIR_Filter IS
    GENERIC (
        FILEADDR   : STRING  := "C:\Users\Muhammed\OneDrive\FPGA_Projects\VivadoProjects\v2_Generic_FIR_Filter\v2_Generic_FIR_Filter.srcs\sources_1\new\FIR_Coeffs.txt";
        FIR_tab    : INTEGER := 63;
        ADDR_WIDTH : INTEGER := (clogb2(FIR_tab)) + 1
    );
    PORT (
        CLK        : IN STD_LOGIC;
        FIR_enable : IN STD_LOGIC;
        FIR_Din    : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        FIR_Dout   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        FIR_ready  : OUT STD_LOGIC
    );
END Generic_FIR_Filter;

ARCHITECTURE Behavioral OF Generic_FIR_Filter IS

    COMPONENT InitBramFromFile
        GENERIC (
            FILEADDR   : STRING  := "xxxxxx.mem";
            DATA_WIDTH : INTEGER := 24;
            ADDR_WIDTH : INTEGER := 8 -- DATA_DEPTH = 2 ** ADDR_WIDTH - 1 -- IN that CASE 255
        );
        PORT (
            clk  : IN STD_LOGIC;
            we   : IN STD_LOGIC;
            addr : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
            di   : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
            dout : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL Coeff_Addr : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Coeff_Data : STD_LOGIC_VECTOR(31 DOWNTO 0)             := (OTHERS => '0');

    COMPONENT floating_point_3
        PORT (
            aclk                 : IN STD_LOGIC;
            s_axis_a_tvalid      : IN STD_LOGIC;
            s_axis_a_tdata       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_b_tvalid      : IN STD_LOGIC;
            s_axis_b_tdata       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_c_tvalid      : IN STD_LOGIC;
            s_axis_c_tdata       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_result_tvalid : OUT STD_LOGIC;
            m_axis_result_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    SIGNAL s_accumulate_a_tvalid      : STD_LOGIC                     := '0';
    SIGNAL s_accumulate_a_tready      : STD_LOGIC                     := '0';
    SIGNAL s_accumulate_a_tdata       : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_accumulate_b_tvalid      : STD_LOGIC                     := '0';
    SIGNAL s_accumulate_b_tready      : STD_LOGIC                     := '0';
    SIGNAL s_accumulate_b_tdata       : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_accumulate_c_tvalid      : STD_LOGIC                     := '0';
    SIGNAL s_accumulate_c_tready      : STD_LOGIC                     := '0';
    SIGNAL s_accumulate_c_tdata       : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL m_accumulate_result_tvalid : STD_LOGIC                     := '0';
    SIGNAL m_accumulate_result_tready : STD_LOGIC                     := '0';
    SIGNAL m_accumulate_result_tdata  : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    SIGNAL sum_prev : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    TYPE states IS (
        S_IDLE,
        S_DATA,
        S_ACCUMULATE
    );
    SIGNAL state : states := S_IDLE;

    SIGNAL cntr : INTEGER RANGE 0 TO FIR_tab + 2 := 0;

    SIGNAL FIR_Data_Buffer : array2D32(0 TO FIR_tab) := (OTHERS => (OTHERS => '0'));

BEGIN

    P_MAIN : PROCESS (CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            s_accumulate_a_tvalid <= '0';
            s_accumulate_b_tvalid <= '0';
            s_accumulate_c_tvalid <= '0';
            FIR_ready             <= '0';
            CASE state IS

                WHEN S_IDLE =>
                    IF FIR_enable = '1' THEN
                        FIR_Data_Buffer <= FIR_Din & FIR_Data_Buffer(0 TO FIR_tab - 1);
                        state           <= S_DATA;
                        Coeff_Addr      <= (OTHERS => '0');
                        cntr            <= 0;
                        sum_prev        <= (OTHERS => '0');
                    END IF;

                WHEN S_DATA =>
                    s_accumulate_a_tvalid <= '1';
                    s_accumulate_b_tvalid <= '1';
                    s_accumulate_c_tvalid <= '1';
                    s_accumulate_a_tdata  <= FIR_Data_Buffer(cntr);
                    s_accumulate_c_tdata  <= sum_prev;
                    state                 <= S_ACCUMULATE;

                WHEN S_ACCUMULATE =>
                    IF m_accumulate_result_tvalid = '1' THEN
                        IF cntr = FIR_tab THEN
                            state      <= S_IDLE;
                            cntr       <= 0;
                            Coeff_Addr <= (OTHERS => '0');
                            FIR_ready  <= '1';
                            FIR_Dout   <= m_accumulate_result_tdata;
                        ELSE
                            state      <= S_DATA;
                            Coeff_Addr <= Coeff_Addr + 1;
                            cntr       <= cntr + 1;
                            sum_prev   <= m_accumulate_result_tdata;
                        END IF;
                    END IF;

            END CASE;
        END IF;
    END PROCESS;

    your_instance_name : floating_point_3
    PORT MAP(
        aclk                 => CLK,
        s_axis_a_tvalid      => s_accumulate_a_tvalid,
        s_axis_a_tdata       => s_accumulate_a_tdata,
        s_axis_b_tvalid      => s_accumulate_b_tvalid,
        s_axis_b_tdata       => Coeff_Data,
        s_axis_c_tvalid      => s_accumulate_c_tvalid,
        s_axis_c_tdata       => s_accumulate_c_tdata,
        m_axis_result_tvalid => m_accumulate_result_tvalid,
        m_axis_result_tdata  => m_accumulate_result_tdata
    );

    InitBramFromFile_Inst : InitBramFromFile
    GENERIC MAP(
        FILEADDR   => FILEADDR,
        DATA_WIDTH => 32,        -- single precision
        ADDR_WIDTH => ADDR_WIDTH -- DATA_DEPTH = 2 ** ADDR_WIDTH - 1 -- IN that CASE 255
    )
    PORT MAP(
        clk  => CLK,
        we   => '0',
        addr => Coeff_Addr,
        di => (OTHERS => '0'),
        dout => Coeff_Data
    );
END Behavioral;
