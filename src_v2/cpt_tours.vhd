-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cpt_vitesses.vhd
--
-- Description  : Compteur de vitesse pour la commande des 3 moteurs pas-a-pas
--
-- Auteur       : A.Moore
-- Date         : 21.05.2024
-- Version      : 1.0
--
-- Utilise dans : Labo moteur pas-à-pas (MSS cplx)
--
--| Modifications |------------------------------------------------------------
-- Version   Auteur      Date               Description
-- 0.0       AME         11.06.2026         Start-up
--
-------------------------------------------------------------------------------

--| Library |------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
-------------------------------------------------------------------------------

--| Entity |-------------------------------------------------------------------
entity cpt_tours is
    port(
        clk_i                 : in  std_logic;
        rst_i                 : in  std_logic;
        load_cpt_tour_i       : in std_logic;
	val_tours 	      : in std_logic_vector(2 downto 0);
        decr_cpt_tour_i       : in  std_logic;
        cpt_tour_eq_zero_o    : out std_logic
        );
end cpt_tours;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture behave of cpt_tours is

    --| Constantes |-----------------------------------------------------------
	signal N_ONE  : unsigned(2 downto 0) := (0 => '1', others => '0');
	signal N_ZERO : unsigned(2 downto 0) := (others => '0');
    --| Signaux |--------------------------------------------------------------
	signal cpt_next,cpt_pres : unsigned(2 downto 0);

begin

    -- Decodeur d'états futur
	cpt_next <= unsigned(val_tours) when load_cpt_tour_i = '1' else -- Charg. de nb de tours
				cpt_next - 1 when decr_cpt_tour_i = '1' else -- Decr du nb de tours
				cpt_next; -- Maintien

    mem: process (clk_i, rst_i)
        begin
            if (rst_i = '1') then
            cpt_pres <= "000";
            elsif rising_edge(clk_i) then
            cpt_pres <= cpt_next;
            end if;
        end process;
    -- Decodeur de sortie
    cpt_tour_eq_zero_o <= '1' when cpt_pres = N_ZERO else
						  '0';



end behave;
