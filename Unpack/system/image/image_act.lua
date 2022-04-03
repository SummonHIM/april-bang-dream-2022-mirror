----------------------------------------
-- アクション制御
----------------------------------------
-- 実行
function image_act(id, p)
	if id and conf.effect == 1 and not getSkip() then
		local lp  = p.loop
		local act = p.act
		local idx = addImageID(id, "act")
		local ida = addImageID(id, "act2")
		if lp == -1 then idx = ida end
		local sw = {

			-- びっくり
			["びっくり"] = function(p)
				local y = mulpos(p.size or 15)
				local l = image_actloop(p, "harf")
				local t = p.time or 120
				local n = p.ease or "out"
				tween{ id=(idx), y=("0,"..-y), yoyo=(l), time=(t), ease=(n)}
			end,

			-- ジャンプ
			["ジャンプ"] = function(p)
				local y = mulpos(p.size or 20)
				local l = image_actloop(p, "harf")
				local t = p.time or 300
				local n = p.ease or "out"
				tween{ id=(idx), y=("0,"..-y), yoyo=(l), time=(t), ease=(n)}
			end,

			-- あくび
			["あくび"] = function(p)
				local y = mulpos(p.size or 12)
				local y2= math.floor(y / 0.66)
				local t = p.time or 800
				local n = p.ease or "inout"
				tween{ id=(idx), y=("0,"..-y..','..-y2..',0'), time=(t..','..(t*2)..','..t), ease=(n)}
			end,

			-- おじぎ
			["おじぎ"] = function(p)
				local y = mulpos(p.size or 20)
				local y2= math.floor(y * 0.95)
				local t = p.time or 600
				local t2= math.floor(t * 0.75)
				local n = p.ease or "inout"
				tween{ id=(idx), y=("0,"..y..','..y2..',0'), time=(t..','..t2..','..t2), ease=(n)}
			end,

			-- うなづく
			["うなづく"] = function(p)
				local y = mulpos(p.size or 10)
				local t = p.time or 120
				local t2= math.floor(t/2)
				local n = p.ease or "out"
				tween{ id=(idx), y=("0,"..y..',5,0'), time=(t..','..t2..','..t2), ease=(n)}
			end,

			-- うんうん
			["うんうん"] = function(p)
				local y = mulpos(p.size or 12)
				local t = p.time or 100
				local n = p.ease or "out"
				tween{ id=(idx), y=("0,"..y..',0,'..y..',0'), time=(t..','..t..','..t..','..t), ease=(n)}
			end,

			-- 縦揺れ(旧クエイク)
			["縦揺れ"] = function(p)
				local y = mulpos(p.size or 8)
				local y2= math.ceil(y * 0.75)
				local t = p.time or 50
				local n = p.ease or "none"
				tween{ id=(idx), y=('0,'..y..','..-y..','..y..','..-y..','..y2..','..-y2..','..y2..','..-y2..',0'), time=(t), ease=(n)}
			end,

			-- いいえ
			["いいえ"] = function(p)
				local x = mulpos(p.size or 12)
				local l = image_actloop(p, "harf")
				local t = p.time or 120
				local n = p.ease or "out"
				tag{"tweenset"}
				tween{ id=(idx), x=("0,"..-x)  , time=(t), ease=(n)}
				tween{ id=(idx), x=(-x..","..x), time=(t), ease=(n), yoyo=(l)}
				tween{ id=(idx), x=(-x..",0")  , time=(t), ease=(n)}
				tag{"/tweenset"}
			end,

			-- ドッキリ
			["ドッキリ"] = function(p)
				local z = p.size or 110
				local l = image_actloop(p, "harf")
				local t = p.time or 80
				local n = p.ease or "none"
				tween{ id=(idx), zoom=("100,"..z), yoyo=(l), time=(t), ease=(n)}
			end,

			-- ゆらゆら
			["ゆらゆら"] = function(p)
				local s = p.size or 2
				local l = image_actloop(p, "harf")
				local t = p.time or 1500
				local n = p.ease or "inout"
				tag{"tweenset"}
				tween{ id=(idx), rotate=("0,"..s)   , time=(t), ease=(n)}
				tween{ id=(idx), rotate=(s..","..-s), time=(t), ease=(n), yoyo=(l)}
				tween{ id=(idx), rotate=(s..",0")   , time=(t), ease=(n)}
				tag{"/tweenset"}
			end,

			-- 浮遊
			["浮遊"] = function(p)
				local s = p.size or 10
				local l = image_actloop(p, "harf")
				local t = p.time or 2000
				local n = p.ease or "inout"
				tag{"tweenset"}
				tween{ id=(idx), y=("0,"..-s)  , time=(t), ease=(n)}
				tween{ id=(idx), y=(-s..","..s), time=(t), ease=(n), yoyo=(l)}
				tween{ id=(idx), y=(-s..",0")  , time=(t), ease=(n)}
				tag{"/tweenset"}
			end,

			-- ウゴウゴ
			["ウゴウゴ"] = function(p)
				local s1 = p.s1   or 95
				local s2 = p.s2   or 105
				local l  = image_actloop(p, "harf")
				local t  = p.time or 100
				local n  = p.ease or "none"
				tag{"tweenset"}
				tween{ id=(idx), xscale=("100,"..s1) , time=(t), ease=(n)}
				tween{ id=(idx), xscale=(s1..","..s2), time=(t), ease=(n), yoyo=(l)}
				tween{ id=(idx), xscale=(s1..",100") , time=(t), ease=(n)}
				tag{"/tweenset"}
				tag{"tweenset"}
				tween{ id=(idx), yscale=("100,"..s2) , time=(t), ease=(n)}
				tween{ id=(idx), yscale=(s2..","..s1), time=(t), ease=(n), yoyo=(l)}
				tween{ id=(idx), yscale=(s2..",100") , time=(t), ease=(n)}
				tag{"/tweenset"}
			end,

			quake = function(p)
				local t = tcopy(p)
				t.id = idx
				quake(t)
			end,

			----------------------------------------
			-- ノラととアクション
			du = function(p)
				local sz = mulpos(p.size or 20)
				local lp = image_actloop(p)
				local tm = math.floor((p.time or 500) / 2)
				tag{"tweenset"}
				for i=1, lp do
					tween{ id=(idx), y=("0,"..sz), time=(tm), ease="out"}
					tween{ id=(idx), y=(sz..",0"), time=(tm), ease="in"}
				end
				tag{"/tweenset"}
			end,

			ud = function(p)
				local sz = -mulpos(p.size or 20)
				local lp = image_actloop(p)
				local tm = math.floor((p.time or 500) / 2)
				tag{"tweenset"}
				for i=1, lp do
					tween{ id=(idx), y=("0,"..sz), time=(tm), ease="out"}
					tween{ id=(idx), y=(sz..",0"), time=(tm), ease="in"}
				end
				tag{"/tweenset"}
			end,

			rl = function(p)
				local sz = mulpos(p.size or 20)
				local lp = image_actloop(p)
				local tm = math.floor((p.time or 500) / 2)
				tag{"tweenset"}
				for i=1, lp do
					tween{ id=(idx), x=("0,"..sz), time=(tm), ease="out"}
					tween{ id=(idx), x=(sz..",0"), time=(tm), ease="in"}
				end
				tag{"/tweenset"}
			end,

			lr = function(p)
				local sz = -mulpos(p.size or 20)
				local lp = image_actloop(p)
				local tm = math.floor((p.time or 500) / 2)
				tag{"tweenset"}
				for i=1, lp do
					tween{ id=(idx), x=("0,"..sz), time=(tm), ease="out"}
					tween{ id=(idx), x=(sz..",0"), time=(tm), ease="in"}
				end
				tag{"/tweenset"}
			end,

			dud = function(p)
				local sz = mulpos(p.size or 20)
				local lp = image_actloop(p)
				local t1 = math.floor((p.time or 500) / 4)
				local t2 = t1 * 2
				tag{"tweenset"}
				tween{ id=(idx), y=("0,"..sz) , time=(t1), ease="out"}
				tween{ id=(idx), y=(sz..","..-sz) , time=(t2), ease="out"}
				if lp>1 then
					for i=1, lp-1 do
						tween{ id=(idx), y=(-sz..","..sz), time=(t2), ease="out", yoyo="1"}
					end
				end
				tween{ id=(idx), y=(-sz..",0"), time=(t1), ease="out"}
				tag{"/tweenset"}
			end,

			rlr = function(p)
				local sz = mulpos(p.size or 20)
				local lp = image_actloop(p)
				local t1 = math.floor((p.time or 500) / 4)
				local t2 = t1 * 2
				tag{"tweenset"}
				tween{ id=(idx), x=("0,"..sz) , time=(t1), ease="out"}
				tween{ id=(idx), x=(sz..","..-sz) , time=(t2), ease="out"}
				if lp>1 then
					for i=1, lp-1 do
						tween{ id=(idx), x=(-sz..","..sz), time=(t2), ease="out", yoyo="1"}
					end
				end
				tween{ id=(idx), x=(-sz..",0"), time=(t1), ease="out"}
				tag{"/tweenset"}
			end,

			----------------------------------------
			-- fgicon
			icon = function(p)
				image_fgicon(id, p)
			end,

			----------------------------------------
			["停止"] = function(p)
				tag{"lytweendel", id=(idx)}		-- act停止
				tag{"lytweendel", id=(ida)}		-- loop act停止
				image_iconstop(id, p)			-- icon停止
			end,

			["stopact"] = function(p)
				tag{"lytweendel", id=(idx)}		-- act停止
				tag{"lytweendel", id=(ida)}		-- loop act停止
			end,

			["stopicon"] = function(p)
				image_iconstop(id, p)			-- icon停止
			end,
		}

		-- emote
		local nm = "user_fgaction"
		if emote and p.emote == 1 then
			emote.action(p)
		elseif sw[act] then
			if not flg.act then flg.act = {} end
			if not flg.act[id] and act ~= "icon" and act ~= "stopicon" then
				tag{"lytweendel", id=(idx)}
				flg.act[id] = true
			end
			sw[act](p)
		elseif _G[nm] then
			_G[nm](p)
		end
	end
