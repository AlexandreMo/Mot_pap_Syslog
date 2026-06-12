-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : UT.vhd
--
-- Description  : UT pour la commande des 3 moteurs pas-a-pas
--
-- Auteur       : A.Moore & Kosher Ali

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

entity UT is
    port(
        clk_i                 : in  std_logic;
        rst_i                 : in  std_logic;  -- actif bas
        nb_tour_i             : in  std_logic_vector(2 downto 0);
        -- Commandes enables (depuis UC)
        set_l_i               : in  std_logic;
        set_m_i               : in  std_logic;
        set_r_i               : in  std_logic;
        stop_l_i              : in  std_logic;
        stop_m_i              : in  std_logic;
        stop_r_i              : in  std_logic;
        -- Commande direction (depuis UC) : '0'=anti-horaire, '1'=horaire
        sel_dir_i             : in  std_logic;
        -- Commandes compteurs (depuis UC)
        nSpeed_cst_i          : in  std_logic;
        decr_cpt_encoche_i    : in  std_logic;
        decr_cpt_tour_i       : in  std_logic;
        decr_cpt_disk_i       : in  std_logic;
        load_cpt_encoche_i    : in  std_logic;
        load_cpt_tour_i       : in  std_logic;
        load_cpt_disk_i       : in  std_logic;
        -- Conditions vers UC
        cpt_encoche_eq_zero_o : out std_logic;
        cpt_tour_eq_zero_o    : out std_logic;
        cpt_disk_eq_m_o       : out std_logic;
        cpt_disk_eq_l_o       : out std_logic;
        cpt_disk_eq_r_o       : out std_logic;
        -- Sorties moteurs
        en_l_o                : out std_logic;
        dir_l_o               : out std_logic;
        en_m_o                : out std_logic;
        dir_m_o               : out std_logic;
        en_r_o                : out std_logic;
        dir_r_o               : out std_logic;
        sel_speed_o           : out std_logic_vector(1 downto 0)
    );
end UT;

architecture behave of UT is

    --| Composants |-----------------------------------------------------------
    component flipflop_rs is
        port(
            clk_i    : in  std_logic;
            reset_i  : in  std_logic;
            R_i      : in  std_logic;
            S_i      : in  std_logic;
            Q_o      : out std_logic
        );
    end component;

    component cpt_encoches is
        port(
            clk_i                 : in  std_logic;
            rst_i                 : in  std_logic;
            load_cpt_encoche_i    : in  std_logic;
            decr_cpt_encoche_i    : in  std_logic;
            cpt_encoche_eq_zero_o : out std_logic
        );
    end component;

    component cpt_tours is
        port(
            clk_i                 : in  std_logic;
            rst_i                 : in  std_logic;
            load_cpt_tour_i       : in  std_logic;
            val_tours             : in  std_logic_vector(2 downto 0);
            decr_cpt_tour_i       : in  std_logic;
            cpt_tour_eq_zero_o    : out std_logic
        );
    end component;

    component cpt_disk is
        port(
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;
            load_cpt_disk_i : in  std_logic;
            incr_cpt_disk_i : in  std_logic;
	    cpt_speed_o     : out std_logic_vector(1 downto 0);
            cpt_disk_eq_m_o : out std_logic;
            cpt_disk_eq_l_o : out std_logic;
            cpt_disk_eq_r_o : out std_logic
        );
    end component;

    --| Signaux |--------------------------------------------------------------
    signal en_l_s, en_m_s, en_r_s     : std_logic;
    signal dir_l_s, dir_m_s, dir_r_s  : std_logic;
    signal cpt_speed_s : std_logic_vector(1 downto 0);
    --| Constantes |-----------------------------------------------------------
    signal VIT_CST : std_logic_vector(1 downto 0) := "01";
begin

    --| Flip-Flop RS pour le moteur gauche (Left) |---------------------------
    ff_rs_l : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            S_i     => set_l_i,
            R_i     => stop_l_i,
            Q_o     => en_l_s
        );

    --| Flip-Flop RS pour le moteur central (Middle) |------------------------
    ff_rs_m : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            S_i     => set_m_i,
            R_i     => stop_m_i,
            Q_o     => en_m_s
        );

    --| Flip-Flop RS pour le moteur droit (Right) |---------------------------
    ff_rs_r : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            S_i     => set_r_i,
            R_i     => stop_r_i,
            Q_o     => en_r_s
        );

    --| Compteur d'encoches |--------------------------------------------------
    cpt_enc : cpt_encoches
        port map(
            clk_i                 => clk_i,
            rst_i                 => rst_i,
            load_cpt_encoche_i    => load_cpt_encoche_i,
            decr_cpt_encoche_i    => decr_cpt_encoche_i,
            cpt_encoche_eq_zero_o => cpt_encoche_eq_zero_o
        );

    --| Compteur de tours |----------------------------------------------------
    cpt_tour : cpt_tours
        port map(
            clk_i               => clk_i,
            rst_i               => rst_i,
            load_cpt_tour_i     => load_cpt_tour_i,
            val_tours           => nb_tour_i,
            decr_cpt_tour_i     => decr_cpt_tour_i,
            cpt_tour_eq_zero_o  => cpt_tour_eq_zero_o
        );

    --| Compteur de disque |---------------------------------------------------
    cpt_d : cpt_disk
        port map(
            clk_i           => clk_i,
            rst_i           => rst_i,
            load_cpt_disk_i => load_cpt_disk_i,
            incr_cpt_disk_i => decr_cpt_disk_i,
            cpt_speed_o     => cpt_speed_s,
            cpt_disk_eq_m_o => cpt_disk_eq_m_o,
            cpt_disk_eq_l_o => cpt_disk_eq_l_o,
            cpt_disk_eq_r_o => cpt_disk_eq_r_o
        );

    --| Assignations de sorties |----------------------------------------------
    en_l_o     <= en_l_s;
    en_m_o     <= en_m_s;
    en_r_o     <= en_r_s;
    dir_l_o    <= sel_dir_i;
    dir_m_o    <= sel_dir_i;
    dir_r_o    <= sel_dir_i;
    sel_speed_o <= VIT_CST when nSpeed_cst_i = '1' else 
                   cpt_speed_s;

end behave;