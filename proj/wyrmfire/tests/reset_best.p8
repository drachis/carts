pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- reset_best.p8 : sets the saved high score back to zero.
-- run it with: pico8 -x tests/reset_best.p8
cartdata("drachis_wyrmfire")
printh("best was "..dget(0).."0, now 0")
dset(0,0)
extcmd("shutdown")
