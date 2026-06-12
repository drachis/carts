-- effects.lua: cosmetic particles

fx_list = {}

function init_fx()
  fx_list = {}
end

function add_fx(x, y, kind, txt)
  local wx = x * 8 + 4
  local wy = y * 8 + 4
  if kind == 1 then
    local dirs = {{-0.5,-0.5},{0.5,-0.5},{-0.5,0.5},{0.5,0.5}}
    for i = 1, 4 do
      local d = dirs[i]
      add(fx_list, {px=wx, py=wy, vx=d[1], vy=d[2], ttl=20, k=1, c=7+flr(rnd(2))*3})
    end
  elseif kind == 2 then
    for i = 1, 3 do
      add(fx_list, {px=wx+flr(rnd(5))-2, py=wy, vx=rnd(0.4)-0.2, vy=-0.3, ttl=25, k=2, c=5+flr(rnd(2))})
    end
  elseif kind == 3 then
    add(fx_list, {px=wx, py=wy, vx=0, vy=-0.5, ttl=30, k=3, txt=txt})
  end
end

function update_fx()
  local live = {}
  for p in all(fx_list) do
    p.px += p.vx
    p.py += p.vy
    p.ttl -= 1
    if p.ttl > 0 then
      add(live, p)
    end
  end
  fx_list = live
  if rnd() < 0.0008 then
    local has_plane = false
    for p in all(fx_list) do
      if p.k == 4 then
        has_plane = true
      end
    end
    if not has_plane then
      add(fx_list, {px=-16, py=8+flr(rnd(300)), vx=1.5, vy=0, ttl=400, k=4})
    end
  end
end

function draw_fx()
  for p in all(fx_list) do
    if p.k == 1 or p.k == 2 then
      pset(p.px, p.py, p.c)
    elseif p.k == 3 then
      local ox = p.px - #p.txt * 2
      print(p.txt, ox+1, p.py+1, 0)
      print(p.txt, ox, p.py, 10)
    elseif p.k == 4 then
      rectfill(p.px, p.py, p.px+4, p.py, 7)
      pset(p.px+1, p.py-1, 7)
      pset(p.px+1, p.py+1, 7)
      if p.ttl % 8 < 4 then
        pset(p.px+4, p.py, 8)
      end
    end
  end
end
