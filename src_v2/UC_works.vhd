-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : UC.vhd
--
-- Description  : Unite de commande des trois moteurs pas-a-pas
--
-- Utilise dans : Labo moteur pas-a-pas (MSS cplx)
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

--| Entity |-------------------------------------------------------------------
entity UC is
    port(
        clk_i              : in  std_logic;
        rst_i              : in  std_logic;

        mode_i             : in  std_logic;
        start_i            : in  std_logic;
        init_i             : in  std_logic;
        run_l_i            : in  std_logic;
        run_m_i            : in  std_logic;
        run_r_i            : in  std_logic;

        mot_free_l_i       : in  std_logic;
        mot_free_m_i       : in  std_logic;
        mot_free_r_i       : in  std_logic;
        all_free_i         : in  std_logic;
        err_config_i       : in  std_logic;

        enc_det_l_i        : in  std_logic;
        enc_det_m_i        : in  std_logic;
        enc_det_r_i        : in  std_logic;
        tour_done_i        : in  std_logic;
        last_tour_i        : in  std_logic;

        ld_nb_tour_o       : out std_logic;
        en_mot_l_o         : out std_logic;
        en_mot_m_o         : out std_logic;
        en_mot_r_o         : out std_logic;
        dir_mot_l_o        : out std_logic;
        dir_mot_m_o        : out std_logic;
        dir_mot_r_o        : out std_logic;
        cnt_enc_rst_o      : out std_logic;
        cnt_tour_rst_o     : out std_logic;
        speed_up_o         : out std_logic;
        speed_down_o       : out std_logic;
        speed_rst_o        : out std_logic;
        sel_mot_o          : out std_logic_vector(1 downto 0);
        err_o              : out std_logic
    );
end UC;

--| Architecture |-------------------------------------------------------------
architecture fsm of UC is

    type state_t is (
        RESET_HOME,
        HOME_CHOOSE,
        HOME_LEFT,
        HOME_CENTER,
        HOME_RIGHT,
        STANDBY,
        HAND_MODE,
        LOAD_AUTO,
        SPIN_CENTER,
        SPIN_LEFT,
        SPIN_RIGHT,
        FAULT
    );

    constant DIR_CCW : std_logic := '0';
    constant DIR_CW  : std_logic := '1';

    signal current_state_s : state_t;
    signal next_state_s    : state_t;

    signal manual_conflict_s : std_logic;
    signal manual_blocked_s  : std_logic;

