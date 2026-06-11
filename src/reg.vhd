-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : reg.vhd
--
-- Description  : Registre de memorisation du nombre de tours 
--
-- Auteur       : A.Moore
-- Date         : 21.05.2024
-- Version      : 1.0
--
-- Utilise dans : Labo moteur pas-à-pas (MSS cplx)
--
--| Modifications |------------------------------------------------------------
-- Version   Auteur      Date               Description
-- 0.0       AME         11.06.2026         Completion of file
--
-------------------------------------------------------------------------------

--| Library |------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
-------------------------------------------------------------------------------

--| Entity |-------------------------------------------------------------------
    entity srg4 is
    port(
        clock_i : in std_logic; --horloge registre
        nReset_i : in std_logic; --reset asynchrone
        ld_i : in std_logic; 
        en_i : in std_logic; 
        val_i : in std_logic_vector(3 downto 0);
        reg_o : out std_logic_vector(3 downto 0)
    ); --sorties du registre
    end srg4;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture behave of srg4 is

signal reset_s, load_s : std_logic;
signal reg_fut, reg_pres : std_logic_vector(2 downto 0);


begin
    reset_s <= not nReset_i; --Adaptation polarite
    load_s <= not nLoad_i; --Adaptation polarite
    --Decodeur d'etat futur (combinatoire)
    reg_fut <= val_i when (load_s = '1') else --chargement
               reg_pres

    mem: process (clock_i, reset_s)
        begin
            if (reset_s = '1') then
            reg_pres <= "000";
            elsif rising_edge(clock_i) then
            reg_pres <= reg_fut;
            end if;
        end process;
    --Mise a jours de l'etat du registre
    reg_o <= reg_pres;
end behave;
