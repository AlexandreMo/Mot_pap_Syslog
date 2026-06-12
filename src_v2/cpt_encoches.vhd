-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cpt_encoches.vhd
--
-- Description  : Compteur d'encoches
--
-- Auteur       : A.Moore
-- Date         : 21.05.2024
-- Version      : 1.1 (Corrected)
--
-- Utilise dans : Labo moteur pas-à-pas (MSS cplx)
--
--| Modifications |------------------------------------------------------------
-- Version   Auteur      Date               Description
-- 1.1       Copilot     12.06.2026         Changed signal to constant
--
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity cpt_encoches is
    port(
        clk_i                 : in  std_logic;
        rst_i                 : in  std_logic;
        load_cpt_encoche_i    : in  std_logic;
        decr_cpt_encoche_i    : in  std_logic;
        cpt_encoche_eq_zero_o : out std_logic
    );
end cpt_encoches;

architecture behave of cpt_encoches is

    --| Constantes |-----------------------------------------------------------
    constant MAX_ENCOCHES : unsigned(3 downto 0) := "0101";
    constant N_ZERO       : unsigned(3 downto 0) := (others => '0');

    --| Signaux |--------------------------------------------------------------
    signal cpt_next, cpt_pres : unsigned(3 downto 0);

begin

    -- Décodeur d'états futur
    cpt_next <= MAX_ENCOCHES when load_cpt_encoche_i = '1' else  -- Chargement MAX
                cpt_pres - 1 when decr_cpt_encoche_i = '1' else   -- Décrémentation
                cpt_pres;                                          -- Maintien

    -- Processus séquentiel
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            cpt_pres <= (others => '0');
        elsif rising_edge(clk_i) then
            cpt_pres <= cpt_next;
        end if;
    end process;

    -- Décodeur de sortie
    cpt_encoche_eq_zero_o <= '1' when cpt_pres = N_ZERO else '0';

end behave;