end
----------------------------------------
-- loop情報変換
function image_actloop(p, md)
	local r = p.loop or 1
	if r < 0 then
		r = -1
	elseif r then
		if md == "harf" then
			r = r * 2 - 1
		end
	end
	return r
end
----------------------------------------
-- 立ち絵アイコン
function image_fgicon(id, p)
	local nm = p.icon or ""

	----------------------------------------
	-- tween
	local sw = {
		x = function(id, v)		tween{ id=(id), x=(v.x)			 , time=(v.time), delay=(v.delay), yoyo=(v.yoyo), loop=(v.loop), ease=(v.ease) } end,
		y = function(id, v)		tween{ id=(id), y=(v.y)			 , time=(v.time), delay=(v.delay), yoyo=(v.yoyo), loop=(v.loop), ease=(v.ease) } end,
		zoom = function(id, v)	tween{ id=(id), zoom=(v.zoom)    , time=(v.time), delay=(v.delay), yoyo=(v.yoyo), loop=(v.loop), ease=(v.ease) } end,
		alpha = function(id, v)	tween{ id=(id), alpha=(v.alpha)  , time=(v.time), delay=(v.delay), yoyo=(v.yoyo), loop=(v.loop), ease=(v.ease) } end,
		rotate = function(id, v)tween{ id=(id), rotate=(v.rotate), time=(v.time), delay=(v.delay), yoyo=(v.yoyo), loop=(v.loop), ease=(v.ease) } end,

		-- 横連結
		clipw = function(id, v, fl)
			local m = v.max
			local w = v.w
			local h = v.h
			local t = v.wait or 100
			local l = v.loop or -1
			local c = ",0,"..w..","..h
			tag{"anime",	id=(id), mode="init", file=(fl), clip=("0"..c), loop=(l)}
			for i=1, m-1 do
				tag{"anime",id=(id), mode="add",  file=(fl), clip=((i*w)..c), time=(i*t)}
			end
			tag{"anime",	id=(id), mode="end",  time=(m * t)}
		end,

		-- 縦連結
		cliph = function(id, v)
			local m = v.max
			local w = v.w
			local h = v.h
			local t = v.wait or 100
			local l = v.loop or -1
			local c = ","..w..","..h
			tag{"anime",	id=(id), mode="init", file=(fl), clip=("0,0"..c), loop=(l)}
			for i=1, m-1 do
				tag{"anime",id=(id), mode="add",  file=(fl), clip=("0,"..(i*h)..c), time=(i*t)}
			end
			tag{"anime",	id=(id), mode="end",  time=(m * t)}
		end,

		-- 連結
		clip = function(id, v)
			local m = v.max
			local t = v.wait or 100
			local l = v.loop or -1
			tag{"anime",	id=(id), mode="init", file=(fl), clip=(v.clip00), loop=(l)}
			for i=1, m-1 do
				local nm = "clip"..string.format("%02d", i)
				tag{"anime",id=(id), mode="add",  file=(fl), clip=(v[nm]), time=(i*t)}
			end
			tag{"anime",	id=(id), mode="end",  time=(m * t)}
		end,
	}

	----------------------------------------
	-- iptが無いと動作しない
	local px = ":icon/"..nm..".ipt"
	if isFile(px) then
		e:include(px)

		-- frame check
		local ch = p.ch
		local f  = scr.img.fgf[ch]
		local xx = 0
		if f then
			id  = f.id..'.fgf.fg'
			xx  = f.fx - game.centerx
		end

		-- 計算
		local ix = p.back and addImageID(id, 'act')..".-1" or addImageID(id, 'act')..".ic"
		local lp = image_actloop(p)
		local b  = ipt.base
		local x  = game.ax + b.x + (p.x or 0)
		local y  = game.ay + b.y + (p.y or 0)
		local z  = b.zoom
		tag{"lytweendel", id=(ix)}

		-- 表示
		local fl = ":icon/"..(b[1] or nm)
		local an = b.anime
		if an then
			if sw[an] then sw[an](ix..".0", b, fl) end
		else
			lyc2{ id=(ix..".0"), file=(fl), anchorx=(b.ax), anchory=(b.ay) }
		end
		tag{"lyprop", id=(ix), left=(x + xx), top=(y), xscale=(z), yscale=(z)}

		-- 無限
		if lp == -1 then
			if not scr.icon then scr.icon = {} end
			local no = tn(p.id)
			scr.icon[no] = ix

		-- 消去
		else
			local dl = b.time or 500
			local fa = b.fade or 250
			tag{"lytween", id=(ix), param="alpha", from="255", to="0", time=(fa), delay=(dl), delete="1"}
		end

		-- tween
		for i=1, 20 do
			local v = ipt[i]
			if v then
				local ac = v[1]
				if sw[ac] then sw[ac](ix..".0", v) end
			end
		end
		flip()
	end
