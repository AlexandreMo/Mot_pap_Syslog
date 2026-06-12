-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : UC.vhd
--
-- Description  : UC pour la commande des 3 moteurs pas-a-pas
--
-- Auteur       : ....
-- Date         : 21.05.2024
-- Version      : 1.0
--
-- Utilise dans : Labo moteur pas-à-pas (MSS cplx)
--
--| Modifications |------------------------------------------------------------
-- Version   Auteur      Date               Description
--
--
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

--| Entity |-------------------------------------------------------------------
entity UC is  --Repris depuis le console_sim_uc.vhd
    port(
        clk_i          : in  std_logic;
        rst_i          : in  std_logic;
        mode_i         : in  std_logic;
        start_i        : in  std_logic;
        init_i         : in  std_logic;
        mot_free_l_i   : in  std_logic;
        mot_free_m_i   : in  std_logic;
        mot_free_r_i   : in  std_logic;
        all_free_i     : in  std_logic;
        err_config_i   : in  std_logic;
        run_l_i        : in  std_logic;
        run_m_i        : in  std_logic;
        run_r_i        : in  std_logic;
        enc_det_l_i    : in  std_logic;
        enc_det_m_i    : in  std_logic;
        enc_det_r_i    : in  std_logic;
        tour_done_i    : in  std_logic;
        last_tour_i    : in  std_logic;
        ld_nb_tour_o   : out std_logic;
        en_mot_l_o     : out std_logic;
        en_mot_m_o     : out std_logic;
        en_mot_r_o     : out std_logic;
        dir_mot_l_o    : out std_logic;
        dir_mot_m_o    : out std_logic;
        dir_mot_r_o    : out std_logic;
        cnt_enc_rst_o  : out std_logic;
        cnt_tour_rst_o : out std_logic;
        speed_up_o     : out std_logic;
        speed_down_o   : out std_logic;
        speed_rst_o    : out std_logic;
        sel_mot_o      : out std_logic_vector(1 downto 0);
        err_o          : out std_logic
    );
end UC;

--| Architecture |-------------------------------------------------------------
architecture fsm of UC is

    --| Constantes |----------------------------------------------------------------
    signal SENS_ANTI_HORAIRE_C : std_logic := '0';
    signal SENS_HORAIRE_C      : std_logic := '1';
--| Types |----------------------------------------------------------------
    type state_t is (
        -- General states
        IDLE,
        INIT_REQUEST,

        -- Init sequence
        INIT_STOP_ALL,
        INIT_CHECK_M,
        INIT_STOP_M,
        INIT_CHECK_L,
        INIT_STOP_L,
        INIT_START_L,
        INIT_CHECK_R,
        INIT_CHECK_R_2
        INIT_STOP_R,
        INIT_START_R,
        INIT_DONE,

        -- Mode Manuel
        MAN_IDLE,
        MAN_CHECK_M,
        MAN_RUN_M,
        MAN_CHECK_L,
        MAN_RUN_L,
        MAN_CHECK_R,
        MAN_RUN_R,
        MAN_CHECK_LR,
        MAN_STOP_ALL,

        -- Mode Automatique
        AUTO_IDLE,
        AUTO_MEMORIZE_TOURS,
        AUTO_START_M,
        AUTO_INIT_CPT_ENC,
        AUTO_INIT_CPT_VIT,
        AUTO_RUN,
        AUTO_WAIT_ENC,
        AUTO_INCR_ENC,
        AUTO_CHECK_ENC5,
        AUTO_INCR_TOUR,
        AUTO_CHECK_TOUR,
        AUTO_INCR_VIT,
        AUTO_DECR_VIT,
        AUTO_CHECK_VIT_ZERO,
        AUTO_START_L,
        AUTO_START_R,

        AUTO_DONE,

        -- Error
        ERR
    );

    --| Signals |--------------------------------------------------------------
    signal current_state_s : state_t;
    signal next_state_s    : state_t;
