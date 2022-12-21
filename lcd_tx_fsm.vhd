library ieee;
use IEEE.STD_LOGIC_1164.ALL;

entity lcd_tx_fsm is
    port(
        clk : in std_logic;
        rst : in std_logic;
        byte_in : in std_logic_vector(0 to 7);  -- Data to send
        stb : in std_logic;                     -- Strobe to initiate the transfer
        rs : in std_logic;                      -- Indicate command or data
        rdy : out std_logic;                    -- Ready for initiate a transfer
        lcd_rs : out std_logic;                 -- RS signal of the LCD
        lcd_en : out std_logic;                 -- Enable pulse
        lcd_rw : out std_logic;                 -- W/R signal of the LCD
        lcd_data: out std_logic_vector(0 to 7)  -- Data signal of the LCD
    );
end lcd_tx_fsm;

architecture behavorial of lcd_tx_fsm is

type lcd_tx_state is (IDLE, INIT_TX, EN_TX, WAIT_230N, FINISH_TX, WAIT_40U);

signal lcd_tx_current_state : lcd_tx_state;
signal lcd_tx_next_state : lcd_tx_state;
signal count_reg, count_next : integer;
signal data_reg, data_next : std_logic_vector(0 to 7);

begin
    -- Transition logic
    process(clk, rst)
    begin
        if rst = '1' then
            lcd_tx_current_state <= IDLE;
            count_reg <= 0;
        elsif rising_edge(clk) then
            lcd_tx_current_state <= lcd_tx_next_state;
            count_reg <= count_next;
            data_reg <= data_next;
        end if;
    end process;

    -- Next state logic
    process(lcd_tx_current_state, stb, rs, count_reg, byte_in)
    begin
    lcd_tx_next_state <= lcd_tx_current_state;
    count_next <= count_reg;
        case lcd_tx_current_state is
            when IDLE =>
                if stb = '1' then
                    lcd_tx_next_state <= INIT_TX;
                    data_next <= byte_in;
                end if;
            
            when INIT_TX =>
                lcd_tx_next_state <= EN_TX;

            when EN_TX =>
                lcd_tx_next_state <= WAIT_230N;

            when WAIT_230N =>
                if count_reg = 12 then
                    count_next <= 0;
                    lcd_tx_next_state <= FINISH_TX;
                else
                    count_next <= count_reg + 1;
                end if;

            when FINISH_TX =>
                lcd_tx_next_state <= WAIT_40U;

            when WAIT_40U =>
                if count_reg = 2000 then
                    count_next <= 0;
                    lcd_tx_next_state <= IDLE;
                else
                    count_next <= count_reg + 1;
                end if;
        end case;
    end process;

    lcd_en <= '1' when lcd_tx_current_state = WAIT_230N else '0';
    lcd_data <= data_reg;
    lcd_rs <= rs;
    lcd_rw <= '0';
    rdy <= '1' when lcd_tx_current_state = IDLE else '0';

end architecture;