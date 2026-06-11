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
--
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
        ld_vit_i              : in std_logic;
        en_vit_i              : in std_logic;
        cpt_vit               : out std_logic_vector(1 downto 0)
    );
end cpt_vitesse;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture behave of cpt_vitesse is

    --| Constantes |-----------------------------------------------------------

    --| Signals |--------------------------------------------------------------
    
    signal cpt_fut, cpt_pres : unsigned(3 downto 0);


begin

    --Description concurrente du décodeur d'états futur--odre de priorite : charge, compte, maintien
    cpt_fut <= (others = '0') when (ld_vit_i = '1') else
                cpt_pres + 1 when (en_vit_i = '1') else --compte
                cpt_pres; --maintien

    mem: process (clock_i, reset_i)
        begin
            if (reset_i = '1') then
            cpt_pres <= "00";
            elsif rising_edge(clock_i) then
            cpt_pres <= cpt_fut;
            end if;
        end process;
    --Décodeur de sortie
    --Mise a jour de l'etat du compteur
    cpt_o <= std_logic_vector(cpt_pres);



end behave;