begin
    --| Process combinatoire : calcul du prochain état |------------------------
    fut : process(current_state_s, mode_i, start_i, init_i,
            run_l_i, run_m_i, run_r_i,
            cap_l_i, cap_m_i, cap_r_i,
            cpt_encoche_eq_zero_o, cpt_tour_eq_zero_o,
            cpt_disk_eq_m_o, cpt_disk_eq_l_o, cpt_disk_eq_r_o)
    begin
        -- Valeur par défaut : on reste sur place
        next_state_s <= current_state_s;

        case current_state_s is

            ----------------------------------------------------------------
            -- ÉTATS GÉNÉRAUX
            ----------------------------------------------------------------
            when IDLE =>
                next_state_s <= INIT_REQUEST;

            when INIT_REQUEST =>
                if init_i = '1' then
                    next_state_s <= INIT_STOP_ALL;
                elsif mode_i = '0' then
                    next_state_s <= MAN_IDLE;
                else -- mode_i = '1' (auto)
                    if start_i = '1' then
                        next_state_s <= AUTO_IDLE;
                    else
                        next_state_s <= INIT_REQUEST;
                    end if;
                end if;

            ----------------------------------------------------------------
            -- SÉQUENCE D'INITIALISATION  (image 4)
            ----------------------------------------------------------------
            when INIT_STOP_ALL =>
                next_state_s <= INIT_CHECK_M;

            when INIT_CHECK_M =>
                -- "Mode M libre?"
                if cap_m_i = '1' then       -- Libre -> O
                    next_state_s <= INIT_CHECK_L;
                else                          -- N
                    next_state_s <= INIT_STOP_M;
                end if;

            when INIT_STOP_M =>
                next_state_s <= INIT_CHECK_L_2;  -- branche de droite du schéma

            -- Branche "Mode M Libre = O" -> check L puis R puis start M
            when INIT_CHECK_L =>
                if cap_l_i = '1' then
                    next_state_s <= INIT_CHECK_R;
                else
                    next_state_s <= ERR;  -- N -> erreur
                end if;

            when INIT_CHECK_R =>
                if cap_r_i = '1' then
                    next_state_s <= INIT_START_M;
                else
                    next_state_s <= ERR;
                end if;

            when INIT_START_M =>
                next_state_s <= INIT_DONE;

            -- Branche "Mode M Libre = N" -> stop M, check L, check R
            when INIT_CHECK_L_2 =>
                if cap_l_i = '1' then
                    next_state_s <= INIT_STOP_L;
                else
                    next_state_s <= ERR;
                end if;

            when INIT_STOP_L =>
                next_state_s <= INIT_CHECK_R_2;

            when INIT_CHECK_R_2 =>
                if cap_r_i = '1' then
                    next_state_s <= INIT_STOP_R;
                else
                    next_state_s <= ERR;
                end if;

            when INIT_STOP_R =>
                next_state_s <= INIT_DONE;

            when INIT_DONE =>
                next_state_s <= INIT_REQUEST;

            ----------------------------------------------------------------
            -- MODE MANUEL  (image 1)
            ----------------------------------------------------------------
            when MAN_IDLE =>
                if mode_i = '1' then
                    next_state_s <= INIT_REQUEST;  -- retour si on bascule en auto
                elsif run_m_i = '1' then
                    next_state_s <= MAN_CHECK_M;
                else
                    next_state_s <= MAN_CHECK_LR;  -- "run_l, run_r = 0 ?"
                end if;

            when MAN_CHECK_LR =>
                -- "run_l, run_r = 0" -> O signifie aucun des deux actif
                if run_l_i = '0' and run_r_i = '0' then
                    next_state_s <= MAN_LR_LIBRES;
                else
                    next_state_s <= MAN_STOP_M;
                end if;

            when MAN_LR_LIBRES =>
                -- "Mode L,R Libres" : check cap_l_i et cap_r_i
                if cap_l_i = '1' and cap_r_i = '1' then
                    next_state_s <= MAN_START_M;
                else
                    next_state_s <= MAN_STOP_M;
                end if;

            when MAN_START_M =>
                next_state_s <= MAN_IDLE;

            when MAN_STOP_M =>
                next_state_s <= MAN_IDLE;

            -- "run_m_i = 1" -> détection run_r (côté droit du schéma)
            when MAN_CHECK_M =>
                next_state_s <= MAN_CHECK_M_LIBRE;

            when MAN_CHECK_M_LIBRE =>
                -- "Mode M Libre?"
                if cap_m_i = '1' then
                    next_state_s <= MAN_CHECK_RUN_L;
                else
                    next_state_s <= MAN_STOP_LR;  -- N -> stop L,R
                end if;

            when MAN_CHECK_RUN_L =>
                if run_l_i = '1' then
                    next_state_s <= MAN_START_L;
                else
                    next_state_s <= MAN_STOP_L;
                end if;

            when MAN_START_L =>
                next_state_s <= MAN_CHECK_RUN_R;

            when MAN_STOP_L =>
                next_state_s <= MAN_CHECK_RUN_R;

            when MAN_CHECK_RUN_R =>
                if run_r_i = '1' then
                    next_state_s <= MAN_START_R;
                else
                    next_state_s <= MAN_STOP_R;
                end if;

            when MAN_START_R =>
                next_state_s <= MAN_IDLE;

            when MAN_STOP_R =>
                next_state_s <= MAN_IDLE;

            when MAN_STOP_LR =>
                next_state_s <= MAN_IDLE;

            ----------------------------------------------------------------
            -- MODE AUTOMATIQUE  (images 2, 3, 5)
            ----------------------------------------------------------------
            when AUTO_IDLE =>
                -- "all disk free?"
                if cap_l_i = '1' and cap_m_i = '1' and cap_r_i = '1' then
                    next_state_s <= AUTO_MEMORIZE_TOURS;
                else
                    next_state_s <= ERR;
                end if;

            when AUTO_MEMORIZE_TOURS =>
                -- charge nb_tour_i dans le registre, init compteur disque (M)
                next_state_s <= AUTO_START_MOTOR;

            -- Démarre le moteur courant (M, puis L, puis R selon cpt_disk)
            when AUTO_START_MOTOR =>
                if cpt_disk_eq_m_o = '1' then
                    if cap_l_i = '1' and cap_r_i = '1' then
                        next_state_s <= AUTO_INIT_COUNTERS;
                    else
                        next_state_s <= ERR;
                    end if;
                elsif cpt_disk_eq_l_o = '1' then
                    if cap_m_i = '1' and cap_r_i = '1' then
                        next_state_s <= AUTO_INIT_COUNTERS;
                    else
                        next_state_s <= ERR;
                    end if;
                elsif cpt_disk_eq_r_o = '1' then
                    if cap_m_i = '1' and cap_l_i = '1' then
                        next_state_s <= AUTO_INIT_COUNTERS;
                    else
                        next_state_s <= ERR;
                    end if;
                else
                    next_state_s <= AUTO_DONE; -- cpt_disk = fin -> terminé
                end if;

            when AUTO_INIT_COUNTERS =>
                -- init cpt_encoche=1, cpt_tour=1 (1er tour)
                next_state_s <= AUTO_RUN;

            -- Boucle principale : tourne jusqu'à encoche = 5
            when AUTO_RUN =>
                next_state_s <= AUTO_CHECK_ENC5;

            when AUTO_CHECK_ENC5 =>
                -- "Encoche = 5?"
                if cpt_encoche_eq_zero_o = '1' then  -- atteint 5 (compteur revenu à 0)
                    next_state_s <= AUTO_CHECK_FIRST_TOUR;
                else
                    next_state_s <= AUTO_INCR_ENC;
                end if;

            when AUTO_INCR_ENC =>
                next_state_s <= AUTO_CHECK_VMAX;

            -- Phase accélération (1er tour) : incrémente vitesse jusqu'à Vmax
            when AUTO_CHECK_VMAX =>
                if nSpeed_cst_i = '1' then        -- "Vmax?" -> O = déjà au max
                    next_state_s <= AUTO_RUN;
                else
                    next_state_s <= AUTO_INCR_VIT;
                end if;

            when AUTO_INCR_VIT =>
                next_state_s <= AUTO_RUN;

            -- Encoche = 5 atteinte : reset encoche, incrémente tour
            when AUTO_CHECK_FIRST_TOUR =>
                next_state_s <= AUTO_INCR_TOUR;

            when AUTO_INCR_TOUR =>
                next_state_s <= AUTO_CHECK_LAST_TOUR;

            -- "cpt_tour >= nb_tour - 1 ?" -> dernier tour : on décélère
            when AUTO_CHECK_LAST_TOUR =>
                if cpt_tour_eq_zero_o = '1' then -- dernier tour en cours
                    next_state_s <= AUTO_CHECK_TOUR_EQ_NBTOUR;
                else
                    next_state_s <= AUTO_RUN;
                end if;

            -- "cpt_tour = nb_tour ?"
            when AUTO_CHECK_TOUR_EQ_NBTOUR =>
                if cpt_tour_eq_zero_o = '1' then  -- = nb_tour -> fin de séquence
                    next_state_s <= AUTO_MAINTAIN_TOUR;
                else
                    -- N -> retour boucle (décélération continue)
                    next_state_s <= AUTO_DECR_VIT;
                end if;

            when AUTO_DECR_VIT =>
                next_state_s <= AUTO_CHECK_VIT_ZERO;

            -- "vitesse == 0 ?"
            when AUTO_CHECK_VIT_ZERO =>
                if nSpeed_cst_i = '1' then  -- vitesse = 0 atteinte
                    next_state_s <= AUTO_STOP_CURRENT;
                else
                    next_state_s <= AUTO_RUN;
                end if;

            when AUTO_MAINTAIN_TOUR =>
                next_state_s <= AUTO_DECR_VIT;

            -- Fin de la séquence pour le disque courant : stop moteur, passer au suivant
            when AUTO_STOP_CURRENT =>
                next_state_s <= AUTO_NEXT_DISK;

            when AUTO_NEXT_DISK =>
                -- decr_cpt_disk effectué ; reboucle sur démarrage moteur suivant
                next_state_s <= AUTO_START_MOTOR;

            when AUTO_DONE =>
                next_state_s <= INIT_REQUEST;

            ----------------------------------------------------------------
            -- ERREUR
            ----------------------------------------------------------------
            when ERR =>
                if init_i = '1' then
                    next_state_s <= INIT_STOP_ALL;
                else
                    next_state_s <= ERR;
                end if;

            when others =>
                next_state_s <= IDLE;

        end case;
    end process;
    --| Process séquentiel : passage vers un autre état---------------------------------
    mem: process(clk_i, rst_i)
    begin
        if rst_i = '0' then
            current_state_s <= IDLE;
        elsif rising_edge(clk_i) then
            current_state_s <= next_state_s;
        end if;
    end process;

    --| Process combinatoire : gestion des sorties |-----------------------------
    out_comb : process(current_state_s)
    begin
        -- Valeurs par défaut : tout désactivé
        ld_nb_tour_o     <= '0';
        en_mot_l_o       <= '0';
        en_mot_m_o       <= '0';
        en_mot_r_o       <= '0';
        dir_mot_l_o      <= SENS_ANTI_HORAIRE_C;
        dir_mot_m_o      <= SENS_ANTI_HORAIRE_C;
        dir_mot_r_o      <= SENS_ANTI_HORAIRE_C;
        cnt_enc_rst_o    <= '0';
        cnt_tour_rst_o   <= '0';
        speed_up_o       <= '0';
        speed_down_o     <= '0';
        speed_rst_o      <= '0';
        sel_mot_o        <= "00";
        err_o            <= '0';

        case current_state_s is

            ----------------------------------------------------------------
            -- SÉQUENCE D'INITIALISATION
            ----------------------------------------------------------------
            when INIT_STOP_ALL =>
                en_mot_l_o   <= '0';
                en_mot_m_o   <= '0';
                en_mot_r_o   <= '0';
                speed_rst_o  <= '1';

            when INIT_STOP_M =>
                en_mot_m_o   <= '0';
                speed_rst_o  <= '1';

            when INIT_STOP_L =>
                en_mot_l_o   <= '0';

            when INIT_START_L =>
                en_mot_l_o   <= '1';
                dir_mot_l_o  <= SENS_HORAIRE_C;
                speed_rst_o  <= '1';



            when INIT_STOP_R =>
                en_mot_r_o   <= '0';

            when INIT_START_R =>
                en_mot_r_o   <= '1';
                dir_mot_r_o  <= SENS_HORAIRE_C;
                speed_rst_o  <= '1';

            when INIT_START_M =>
                en_mot_m_o   <= '1';
                dir_mot_m_o  <= SENS_HORAIRE_C;
                speed_rst_o  <= '1';



            ----------------------------------------------------------------
            -- MODE MANUEL
            ----------------------------------------------------------------
            when MAN_IDLE =>
                speed_rst_o  <= '1';



            when MAN_START_M =>
                en_mot_m_o   <= '1';
                dir_mot_m_o  <= SENS_HORAIRE_C;

            when MAN_STOP_M =>
                en_mot_m_o   <= '0';
                speed_rst_o  <= '1';


            when MAN_START_L =>
                en_mot_l_o   <= '1';
                dir_mot_l_o  <= SENS_HORAIRE_C;

            when MAN_STOP_L =>
                en_mot_l_o   <= '0';

            when MAN_START_R =>
                en_mot_r_o   <= '1';
                dir_mot_r_o  <= SENS_HORAIRE_C;

            when MAN_STOP_R =>
                en_mot_r_o   <= '0';

            when MAN_STOP_LR =>
                en_mot_l_o   <= '0';
                en_mot_r_o   <= '0';
                speed_rst_o  <= '1';

            ----------------------------------------------------------------
            -- MODE AUTOMATIQUE
            ----------------------------------------------------------------
            when AUTO_IDLE =>
                speed_rst_o  <= '1';

            when AUTO_MEMORIZE_TOURS =>
                ld_nb_tour_o <= '1';
                cnt_enc_rst_o<= '1';
                sel_mot_o    <= "00";  -- Start with disk M

            when AUTO_START_MOTOR =>
                -- Active le moteur selon cpt_disk
                -- M = "00", L = "01", R = "10"
                if cpt_disk_eq_m_o = '1' then
                    en_mot_m_o  <= '1';
                    dir_mot_m_o <= SENS_HORAIRE_C;
                    sel_mot_o   <= "00";
                elsif cpt_disk_eq_l_o = '1' then
                    en_mot_l_o  <= '1';
                    dir_mot_l_o <= SENS_HORAIRE_C;
                    sel_mot_o   <= "01";
                elsif cpt_disk_eq_r_o = '1' then
                    en_mot_r_o  <= '1';
                    dir_mot_r_o <= SENS_HORAIRE_C;
                    sel_mot_o   <= "10";
                end if;

            when AUTO_INIT_COUNTERS =>
                cnt_enc_rst_o  <= '1';
                cnt_tour_rst_o <= '1';
                speed_rst_o    <= '1';

            when AUTO_RUN =>
                -- Moteur tourne, pas de changement

            when AUTO_CHECK_ENC5 =>
                -- Vérification, pas d'action

            when AUTO_INCR_ENC =>
                -- Compteur géré par UT

            when AUTO_CHECK_VMAX =>
                -- Vérification

            when AUTO_INCR_VIT =>
                speed_up_o   <= '1';

            when AUTO_CHECK_FIRST_TOUR =>
                cnt_enc_rst_o <= '1';

            when AUTO_INCR_TOUR =>
                -- Compteur géré par UT

            when AUTO_CHECK_LAST_TOUR =>
                -- Vérification

            when AUTO_CHECK_TOUR_EQ_NBTOUR =>
                -- Vérification

            when AUTO_MAINTAIN_TOUR =>
                -- Maintien du tour

            when AUTO_DECR_VIT =>
                speed_down_o <= '1';

            when AUTO_CHECK_VIT_ZERO =>
                -- Vérification

            when AUTO_STOP_CURRENT =>
                en_mot_l_o   <= '0';
                en_mot_m_o   <= '0';
                en_mot_r_o   <= '0';
                speed_rst_o  <= '1';

            when AUTO_NEXT_DISK =>
                -- Passage au disque suivant (décrémentation cpt_disk)
                decr_cpt_disk_o <= '1';

            when AUTO_DONE =>
                -- Rien à faire

            ----------------------------------------------------------------
            -- ERREUR
            ----------------------------------------------------------------
            when ERR =>
                err_o        <= '1';
                en_mot_l_o   <= '0';
                en_mot_m_o   <= '0';
                en_mot_r_o   <= '0';
                speed_rst_o  <= '1';

            when others =>
                err_o <= '1';

        end case;
    end process;

end fsm;

