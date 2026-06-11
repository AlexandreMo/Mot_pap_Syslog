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
entity cpt_vitesse is
    port(
        clk_i                 : in  std_logic;
        rst_i                 : in  std_logic;
        ld_vit_i              : in  std_logic;
		vitesse_i			  : in  std_logic_vector(1 downto 0);
        decr_cpt_disk_i       : in  std_logic;
        en_vit_i              : in  std_logic
        );
end cpt_vitesse;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture behave of cpt_vitesse is

    --| Constantes |-----------------------------------------------------------
	signal VIT_MAX : unsigned(1 downto 0) := "11";
	signal VIT_MIN : unsigned(1 downto 0) := "01";
	
    --| Signaux |--------------------------------------------------------------
	signal cpt_pres,cpt_pres : unsigned(1 downto 0);
begin
     -- Decodeur d'états futur
	cpt_next <= vitesse_i when ld_vit_i = '1' else -- Charg. de la vitesse
				cpt_next - 1 when decr_cpt_disk_i = '1' else -- Decr de la vitesse
				cpt_next + 1 when decr_cpt_disk_i = '0'; -- Incr de la vitesse 

    

    mem: process (clock_i, reset_i)
        begin
            if (reset_i = '1') then
            cpt_pres <= "00";
            elsif rising_edge(clock_i) then
            cpt_pres <= cpt_fut;
            end if;
        end process;
    


end behave;
