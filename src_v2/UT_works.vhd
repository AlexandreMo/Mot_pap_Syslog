-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : UT.vhd
--
-- Description  : Unite de traitement des trois moteurs pas-a-pas
--
-- Utilise dans : Labo moteur pas-a-pas (MSS cplx)
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

--| Entity |-------------------------------------------------------------------
entity UT is
    port(
        clk_i              : in  std_logic;
        rst_i              : in  std_logic;

        cap_l_i            : in  std_logic;
        cap_m_i            : in  std_logic;
        cap_r_i            : in  std_logic;

        ld_nb_tour_i       : in  std_logic;
        nb_tour_i          : in  std_logic_vector(2 downto 0);

        en_mot_l_i         : in  std_logic;
        en_mot_m_i         : in  std_logic;
        en_mot_r_i         : in  std_logic;
        dir_mot_l_i        : in  std_logic;
        dir_mot_m_i        : in  std_logic;
        dir_mot_r_i        : in  std_logic;

        cnt_enc_rst_i      : in  std_logic;
        cnt_tour_rst_i     : in  std_logic;
        speed_up_i         : in  std_logic;
        speed_down_i       : in  std_logic;
        speed_rst_i        : in  std_logic;
        sel_mot_i          : in  std_logic_vector(1 downto 0);

        enc_det_l_o        : out std_logic;
        enc_det_m_o        : out std_logic;
        enc_det_r_o        : out std_logic;
        tour_done_o        : out std_logic;
        last_tour_o        : out std_logic;
        mot_free_l_o       : out std_logic;
        mot_free_m_o       : out std_logic;
        mot_free_r_o       : out std_logic;
        all_free_o         : out std_logic;
        err_config_o       : out std_logic;
        sel_speed_o        : out std_logic_vector(1 downto 0);

        en_l_o             : out std_logic;
        en_m_o             : out std_logic;
        en_r_o             : out std_logic;
        dir_l_o            : out std_logic;
        dir_m_o            : out std_logic;
        dir_r_o            : out std_logic
    );
end UT;

--| Architecture |-------------------------------------------------------------
architecture behave of UT is

    constant NOTCHES_PER_TURN : unsigned(2 downto 0) :=
        to_unsigned(5, 3);
    constant SPEED_MIN : unsigned(1 downto 0) := "00";
    constant SPEED_MAX : unsigned(1 downto 0) := "11";

    signal target_turns_s : unsigned(2 downto 0);
    signal notch_count_s  : unsigned(2 downto 0);
    signal turn_count_s   : unsigned(2 downto 0);
    signal speed_s        : unsigned(1 downto 0);

    signal previous_cap_l_s : std_logic;
    signal previous_cap_m_s : std_logic;
    signal previous_cap_r_s : std_logic;

    signal notch_l_s        : std_logic;
    signal notch_m_s        : std_logic;
    signal notch_r_s        : std_logic;
    signal selected_notch_s : std_logic;

begin

    -- A sensor at zero means that the corresponding disk notch is aligned.
    mot_free_l_o  <= not cap_l_i;
    mot_free_m_o  <= not cap_m_i;
    mot_free_r_o  <= not cap_r_i;
    all_free_o    <= not (cap_l_i or cap_m_i or cap_r_i);
    err_config_o  <= cap_m_i and (cap_l_i or cap_r_i);

    -- Store the previous sensor values for falling-edge detection.
    sensor_history : process(clk_i, rst_i) is
    begin
        if rst_i = '1' then
            previous_cap_l_s <= '0';
            previous_cap_m_s <= '0';
            previous_cap_r_s <= '0';
        elsif rising_edge(clk_i) then
            previous_cap_l_s <= cap_l_i;
            previous_cap_m_s <= cap_m_i;
            previous_cap_r_s <= cap_r_i;
        end if;
    end process sensor_history;

    notch_l_s <= previous_cap_l_s and not cap_l_i;
    notch_m_s <= previous_cap_m_s and not cap_m_i;
    notch_r_s <= previous_cap_r_s and not cap_r_i;

    enc_det_l_o <= notch_l_s;
    enc_det_m_o <= notch_m_s;
    enc_det_r_o <= notch_r_s;

    with sel_mot_i select selected_notch_s <=
        notch_m_s when "00",
        notch_l_s when "01",
        notch_r_s when "10",
        '0'       when others;

    -- Capture the requested number of turns at automatic-mode start.
    target_register : process(clk_i, rst_i) is
    begin
        if rst_i = '1' then
            target_turns_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if ld_nb_tour_i = '1' then
                target_turns_s <= unsigned(nb_tour_i);
            end if;
        end if;
    end process target_register;

    -- Five detected notches form one complete turn.
    position_counters : process(clk_i, rst_i) is
    begin
        if rst_i = '1' then
            notch_count_s <= (others => '0');
            turn_count_s  <= (others => '0');
        elsif rising_edge(clk_i) then
            if cnt_enc_rst_i = '1' then
                notch_count_s <= (others => '0');
            elsif selected_notch_s = '1' then
                if notch_count_s = NOTCHES_PER_TURN - 1 then
                    notch_count_s <= (others => '0');
                else
                    notch_count_s <= notch_count_s + 1;
                end if;
            end if;

            if cnt_tour_rst_i = '1' then
                turn_count_s <= (others => '0');
            elsif selected_notch_s = '1' and
                  notch_count_s = NOTCHES_PER_TURN - 1 then
                if turn_count_s /= to_unsigned(7, turn_count_s'length) then
                    turn_count_s <= turn_count_s + 1;
                end if;
            end if;
        end if;
    end process position_counters;

    tour_done_o <= '1' when turn_count_s >= target_turns_s else
                   '0';

    last_tour_o <= '1'
        when target_turns_s /= 0 and
             turn_count_s = target_turns_s - 1
        else '0';

    -- Speed changes are saturated at the slowest and fastest selections.
    speed_register : process(clk_i, rst_i) is
    begin
        if rst_i = '1' then
            speed_s <= SPEED_MIN;
        elsif rising_edge(clk_i) then
            if speed_rst_i = '1' then
                speed_s <= SPEED_MIN;
            elsif speed_up_i = '1' and speed_s /= SPEED_MAX then
                speed_s <= speed_s + 1;
            elsif speed_down_i = '1' and speed_s /= SPEED_MIN then
                speed_s <= speed_s - 1;
            end if;
        end if;
    end process speed_register;

    sel_speed_o <= std_logic_vector(speed_s);

    -- Motor commands are stored in the UT as required by the UC/UT partition.
    motor_command_registers : process(clk_i, rst_i) is
    begin
        if rst_i = '1' then
            en_l_o  <= '0';
            en_m_o  <= '0';
            en_r_o  <= '0';
            dir_l_o <= '0';
            dir_m_o <= '0';
            dir_r_o <= '0';
        elsif rising_edge(clk_i) then
            en_l_o  <= en_mot_l_i;
            en_m_o  <= en_mot_m_i;
            en_r_o  <= en_mot_r_i;
            dir_l_o <= dir_mot_l_i;
            dir_m_o <= dir_mot_m_i;
            dir_r_o <= dir_mot_r_i;
        end if;
    end process motor_command_registers;

end behave;
