-- sound.lua : sfx slot names + a muted play wrapper. the actual waveforms live
-- in the cart __sfx__ (authored in gen_gfx.py, reused from citysim1). callers
-- use snd(slot); a pause-menu item toggles sfx_mute.
-- api: snd(n); globals: snd_deny/doze/place/fire/boom, sfx_mute
snd_deny=0
snd_doze=1
snd_place=2
snd_fire=3
snd_boom=4
sfx_mute=false

function snd(n)
 if not sfx_mute then sfx(n) end
end
