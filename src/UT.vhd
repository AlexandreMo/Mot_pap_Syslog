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

--| Library |------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
-------------------------------------------------------------------------------

--| Entity |-------------------------------------------------------------------
entity UT is
    port(
        clk_i                 : in  std_logic;
        rst_i                 : in  std_logic;

         
        sel_speed_o           : out std_logic;
        en_l_o                : out std_logic;
        en_m_o                : out std_logic;
        en_r_o                : out std_logic;
        dir_l_o               : out std_logic;
        dir_m_o               : out std_logic;
        dir_r_o               : out std_logic
    );
end UT;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture behave of UT is

    --| Constantes |-----------------------------------------------------------

    -- to be completed



    --| Signals |--------------------------------------------------------------
    signal ld_vit_s       : std_logic := '0';
    signal en_vit_s       : std_logic := '0';
    signal ld_enc_s       : std_logic := '0';
    signal en_enc_s       : std_logic := '0';
    signal ld_tours_s     : std_logic := '0';
    signal cpt_vit_s      : std_logic_vector(1 downto 0);
    signal encoches_s     : std_logic_vector(6 downto 0);
    signal tours_s        : std_logic_vector(3 downto 0);



    --| Components |-----------------------------------------------------------
    component cpt_vitesse
        port(
            clk_i      : in  std_logic;
            rst_i      : in  std_logic;
            ld_vit_i   : in  std_logic;
            en_vit_i   : in  std_logic;
            cpt_vit    : out std_logic_vector(1 downto 0)
        );
    end component;

    component cpt_encoches
        port(
            clk_i      : in  std_logic;
            rst_i      : in  std_logic;
            ld_enc_i   : in  std_logic;
            en_enc_i   : in  std_logic;
            encoches   : out std_logic_vector(6 downto 0)
        );
    end component;

    component mem_tours
        port(
            clock_i    : in  std_logic;
            nReset_i   : in  std_logic;
            ld_i       : in  std_logic;
            en_i       : in  std_logic;
            reg_o      : out std_logic_vector(3 downto 0)
        );
    end component;




begin
    --Synchronisation du nb de tours
    mem_tours : srg4
        port map(
            clock_i    => clk_i,
            nReset_i   => rst_i,
            ld_i       => ld_tours_s,
            en_i       => en,
            reg_o      => tours_s
        );
    -- Compteur de vitesse
   cpt_vitesse_inst : cpt_vitesse
        port map(
            clk_i      => clk_i,
            rst_i      => rst_i,
            ld_vit_i   => ld_vit_s,
            en_vit_i   => en_vit_s,
            cpt_vit    => cpt_vit_s
        );
    -- Compteur d'encoches
    cpt_encoches_inst : cpt_encoches
        port map(
            clk_i      => clk_i,
            rst_i      => rst_i,
            ld_enc_i   => ld_enc_s,
            en_enc_i   => en_enc_s,
            encoches   => encoches_s
        );
    -- Enable moteur Gauche
    rs_en_l : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => not rst_i,      -- adaptation polarité
            R_i     => stop_mot_l_s,   -- commande UC : stop
            S_i     => start_mot_l_s,  -- commande UC : start
            Q_o     => en_l_o
        );

    -- Enable moteur Milieu
    rs_en_m : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => not rst_i,
            R_i     => stop_mot_m_s,
            S_i     => start_mot_m_s,
            Q_o     => en_m_o
        );

    -- Enable moteur Droite
    rs_en_r : flipflop_rs
        port map(
            clk_i   => clk_i,
            reset_i => not rst_i,
            R_i     => stop_mot_r_s,
            S_i     => start_mot_r_s,
            Q_o     => en_r_o
        );
    -- Moteur Gauche : toujours anti-horaire
    dir_l_o <= '0';

    -- Moteur Milieu
    dir_m_o <= '1' when sel_dir_m_i = '1' else '0';

    -- Moteur Droite  
    dir_r_o <= '1' when sel_dir_r_i = '1' else '0';

    



end behave;
