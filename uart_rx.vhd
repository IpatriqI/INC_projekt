-- uart_rx.vhd: UART controller - receiving (RX) side
-- Author(s): Patrik Dekýš (xdekysp00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



-- Entity declaration (DO NOT ALTER THIS PART!)
entity UART_RX is
    port(
        CLK      : in std_logic;
        RST      : in std_logic;
        DIN      : in std_logic;
        DOUT     : out std_logic_vector(7 downto 0);
        DOUT_VLD : out std_logic
    );
end entity;



-- Architecture implementation (INSERT YOUR IMPLEMENTATION HERE)
architecture behavioral of UART_RX is
    signal shift_reg      : std_logic_vector(7 downto 0) := "00000000";
    signal start_bit_cnt  : std_logic_vector(3 downto 0) := "0000";
    signal word_cnt       : std_logic_vector(3 downto 0) := "0000";
    signal word_end_fsm   : std_logic_vector(3 downto 0) := "0000";
    signal word_start_fsm : std_logic_vector(3 downto 0) := "0000";
    signal midbit_cnt     : std_logic_vector(3 downto 0) := "0000";
    signal cnt_rst_fsm    : std_logic := '0';
    signal start_bit_fsm  : std_logic := '0';
    signal write_en_fsm   : std_logic := '0';
    signal vld_fsm        : std_logic := '0';
    signal midbit_of_cnt  : std_logic := '0'; --Overflow Midbit counter
    signal data_rst       : std_logic := '0';

begin

    -- Instance of RX FSM
    fsm: entity work.UART_RX_FSM
    port map (
        CLK        => CLK,
        RST        => RST, 
        DIN        => DIN, 
        WORD_START => word_start_fsm,
        WORD_END   => word_end_fsm,  
        CNT_RST    => cnt_rst_fsm, 
        START_BIT  => start_bit_fsm, 
        WRITE_EN   => write_en_fsm, 
        VLD        => vld_fsm
        );

    -- Shift register with contoled enable by FSM
    shift_register: process(CLK)
    begin
        if rising_edge(CLK) then
            if write_en_fsm = '1' and midbit_of_cnt = '1' then
                shift_reg <= DIN & shift_reg(7 downto 1);
                end if;
            end if;
    end process;


    -- Number of words in shift register
    word_counter: process(CLK) begin
        if rising_edge(CLK) then
            if cnt_rst_fsm = '1' then
                word_end_fsm <= "0000";
            else
                if write_en_fsm = '1' and midbit_of_cnt = '1' then
                    word_end_fsm <= word_end_fsm + 1;
                end if;
                if write_en_fsm = '0' then
                    word_end_fsm <= "0000";
                end if;
            end if;
        end if;
    end process; 
    

    -- 8 cycles of CLK
    start_bit_counter : process(CLK) begin
        if rising_edge(CLK) then 
            if cnt_rst_fsm = '1' then 
               word_start_fsm <= "0000";
            end if;
            if start_bit_fsm = '1' then
                word_start_fsm <= word_start_fsm + 1;
            else
                word_start_fsm <= "0000";
            end if;
        end if;
    end process;
   

    -- 16 cycles of CLK
    midbit_counter: process(CLK) begin
        if rising_edge(CLK) then 
            if cnt_rst_fsm = '1' then 
                midbit_cnt <= "0000";
            end if;
            if write_en_fsm = '1' then 
                midbit_cnt <= midbit_cnt + 1;
            else
                midbit_cnt <= "0000";
            end if;
            if midbit_cnt = "1111" then
                midbit_of_cnt <= '1';
            else
                midbit_of_cnt <= '0';
            end if;
        end if;
    end process;
 

    -- If whole word is in register, set vld_fsm to '1'
    DOUT <= shift_reg when vld_fsm = '1' else (others => '0');
    DOUT_VLD <= vld_fsm;

end architecture;
