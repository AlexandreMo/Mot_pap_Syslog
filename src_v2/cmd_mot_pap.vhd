-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cmd_mot_pap.vhd
--
-- Description  :
--
-- Auteur       : L. Fournier
-- Date         : 06.09.2022
-- Version      : 1.0
--
-- Utilise dans : Labo moteur pas-à-pas
--
--| Modifications |------------------------------------------------------------
-- Version   Auteur      Date               Description
-- 1.0       LFR         06.09.2022         First version.
-- 2.0       LFR         16.02.2024         2024 version for SysLog2 (MSS cplx)
--
-------------------------------------------------------------------------------

--| Library |------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
-------------------------------------------------------------------------------

--| Entity |-------------------------------------------------------------------
entity cmd_mot_pap is
    generic(
        SIMULATION : boolean := false
    );
    port(
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        cap_l_i     : in  std_logic;
        cap_m_i     : in  std_logic;
        cap_r_i     : in  std_logic;
        mode_i      : in  std_logic;
        start_i     : in  std_logic;
        init_i      : in  std_logic;
        nb_tour_i   : in  std_logic_vector(2 downto 0);
        run_l_i     : in  std_logic;
        run_m_i     : in  std_logic;
        run_r_i     : in  std_logic;
        en_l_o      : out std_logic;
        dir_l_o     : out std_logic;
        en_m_o      : out std_logic;
        dir_m_o     : out std_logic;
        en_r_o      : out std_logic;
        dir_r_o     : out std_logic;
        sel_speed_o : out std_logic_vector(1 downto 0);
        err_o       : out std_logic
    );
end cmd_mot_pap;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture struct of cmd_mot_pap is

    --| Internal signals |-----------------------------------------------------
    signal en_l_s                : std_logic;
    signal en_m_s                : std_logic;
    signal en_r_s                : std_logic;
    signal dir_l_s               : std_logic;
    signal dir_r_s               : std_logic;
    signal dir_m_s               : std_logic;
    signal sel_speed_s            : std_logic_vector(1 downto 0);

    -- Signals from UC to UT
    signal set_l_s                : std_logic;
    signal set_m_s                : std_logic;
    signal set_r_s                : std_logic;
    signal stop_l_s               : std_logic;
    signal stop_m_s               : std_logic;
    signal stop_r_s               : std_logic;
    signal sel_dir_s              : std_logic;
    signal nSpeed_cst_s            : std_logic;
    signal decr_cpt_encoche_s     : std_logic;
    signal decr_cpt_tour_s        : std_logic;
    signal decr_cpt_disk_s        : std_logic;
    signal load_cpt_encoche_s     : std_logic;
    signal load_cpt_tour_s        : std_logic;
    signal load_cpt_disk_s        : std_logic;

    -- Signals from UT to UC
    signal cpt_encoche_eq_zero_s  : std_logic;
    signal cpt_tour_eq_zero_s     : std_logic;
    signal cpt_disk_eq_m_s        : std_logic;
    signal cpt_disk_eq_l_s        : std_logic;
    signal cpt_disk_eq_r_s        : std_logic;

    -- Input synchronization
    signal cap_l_sync_s           : std_logic;
    signal cap_m_sync_s           : std_logic;
    signal cap_r_sync_s           : std_logic;
    signal start_sync_s           : std_logic;
    signal init_sync_s            : std_logic;
    signal mode_sync_s            : std_logic;
    ---------------------------------------------------------------------------

    --| Components |-----------------------------------------------------------
    component UC is
        port(
            clk_i                 : in  std_logic;
            rst_i                 : in  std_logic;
            mode_i                : in  std_logic;
            start_i               : in  std_logic;
            init_i                : in  std_logic;
            cap_l_i               : in  std_logic;
            cap_m_i               : in  std_logic;
            cap_r_i               : in  std_logic;
            cpt_encoche_eq_zero_i : in  std_logic;
            cpt_tour_eq_zero_i    : in  std_logic;
            cpt_disk_eq_m_i       : in  std_logic;
            cpt_disk_eq_l_i       : in  std_logic;
            cpt_disk_eq_r_i       : in  std_logic;
            set_l_o               : out std_logic;
            set_m_o               : out std_logic;
            set_r_o               : out std_logic;
            stop_l_o              : out std_logic;
            stop_m_o              : out std_logic;
            stop_r_o              : out std_logic;
            sel_dir_o             : out std_logic;
            nSpeed_cst_o          : out std_logic;
            decr_cpt_encoche_o    : out std_logic;
            decr_cpt_tour_o       : out std_logic;
            decr_cpt_disk_o       : out std_logic;
            load_cpt_encoche_o    : out std_logic;
            load_cpt_tour_o       : out std_logic;
            load_cpt_disk_o       : out std_logic;
            err_o                 : out std_logic
        );
    end component;
    for all : UC use entity work.UC(fsm);

    component UT is
        port(
            clk_i                 : in  std_logic;
            rst_i                 : in  std_logic;
            nb_tour_i             : in  std_logic_vector(2 downto 0);
            set_l_i               : in  std_logic;
            set_m_i               : in  std_logic;
            set_r_i               : in  std_logic;
            stop_l_i              : in  std_logic;
            stop_m_i              : in  std_logic;
            stop_r_i              : in  std_logic;
            sel_dir_i             : in  std_logic;
            nSpeed_cst_i          : in  std_logic;
            decr_cpt_encoche_i    : in  std_logic;
            decr_cpt_tour_i       : in  std_logic;
            decr_cpt_disk_i       : in  std_logic;
            load_cpt_encoche_i    : in  std_logic;
            load_cpt_tour_i       : in  std_logic;
            load_cpt_disk_i       : in  std_logic;
            cpt_encoche_eq_zero_o : out std_logic;
            cpt_tour_eq_zero_o    : out std_logic;
            cpt_disk_eq_m_o       : out std_logic;
            cpt_disk_eq_l_o       : out std_logic;
            cpt_disk_eq_r_o       : out std_logic;
            en_l_o                : out std_logic;
            dir_l_o               : out std_logic;
            en_m_o                : out std_logic;
            dir_m_o               : out std_logic;
            en_r_o                : out std_logic;
            dir_r_o               : out std_logic;
            sel_speed_o           : out std_logic_vector(1 downto 0)
        );
    end component;
    for all : UT use entity work.UT(behave);
    ---------------------------------------------------------------------------

