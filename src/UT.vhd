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

    --| Signaux internes |-----------------------------------------------------
    signal ld_vit_s    : std_logic := '0';
    signal en_vit_s    : std_logic := '0';
    signal ld_enc_s    : std_logic := '0';
    signal en_enc_s    : std_logic := '0';
    signal ld_tours_s  : std_logic := '0';
    signal cpt_vit_s   : std_logic_vector(1 downto 0);
    signal encoches_s  : std_logic_vector(6 downto 0);
    signal tours_s     : std_logic_vector(3 downto 0);
    signal rst_high_s  : std_logic;  -- reset actif haut pour les RS

    --| Components |-----------------------------------------------------------
    component flipflop_rs
        port(
            clk_i   : in  std_logic;
            reset_i : in  std_logic;
            R_i     : in  std_logic;
            S_i     : in  std_logic;
            Q_o     : out std_logic
        );
    end component;

    component cpt_vitesse
        port(
            clk_i    : in  std_logic;
            rst_i    : in  std_logic;
            ld_vit_i : in  std_logic;
            en_vit_i : in  std_logic;
            cpt_vit  : out std_logic_vector(1 downto 0)
        );
    end component;

    component cpt_encoches
        port(
            clk_i    : in  std_logic;
            rst_i    : in  std_logic;
            ld_enc_i : in  std_logic;
            en_enc_i : in  std_logic;
            encoches : out std_logic_vector(6 downto 0)
        );
    end component;

    component mem_tours
        port(
            clock_i  : in  std_logic;
            nReset_i : in  std_logic;
            ld_i     : in  std_logic;
            val_i    : in  std_logic_vector(2 downto 0);
            en_i     : in  std_logic;
            reg_o    : out std_logic_vector(3 downto 0)
        );
    end component;

begin

    --| Adaptation polarité reset |--------------------------------------------
    rst_high_s <= not rst_i;  -- rst_i actif bas → actif haut pour les RS

    --| Mémorisation nb_tours |------------------------------------------------
    mem_tours_inst : mem_tours
        port map(
            clock_i  => clk_i,
            nReset_i => rst_i,        -- actif bas, direct
            ld_i     => ld_tours_s,
            val_i    => nb_tour_i,
            en_i     => '0',          -- pas d'incrémentation
            reg_o    => tours_s
        );

    --| Compteur de vitesse |--------------------------------------------------
    cpt_vitesse_inst : cpt_vitesse
        port map(
            clk_i    => clk_i,
            rst_i    => rst_i,
            ld_vit_i => ld_vit_s,
            en_vit_i => en_vit_s,
            cpt_vit  => cpt_vit_s
        );

    --| Compteur d'encoches |-------------------------------------------------
    cpt_encoches_inst : cpt_encoches
        port map(
            clk_i    => clk_i,
            rst_i    => rst_i,
            ld_enc_i => ld_enc_s,
            en_enc_i => en_enc_s,
            encoches => encoches_s
        );

    --| Bascules RS enables moteurs |-----------------------------------------
    rs_en_l : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => rst_high_s,
            R_i     => stop_l_i,   -- port de l'UC
            S_i     => set_l_i,    -- port de l'UC
            Q_o     => en_l_o
        );

    rs_en_m : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => rst_high_s,
            R_i     => stop_m_i,
            S_i     => set_m_i,
            Q_o     => en_m_o
        );

    rs_en_r : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => rst_high_s,
            R_i     => stop_r_i,
            S_i     => set_r_i,
            Q_o     => en_r_o
        );

    --| Directions |-----------------------------------------------------------
    dir_l_o <= '0';                                    -- toujours anti-horaire
    dir_m_o <= '1' when sel_dir_i = '1' else '0';
    dir_r_o <= '1' when sel_dir_i = '1' else '0';

    --| Vitesse vers controller_mot_pap |--------------------------------------
    sel_speed_o <= cpt_vit_s;

end behave;