begin

    manual_conflict_s <= run_m_i and (run_l_i or run_r_i);

    manual_blocked_s <= ((run_l_i or run_r_i) and not mot_free_m_i) or
                        (run_m_i and not (mot_free_l_i and mot_free_r_i));

    --| State register |--------------------------------------------------------
    fsm_reg : process(clk_i, rst_i) is
    begin
        if rst_i = '1' then
            current_state_s <= RESET_HOME;
        elsif rising_edge(clk_i) then
            current_state_s <= next_state_s;
        end if;
    end process fsm_reg;

    --| Next-state and output decoder |-----------------------------------------
    fsm_decode : process(all) is
    begin
        next_state_s   <= current_state_s;

        ld_nb_tour_o   <= '0';
        en_mot_l_o     <= '0';
        en_mot_m_o     <= '0';
        en_mot_r_o     <= '0';
        dir_mot_l_o    <= DIR_CCW;
        dir_mot_m_o    <= DIR_CCW;
        dir_mot_r_o    <= DIR_CCW;
        cnt_enc_rst_o  <= '0';
        cnt_tour_rst_o <= '0';
        speed_up_o     <= '0';
        speed_down_o   <= '0';
        speed_rst_o    <= '0';
        sel_mot_o      <= "00";
        err_o          <= '0';

        case current_state_s is

            when RESET_HOME =>
                speed_rst_o    <= '1';
                cnt_enc_rst_o  <= '1';
                cnt_tour_rst_o <= '1';
                next_state_s   <= HOME_CHOOSE;

            when HOME_CHOOSE =>
                speed_rst_o <= '1';

                if err_config_i = '1' then
                    next_state_s <= FAULT;
                elsif all_free_i = '1' then
                    next_state_s <= STANDBY;
                elsif mot_free_l_i = '0' and mot_free_m_i = '1' then
                    next_state_s <= HOME_LEFT;
                elsif mot_free_m_i = '0' and
                      mot_free_l_i = '1' and mot_free_r_i = '1' then
                    next_state_s <= HOME_CENTER;
                elsif mot_free_r_i = '0' and mot_free_m_i = '1' then
                    next_state_s <= HOME_RIGHT;
                else
                    next_state_s <= FAULT;
                end if;

            when HOME_LEFT =>
                speed_rst_o <= '1';
                dir_mot_l_o <= DIR_CCW;

                if mot_free_l_i = '1' then
                    next_state_s <= HOME_CHOOSE;
                elsif err_config_i = '1' or mot_free_m_i = '0' then
                    next_state_s <= FAULT;
                else
                    en_mot_l_o <= '1';
                end if;

            when HOME_CENTER =>
                speed_rst_o <= '1';
                dir_mot_m_o <= DIR_CCW;

                if mot_free_m_i = '1' then
                    next_state_s <= HOME_CHOOSE;
                elsif err_config_i = '1' or
                      mot_free_l_i = '0' or mot_free_r_i = '0' then
                    next_state_s <= FAULT;
                else
                    en_mot_m_o <= '1';
                end if;

            when HOME_RIGHT =>
                speed_rst_o <= '1';
                dir_mot_r_o <= DIR_CCW;

                if mot_free_r_i = '1' then
                    next_state_s <= HOME_CHOOSE;
                elsif err_config_i = '1' or mot_free_m_i = '0' then
                    next_state_s <= FAULT;
                else
                    en_mot_r_o <= '1';
                end if;

            when STANDBY =>
                speed_rst_o <= '1';

                if init_i = '1' then
                    next_state_s <= RESET_HOME;
                elsif mode_i = '1' and err_config_i = '1' then
                    next_state_s <= FAULT;
                elsif mode_i = '0' then
                    next_state_s <= HAND_MODE;
                elsif start_i = '1' and all_free_i = '1' then
                    next_state_s <= LOAD_AUTO;
                end if;

            when HAND_MODE =>
                speed_rst_o <= '1';
                dir_mot_l_o <= DIR_CCW;
                dir_mot_m_o <= DIR_CCW;
                dir_mot_r_o <= DIR_CCW;

                if init_i = '1' then
                    next_state_s <= RESET_HOME;
                elsif mode_i = '1' then
                    next_state_s <= STANDBY;
                elsif manual_conflict_s = '0' and manual_blocked_s = '0' then
                    en_mot_l_o <= run_l_i;
                    en_mot_m_o <= run_m_i;
                    en_mot_r_o <= run_r_i;
                end if;

            when LOAD_AUTO =>
                ld_nb_tour_o   <= '1';
                cnt_enc_rst_o  <= '1';
                cnt_tour_rst_o <= '1';
                speed_rst_o    <= '1';
                next_state_s   <= SPIN_CENTER;

            when SPIN_CENTER =>
                sel_mot_o   <= "00";
                dir_mot_m_o <= DIR_CW;

                if tour_done_i = '1' then
                    cnt_enc_rst_o  <= '1';
                    cnt_tour_rst_o <= '1';
                    speed_rst_o    <= '1';
                    next_state_s   <= SPIN_LEFT;
                elsif mot_free_l_i = '0' or mot_free_r_i = '0' then
                    next_state_s <= FAULT;
                else
                    en_mot_m_o <= '1';
                    if enc_det_m_i = '1' then
                        if last_tour_i = '1' then
                            speed_down_o <= '1';
                        else
                            speed_up_o <= '1';
                        end if;
                    end if;
                end if;

            when SPIN_LEFT =>
                sel_mot_o   <= "01";
                dir_mot_l_o <= DIR_CCW;

                if tour_done_i = '1' then
                    cnt_enc_rst_o  <= '1';
                    cnt_tour_rst_o <= '1';
                    speed_rst_o    <= '1';
                    next_state_s   <= SPIN_RIGHT;
                elsif mot_free_m_i = '0' then
                    next_state_s <= FAULT;
                else
                    en_mot_l_o <= '1';
                    if enc_det_l_i = '1' then
                        if last_tour_i = '1' then
                            speed_down_o <= '1';
                        else
                            speed_up_o <= '1';
                        end if;
                    end if;
                end if;

            when SPIN_RIGHT =>
                sel_mot_o   <= "10";
                dir_mot_r_o <= DIR_CW;

                if tour_done_i = '1' then
                    cnt_enc_rst_o  <= '1';
                    cnt_tour_rst_o <= '1';
                    speed_rst_o    <= '1';
                    next_state_s   <= STANDBY;
                elsif mot_free_m_i = '0' then
                    next_state_s <= FAULT;
                else
                    en_mot_r_o <= '1';
                    if enc_det_r_i = '1' then
                        if last_tour_i = '1' then
                            speed_down_o <= '1';
                        else
                            speed_up_o <= '1';
                        end if;
                    end if;
                end if;

            when FAULT =>
                err_o       <= '1';
                speed_rst_o <= '1';

                if init_i = '1' and err_config_i = '0' then
                    next_state_s <= RESET_HOME;
                end if;

            when others =>
                next_state_s <= RESET_HOME;

        end case;
    end process fsm_decode;

end fsm;
