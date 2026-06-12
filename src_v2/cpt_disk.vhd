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
entity cpt_disk is
    port(
        clk_i                 : in  std_logic;
        rst_i                 : in  std_logic;
        load_cpt_disk_i       : in  std_logic;
        incr_cpt_disk_i       : in  std_logic;
        cpt_speed_o           : out std_logic_vector(1 downto 0);
        cpt_disk_eq_m_o       : out std_logic;
        cpt_disk_eq_l_o       : out std_logic;
        cpt_disk_eq_r_o       : out std_logic
        );
end cpt_disk;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture behave of cpt_disk is

    --| Constantes |-----------------------------------------------------------
	signal DISK_M : unsigned(1 downto 0) := "00";
	signal DISK_L : unsigned(1 downto 0) := "01";
    signal DISK_R : unsigned(1 downto 0) := "10";
    
    
    --| Signaux |--------------------------------------------------------------
	signal cpt_next,cpt_pres : unsigned(1 downto 0);
begin
     -- Decodeur d'états futur
	cpt_next <= DISK_M when load_cpt_disk_i = '1' else -- Charg. de la vitesse 
		    cpt_next + 1 when incr_cpt_disk_i = '1'else 
                    cpt_next; -- Incr de la vitesse 

    mem: process (clk_i, rst_i)
        begin
            if (rst_i = '1') then
            cpt_pres <= DISK_M;
            elsif rising_edge(rst_i) then
            cpt_pres <= cpt_next;
            end if;
        end process;
    -- Sortie
    cpt_speed_o <= std_logic_vector(cpt_pres);
    -- Décodeur de sortie
    cpt_disk_eq_m_o <= '1' when cpt_pres = "00" else '0';
    cpt_disk_eq_l_o <= '1' when cpt_pres = "01" else '0';
    cpt_disk_eq_r_o <= '1' when cpt_pres = "10" else '0';

end behave;
