-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cpt_encoches.vhd
--
-- Description  : Compteur pour determiner le nombre d'encoches pour les 3 moteurs pas-a-pas
--
-- Auteur       : A.Moore
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
entity cpt_encoches is
    port(
        clk_i                 : in  std_logic;
        rst_i                 : in  std_logic;
        ld_enc_i              : in  std_logic;
        en_enc_i              : in  std_logic;
        encoches              :out std_logic_vector(6 downto 0)
    );
end cpt_encoches;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture behave of cpt_encoches is

    --| Constantes |-----------------------------------------------------------
    signal N_ENCOCHES : in std_logic_vector(3 downto 0) := "0101"; -- 5 encoches par tour
    signal cpt_pres, cpt_next : unsigned(6 downto 0) := (others => '0'); -- Compteur actuel et futur
    signal Fin_encoches : std_logic; -- Signal indiquant la fin du comptage des encoches
    signal N_fin_cpt : unsigned(4 downto 0);


begin
    -- Détermination du nombre de tours complets effectués
    N_tours = N_ENCOCHES << 2 - 1;
    -- Decodeur d'état futur
    cpt_next <= (others => '0') when ld_enc_i = 0 else -- Chargement du compteur
                cpt_pres + 1 when en_enc_i = '1' else -- Incrémentation du compteur
                cpt_pres; -- Maintien du compteur
    

    -- Processus de comptage
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            cpt_pres <= (others => '0');
        elsif rising_edge(clk_i) then
            cpt_pres <= cpt_next;
        end if;
    end process;
    -- Decodeur de sortie
    fin_encoches <= '1' when cpt_pres = unsigned(N_ENCOCHES) else '0'; -- Indique la fin du comptage des encoches
    cpt_encoches <= std_logic_vector(cpt_pres);

   




end behave;