begin
    --| Bloc de pre-traitement des entrees |------------------------------------
    -- Input synchronization using DFF
    dff_cap_l : dff_en
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            D_i     => cap_l_i,
            en_i    => '1',
            Q_o     => cap_l_sync_s
        );

    dff_cap_m : dff_en
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            D_i     => cap_m_i,
            en_i    => '1',
            Q_o     => cap_m_sync_s
        );

    dff_cap_r : dff_en
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            D_i     => cap_r_i,
            en_i    => '1',
            Q_o     => cap_r_sync_s
        );

    dff_start : dff_en
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            D_i     => start_i,
            en_i    => '1',
            Q_o     => start_sync_s
        );

    dff_init : dff_en
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            D_i     => init_i,
            en_i    => '1',
            Q_o     => init_sync_s
        );
    dff_mode : dff_en
        port map(
            clk_i   => clk_i,
            reset_i => rst_i,
            D_i     => mode_i,
            en_i    => '1',
            Q_o     => mode_sync_s
        );
    --| Components instanciation |---------------------------------------------
    UC_inst : UC
    port map(
        clk_i                 => clk_i,
        rst_i                 => rst_i,
        mode_i                => mode_sync_s,
        start_i               => start_sync_s,
        init_i                => init_sync_s,
        cap_l_i               => cap_l_sync_s,
        cap_m_i               => cap_m_sync_s,
        cap_r_i               => cap_r_sync_s,
        cpt_encoche_eq_zero_i => cpt_encoche_eq_zero_s,
        cpt_tour_eq_zero_i    => cpt_tour_eq_zero_s,
        cpt_disk_eq_m_i       => cpt_disk_eq_m_s,
        cpt_disk_eq_l_i       => cpt_disk_eq_l_s,
        cpt_disk_eq_r_i       => cpt_disk_eq_r_s,
        set_l_o               => set_l_s,
        set_m_o               => set_m_s,
        set_r_o               => set_r_s,
        stop_l_o              => stop_l_s,
        stop_m_o              => stop_m_s,
        stop_r_o              => stop_r_s,
        sel_dir_o             => sel_dir_s,
        nSpeed_cst_o          => nSpeed_cst_s,
        decr_cpt_encoche_o    => decr_cpt_encoche_s,
        decr_cpt_tour_o       => decr_cpt_tour_s,
        decr_cpt_disk_o       => decr_cpt_disk_s,
        load_cpt_encoche_o    => load_cpt_encoche_s,
        load_cpt_tour_o       => load_cpt_tour_s,
        load_cpt_disk_o       => load_cpt_disk_s,
        err_o                 => err_o
    );

    UT_inst : UT
    port map(
        clk_i                 => clk_i,
        rst_i                 => rst_i,
        nb_tour_i             => nb_tour_i,
        set_l_i               => set_l_s,
        set_m_i               => set_m_s,
        set_r_i               => set_r_s,
        stop_l_i              => stop_l_s,
        stop_m_i              => stop_m_s,
        stop_r_i              => stop_r_s,
        sel_dir_i             => sel_dir_s,
        nSpeed_cst_i          => nSpeed_cst_s,
        decr_cpt_encoche_i    => decr_cpt_encoche_s,
        decr_cpt_tour_i       => decr_cpt_tour_s,
        decr_cpt_disk_i       => decr_cpt_disk_s,
        load_cpt_encoche_i    => load_cpt_encoche_s,
        load_cpt_tour_i       => load_cpt_tour_s,
        load_cpt_disk_i       => load_cpt_disk_s,
        cpt_encoche_eq_zero_o => cpt_encoche_eq_zero_s,
        cpt_tour_eq_zero_o    => cpt_tour_eq_zero_s,
        cpt_disk_eq_m_o       => cpt_disk_eq_m_s,
        cpt_disk_eq_l_o       => cpt_disk_eq_l_s,
        cpt_disk_eq_r_o       => cpt_disk_eq_r_s,
        en_l_o                => en_l_s,
        en_m_o                => en_m_s,
        en_r_o                => en_r_s,
        dir_l_o               => dir_l_s,
        dir_m_o               => dir_m_s,
        dir_r_o               => dir_r_s,
        sel_speed_o           => sel_speed_s
    );

    --| Output affectation |---------------------------------------------------
    en_l_o      <= en_l_s;
    en_m_o      <= en_m_s;
    en_r_o      <= en_r_s;
    dir_l_o     <= dir_l_s;
    dir_m_o     <= dir_m_s;
    dir_r_o     <= dir_r_s;
    sel_speed_o <= sel_speed_s;

end struct;