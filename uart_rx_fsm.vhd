-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Patrik Dekýš (xdekysp00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity UART_RX_FSM is
    port(
        CLK        : in    std_logic;
        RST        : in    std_logic;
        DIN        : in    std_logic;
        WORD_END   : in    std_logic_vector(3 downto 0);
        WORD_START : in    std_logic_vector(3 downto 0);
        CNT_RST    : out   std_logic;
        START_BIT  : out   std_logic;
        WRITE_EN   : out   std_logic;
        VLD        : out   std_logic
    );
end entity;



architecture behavioral of UART_RX_FSM is

    type t_state is (IDLE, START, DATA, STOP, VALID);
    signal next_state : t_state;
    signal state      : t_state;

begin

    -- Present state register
    state_register: process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                state <= IDLE;
                else
                state <= next_state;
            end if;
        end if;
    end process;
    

    -- Next state logic 
    next_state_logic: process (state, CLK, DIN, WORD_START, WORD_END) 
    begin
        next_state <= state;            
        case state is
            when IDLE => 
            if DIN = '0' then
                next_state <= START;
            end if;
            when START =>
                if WORD_START = "0111" then
                    next_state <= DATA;
                end if;
            when DATA =>
                if WORD_END = "1000" then
                    next_state <= STOP;
                    end if;
            when STOP =>
                if WORD_START = "1111" and DIN = '1' then
                    next_state <= VALID;
                end if;
            when VALID =>
                next_state <= IDLE; 
            end case;  
    end process;
    
    -- Output of fsm 
    output_logic: process (state)
    begin
        -- Default values
        CNT_RST <= '0';
        START_BIT <= '0';
        WRITE_EN <= '0';
        VLD <= '0';
        -----------------
        case state is
            when IDLE =>
                CNT_RST <= '1';
                CNT_RST <= '0';
                START_BIT <= '0';
                WRITE_EN <= '0';
                VLD <= '0';
            when START =>
                CNT_RST <= '0';
                START_BIT <= '1';
                WRITE_EN <= '0';
                VLD <= '0';
            when DATA =>
                CNT_RST <= '1';
                CNT_RST <= '0';
                START_BIT <= '0';
                WRITE_EN <= '1';
                VLD <= '0';
            when STOP =>
                CNT_RST <= '1';
                CNT_RST <= '0';
                START_BIT <= '1';
                WRITE_EN <= '0';
                VLD <= '0';
            when VALID =>
                CNT_RST <= '1';
                CNT_RST <= '0';
                START_BIT <= '0';
                WRITE_EN <= '0';
                VLD <= '1';
        end case;
    end process;

end architecture;