end
----------------------------------------
-- icon停止
function image_iconstop(id, p)
	if not scr.icon then scr.icon = {} end
	local no = tn(p.id)
	local ic = scr.icon[no]
	if ic then
		tag{"lytweendel", id=(ic..".0")}
		lydel2(ic)
		flip()
		scr.icon[no] = nil
	end
end
----------------------------------------
-- 演出
----------------------------------------
-- quake
function tag_quake(p)
	local sync = tn(p.sync or 0)
	if sync == 1 then	quake(p)		-- すぐに実行する
	else image_store('quake', p) end	-- スタック
end
----------------------------------------
-- quake
function quake(p)
	if not scr.quake then scr.quake = {} end
	local mode = p.mode or 'gr'
	local id   = p.id   or quake_idtable[mode] or scr.quake[mode]
	if mode == 'bg' or mode == 'cg' then
		local v = scr.img.bg
		local n = tn(p.id or 0) + 1
		if v[n] then
			id = addImageID(v[n].idx, "act")
		else
			message("通知", mode, "id:", n, "は設置されていない画像です")
			return
		end
	elseif mode == 'st' then
		local ch = p.id
		local v  = scr.img.fg
		if ch and v[ch] then
			id = addImageID(v[ch], "act")
		else
			message("通知", mode, "id:", n, "は設置されていない画像です")
			return
		end
	end
	if not id then return end

	tag{"lytweendel", id=(id)}

	----------------------------------------
	-- 停止
	if tn(p.stop) == 1 then
		if scr.quake[mode] then
			tween{ id=(id), x="1,0", time="0"}
			tween{ id=(id), y="1,0", time="0"}
			scr.quake[mode] = nil
		end

	----------------------------------------
	-- 
	else
		local q = init.quake
		local size = mulpos(p.size or q and q[1] or 6)	-- 揺れサイズ
		local w    = mulpos(p.w) or size				-- 揺れサイズ w
		local h    = mulpos(p.h) or size				-- 揺れサイズ h
		local time = tn(p.time or q and q[2] or 60)		-- 揺れる時間
		local cnt  = tn(p.loop or q and q[3] or 10)		-- 揺れる回数
		local ease = p.ease or 'inout'
		local dir  = p.dir  or 'r'
		local fr   = math.ceil(time / 4)
		local mn   = math.ceil(time / 2)

		if cnt ~= -1 and getSkip() then return end

		local sw = {

		----------------------------------------
		-- ランダム∞
		r0 = function()
			if w then
				e:tag{"tweenset"}
				tween{ id=(id), x=("0,"..w)   , time=(fr*2), ease=(ease)}
				tween{ id=(id), x=(w..","..-w), time=(mn*2), ease=(ease), yoyo=(cnt)}
				tween{ id=(id), x=(-w..",0")  , time=(fr*2), ease=(ease)}
				e:tag{"/tweenset"}
			end
			if h then
				e:tag{"tweenset"}
				tween{ id=(id), y=("0,"..h)   , time=(fr), ease=(ease)}
				tween{ id=(id), y=(h..","..-h), time=(mn), ease=(ease), yoyo=(cnt*2)}
				tween{ id=(id), y=(-h..",0")  , time=(fr), ease=(ease)}
				e:tag{"/tweenset"}
			end
		end,

		----------------------------------------
		-- ランダム８
		r1 = function()
			if w then
				e:tag{"tweenset"}
				tween{ id=(id), x=("0,"..w)   , time=(fr), ease=(ease)}
				tween{ id=(id), x=(w..","..-w), time=(mn), ease=(ease), yoyo=(cnt*2)}
				tween{ id=(id), x=(-w..",0")  , time=(fr), ease=(ease)}
				e:tag{"/tweenset"}
			end
			if h then
				e:tag{"tweenset"}
				tween{ id=(id), y=("0,"..h)   , time=(fr*2), ease=(ease)}
				tween{ id=(id), y=(h..","..-h), time=(mn*2), ease=(ease), yoyo=(cnt)}
				tween{ id=(id), y=(-h..",0")  , time=(fr*2), ease=(ease)}
				e:tag{"/tweenset"}
			end
		end,

		----------------------------------------
		-- 2 : 往復＋逆往復
		r2 = function()
			if w then
				e:tag{"tweenset"}
				tween{ id=(id), x=("0,"..w)   , time=(fr), ease=(ease)}
				tween{ id=(id), x=(w..","..-w), time=(mn), ease=(ease), yoyo=(cnt)}
				tween{ id=(id), x=(-w..",0")  , time=(fr), ease=(ease)}
				e:tag{"/tweenset"}
			end
			if h then
				e:tag{"tweenset"}
				tween{ id=(id), y=("0,"..h)   , time=(fr), ease=(ease)}
				tween{ id=(id), y=(h..","..-h), time=(mn), ease=(ease), yoyo=(cnt)}
				tween{ id=(id), y=(-h..",0")  , time=(fr), ease=(ease)}
				e:tag{"/tweenset"}
			end
		end,

		----------------------------------------
		-- 3 : 往復
		r3 = function()
			if w then
				tween{ id=(id), x=("0,"..w), time=(mn), ease=(ease), yoyo=(cnt)}
			end
			if h then
				tween{ id=(id), y=("0,"..h), time=(mn), ease=(ease), yoyo=(cnt)}
			end
		end,

		----------------------------------------
		-- 4 : 右下→戻る→左下→戻る
		r4 = function()
			if w then
				e:tag{"tweenset"}
				tween{ id=(id), x=("0,"..w)   , time=(fr), ease=(ease)}
				tween{ id=(id), x=(w..","..-w), time=(mn), ease=(ease), yoyo=(cnt)}
				tween{ id=(id), x=(-w..",0")  , time=(fr), ease=(ease)}
				e:tag{"/tweenset"}
			end
			if h then
				tween{ id=(id), y=("0,"..h), time=(fr), ease=(ease), yoyo=(cnt)}
			end
		end,
		}

		if sw[dir] then sw[dir]()

		-- 無限ループ
		elseif time == -1 then
			if dir == 'r' or dir == 'v' then tween{ id=(id), x=(size..','..-size), time=(80), yoyo="-1", ease=(p.ease)} end
			if dir == 'r' or dir == 'h' then tween{ id=(id), y=(size..','..-size), time=(70), yoyo="-1", ease=(p.ease)} end
			scr.quake[mode] = id

		-- 時間指定ゆれ / 現在スキップ中かeffect offならば実行しない
		elseif not getSkip(true) then
			local s = size
			local r = -s
			local r2= -s
			local c = 1
			for i=1, cnt do
				local n = math.ceil(s * c)
				if n == 0 then n = 1 end
				r = r..','..n
				r2= r2..','..n..','..-n
				c = c * -1
				s = s * 0.85
			end

			local rx = r..',0'
			local r2 = r2..',0'
				if dir == 'v' then tween{ id=(id), x=(rx), time=(math.ceil(time/2)..','..time), ease=(ease)}
			elseif dir == 'h' then tween{ id=(id), y=(rx), time=(math.ceil(time/2)..','..time), ease=(ease)}
			elseif dir == 'r' then
				tween{ id=(id), x=(r2), time=(math.ceil(time/4)..','..math.ceil(time/2)), ease=(ease)}
				tween{ id=(id), y=(rx), time=(math.ceil(time/2)..','..time), ease=(ease)}
			elseif dir == 'r2' then
				tween{ id=(id), x=(rx), time=(math.ceil(time/4)..','..math.ceil(time/2)), ease=(ease)}
				tween{ id=(id), y=(r2), time=(math.ceil(time/2)..','..time), ease=(ease)}
			end
		end
	end
end
----------------------------------------
-- flash
function tag_flash(p)
	-- 現在スキップ中かeffect offならば実行しない
	if getSkip(true) then return end

	local sync = tn(p.sync or 0)
	if sync == 1 then flash(p)			-- すぐに実行する
	else image_store('flash', p) end	-- スタック
end
----------------------------------------
-- flash
function flash(p)
	local id = getImageID("fl")
	local md = p.mode or "haru"
	local cl = p.color or "0xffffff"
	local st = p.style
	local sw = {
		-- 停止
		stop = function(p)
			tag{"lytweendel", id=(id)}
			lydel2(id)
		end,

		-- harukaze flash
		haru = function(p)
			local tm = math.ceil((p.time or 100) / 2)
			local al = p.alpha or 255;
			local lp = p.loop or p.count or 1 if lp > 1 then lp = lp * 2 - 1 end
			lyc2{ id=(id), width=(game.width), height=(game.height), color=(cl), layermode=(st)}
			tween{ id=(id), alpha="0,"..al, yoyo=(lp), time=(tm), delete="1" }
			flip()
		end,
	}
	if sw[md] then sw[md](p) end
end
----------------------------------------
