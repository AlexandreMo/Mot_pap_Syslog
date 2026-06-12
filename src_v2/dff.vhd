-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : dff_en.vhd
--
-- Description  : Bascule de synchronisation
-- 
-- Auteur       : Etienne Messerli
-- Date         : 11.01.2020
-- Version      : 1.1
-- 
-- Utilise      : Moteur pas pas 
-- 
--| Modifications |------------------------------------------------------------
-- Vers.  Qui   Date         Description
-- 1.0    EMI   22.10.2014   Solution correcte a) exercice dff_en
-- 1.1    MIM   11.01.2020   Move to vhdl-2008
-- 1.2    AME   26.05.2026   
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity dff_en is
    port(
        clk_i   : in  std_logic;
        reset_i : in  std_logic;
        D_i     : in  std_logic;
        en_i    : in  std_logic;
        Q_o     : out std_logic
        );
end dff_en;


architecture comport of dff_en is
    signal Q_fut, Q_pres : std_logic;

begin
    --Adaptation polarite

    --Si EN actif alors Q+ = D sinon Q+ = Q
    Q_fut <= D_i when en_i = '1' else
             Q_pres;

    process(all)
    begin
        if reset_i = '1' then
            Q_pres <= '0';
        elsif Rising_Edge(clk_i) then
            Q_pres <= Q_fut;
        end if;
    end process;

    Q_o <= Q_pres;

end comport;
