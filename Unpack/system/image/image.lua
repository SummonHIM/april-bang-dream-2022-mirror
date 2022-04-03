----------------------------------------
-- image共通
----------------------------------------
-- 全消去
function tags.alldelete(e, p) alldelete(p) return 1 end
function alldelete(p)
	allsound_stop(p)
	tag{"lydel", id="1"}
	tag{"lydel", id="400"}
	tag{"lydel", id="500"}
	tag{"lydel", id="600"}
	reset_bg()
	menu_playtime()
	uitrans(p)
end
----------------------------------------
-- ID取得
function getImageID(nm, p)
	local r = '1.0.bx.by.bs'
	if p then
		local id = p.id or 0
		local lv = p.lv or nm == 'fg' and 5 or 0
		r = r.."."..lv..'.'..nm..'.'..id
	elseif nm == "base" then
	elseif nm == "blurx" then r = '1.0.bx'
	elseif nm == "blury" then r = '1.0.bx.by'
	else
		r = r.."."..nm
	end

	-- frame処理
	if p and p.cgc then
		local bx = 1 + p.cgc
		local v  = scr.img.bg[bx]
		if v then r = v.idx..'.'..lv..'.'..nm..'.'..id end
	end
	return r
end
----------------------------------------
-- addid
function addImageID(id, nm)
	local r = id
	local tbl = {
		tone = ".t",
		blury= ".t.y",
		blurx= ".t.y.x",
		pos  = ".t.y.x.p",
		move = ".t.y.x.p.m",
		act  = ".t.y.x.p.m.a",
		act2 = ".t.y.x.p.m.a.a",
		base = ".t.y.x.p.m.a.a.b",
	}
	if tbl[nm] then r = r..tbl[nm] end
	return r
end
----------------------------------------
-- ハード倍率
function mulpos(p)
	local r = p
	local n = game.scale
	if n ~= 1 then
		if type(r) == "string" then
			if r:find(",") then
				local a = explode(",", r)
				for i, v in ipairs(a) do
					local c = math.floor(v * n)
					if i == 1 then	r = c
					else			r = r..","..c end
				end
			elseif tn(r) then
				r = math.floor(p * n)
			else
				message("警告", r, " は使用できない倍率パラメータです")
			end
		elseif r then
			r = math.floor(p * n)
		end
	end
	return r
end
----------------------------------------
-- anyチェック
function anyCheck(p)
	local f = p.file
	if f and p.any and not p.movie then
		local n = 1 + (cond(p.any) or 0)
		local a = explode(",", f)
		local m = #a
		if n <= 0 then n = 1 elseif n > m then n = m end
		f = a[n]
	end

	-- 多言語
	local v = csv.imglang or {}
	if v[f] then
		local ln = get_language(true)
		local s  = init.langadd[ln]
		if s then f = f..s end
	end
	return f
end
----------------------------------------
-- 
----------------------------------------
-- ファイル読み込み／cacheでも使えるようにする
function readImage(id, p, tone)
	local idx  = not id and p.ix or addImageID(id, "base")
	local path = p.path or ":bg/"
	local file = anyCheck(p) or "black"
	local pos  = true
	local px   = path..file
	local mv   = tn(p.movie) or 0
	local mvfl = mv >= 1 and true
	local anef = conf.effect or 1
	if id then lydel2(id) end

	--------------------------------
	-- color
	if p.color then
		local g  = game
		local cw = mulpos(p.cw) or g.width
		local ch = mulpos(p.ch) or g.height
		lyc2{ id=(idx..'.0'), width=(cw), height=(ch), color=(p.color) }

		-- pos
		local ax = math.floor(cw / 2)
		local ay = math.floor(ch / 2)
		tag{"lyprop", id=(addImageID(id, 'move')), anchorx=(ax), anchory=(ay)}
		tag{"lyprop", id=(addImageID(id, 'act' )), anchorx=(ax), anchory=(ay)}
		if p.pmode ~= 1 then
		tag{"lyprop", id=(id) , left=(g.ax - ax), top=(g.ay - ay)}
		end

	--------------------------------
	-- ogv
	elseif mvfl then
		local px = path..file..".ogv"
		local lp = p.loop or p.movieloop or 0
		local ax = mulpos(p.ax) or game.ax
		local ay = mulpos(p.ay) or game.ay

		-- movie=2の処理
		local i  = nil
		local sy = p.sync
		if mv == 2 then
			sy = nil
			i  = 0		
		end
		tag{"video" , id=(idx), file=(px), loop=(lp)}
		tag{"lyprop", id=(addImageID(id, 'move')), anchorx=(ax), anchory=(ay)}
		tag{"lyprop", id=(addImageID(id, 'act' )), anchorx=(ax), anchory=(ay)}
		if id then tag{"lyprop", id=(id ), visible=(anef)} end

		-- sync
		if sy and anef == 1 and not getSkip() then eqtag{"wait", video=(idx), input=(i)} end

	--------------------------------
	-- ipt
	elseif e:isFileExists(px..'.ipt') then
		e:include(px..'.ipt')

		local sw = {

		--------------------------------
		-- 2048px分割
		cut = function()
			for i, v in ipairs(ipt) do
				lyc2{ id=(idx.."."..v.id), file=(path..v.file), x=(v.x), y=(v.y) }
			end
		end,

		--------------------------------
		-- 差分
		diff = function()
			lyc2{ id=(idx..".0"), file=(path..ipt.base[1]) }
			for i, v in ipairs(ipt) do
				lyc2{ id=(idx.."."..v.id), file=(path..v.file), x=(v.x), y=(v.y) }
			end
			e:tag{"lyprop", id=(idx), intermediate_render="1"}
		end,

		--------------------------------
		-- アニメーション
		anime90 = function(p)
			local file = p.path..p.file
			if tone == 'cache' then
				lyc2{ id=(idb..0), file=(file) }
				flag = nil
			else
				local loop = p.amode == 1 and -1 or 0
				local max  = ipt.max
				local time = 0
				local at  = p.atime
				local ida = idb..0
				for i=1, max do
					if i == 1 then
						tag{"anime", id=(ida), mode="init", file=(file), clip=(ipt[i]), loop=(loop)}
					else
						time = time + at
						tag{"anime", id=(ida), mode="add", file=(file), clip=(ipt[i]), time=(time)}
					end
				end
				time = time + at
				tag{"anime" , id=(ida), mode="end", time=(time)}
				tag{"lyprop", id=(idz), left=(game.ax), top=(game.ay)}
				tag{"lyprop", id=(id ), visible=(anef)}
			end
		end,

		--------------------------------
		-- 連結アニメーション
		anime = function(p)
			local v = ipt.base
			local max = v.max
			if tone == 'cache' then
				local file = p.path..ipt[1][1]
				flag = nil
			else
				local loop = v.loop or -1
				local time = 0
				local at  = v.time
				for i=1, max do
					local t = ipt[i]
					local file = p.path..t[1]
					if i == 1 then
						tag{"anime", id=(id), mode="init", file=(file), clip=(t.clip), loop=(loop)}
					else
						time = time + at
						tag{"anime", id=(id), mode="add", file=(file), clip=(t.clip), time=(time)}
					end
				end
				time = time + at
				tag{"anime" , id=(id), mode="end", time=(time)}
				tag{"lyprop", id=(id), left=(v.x), top=(v.y), visible=(anef)}
				if tone == 'system' then
					tag{"lyprop", id=(id), left=(v.x), top=(v.y), anchorx=(v.ax), anchory=(v.ay)}
					flag = nil
				end
			end
		end,

		--------------------------------
		-- 全画面アニメーション
		anime_full = function(p)
			local v    = ipt.base
			local max  = v.max
			local loop = v.loop or -1
			local time = 0
			local at   = v.time
			local ida  = idx..".0"
			for i=1, max do
				local file = p.path..ipt[i][1]
				if i == 1 then
					tag{"anime", id=(ida), mode="init", file=(file), loop=(loop)}
				else
					time = time + at
					tag{"anime", id=(ida), mode="add", file=(file), time=(time)}
				end
			end
			time = time + at
			tag{"anime", id=(ida), mode="end", time=(time)}
			tag{"lyprop", id=(id), visible=(anef)}
--			tag{"lyprop", id=(idx), left=(v.ax), top=(v.ay)}
		end,

		--------------------------------
		-- 特殊アニメーション
		exani = function(p)
			local fl = ipt.lua
			if fl and _G[fl] then _G[fl](idx, p) end
		end,
		}

		local md = ipt.mode
		if md and sw[md] then
			sw[md](p)

			-- 設定
			local v  = ipt.base
			local z  = v.zoom
			local ax = mulpos(p.ax) or v.ax
			local ay = mulpos(p.ay) or v.ay
			tag{"lyprop", id=(addImageID(id, 'pos')) , left=(v.x), top=(v.y) }
			tag{"lyprop", id=(addImageID(id, 'move')), anchorx=(ax), anchory=(ay)}
			tag{"lyprop", id=(addImageID(id, 'act' )), anchorx=(ax), anchory=(ay)}
			if z then tag{"lyprop", id=(idx) , xscale=(z), yscale=(z), anchorx=(v.ax), anchory=(v.ay) } end
			if p.pmode ~= 1 then
			tag{"lyprop", id=(id) , left=(x), top=(y)}
			end
		end

	--------------------------------
	-- 画像直
	else
		local bx = p.bx and mulpos(p.bx)
		local by = p.by and mulpos(p.by)

		-- black / white
		if init[file] then px = init[file] end

		-- clip
		local cl = nil
		if p.exclip then
			local ax = explode(",", p.exclip)
			local cx = mulpos(ax[1])
			local cy = mulpos(ax[2])
			local cw = mulpos(ax[3])
			local ch = mulpos(ax[4])
			cl = cx..","..cy..","..cw..","..ch
		end
		lyc2{ id=(idx..'.0'), file=(px), clip=(cl) }

		if id then
			local idp = addImageID(id, 'pos')
			tag{"lyprop", id=(idp), left=(bx), top=(by) }

			local v = csv.cgsize and csv.cgsize[file] or {}
			local x = v.wx
			local y = v.wy or 0
			local ax = p.ax or v.ax --	ax = ax and mulpos(ax) or game.centerx
			local ay = p.ay or v.ay --	ay = ay and mulpos(ay) or game.centery

			-- 中心点を自動取得
			if not ax and not ay and init.game_layerinfo == 'on' then
				e:tag{"var", name="t.ly", system="get_layer_info", id=(idb..'0'), style="map"}
				local lyax = math.floor(e:var("t.ly.width") / 2)
				local lyay = math.floor(e:var("t.ly.height") / 2)
				ax = ax and mulpos(ax) or lyax or game.centerx
				ay = ay and mulpos(ay) or lyay or game.centery

			-- 通常モード
			else
				ax = ax and mulpos(ax) or game.centerx
				ay = ay and mulpos(ay) or game.centery
			end
			tag{"lyprop", id=(addImageID(id, 'move')), anchorx=(ax), anchory=(ay)}
			tag{"lyprop", id=(addImageID(id, 'act' )), anchorx=(ax), anchory=(ay)}
			if p.pmode ~= 1 then
			tag{"lyprop", id=(id) , left=(x), top=(y)}
			end
		end
	end

	-- dir
	local d = p.dir
	if d and d ~= "none"  then
		local rx = (d == "rxy" or d == "rx") and 1
		local ry = (d == "rxy" or d == "ry") and 1
		tag{"lyprop", id=(id) , reversex=(rx), reversey=(ry), anchorx=(game.centerx), anchory=(game.centery)}
	end

	-- mask
	local m = p.lymask
	if m then tag{"lyprop", id=(id), intermediate_render="1", intermediate_render_mask=(":mask/"..m)} end

	-- filter
--	if not p.notone then setColortone(id) end
	shader_lyprop(id, p)

	-- blur
--	local nm = p.id and p.id > 0 and "alpha"
--	setBlur(id, nm, p)

	-- CG鑑賞拡張登録
	cgset(p)
end
----------------------------------------
-- 色調
----------------------------------------
-- 色調
function colortone(p)
	if not scr.tone then scr.tone = {} end
	local mode = p.style or "reset"
	scr.tone.mode = mode
	scr.tone.p    = p

	message("通知", mode, "を適用します")

	-- trans
	if p.sync == 1 then
		local tm = p.time or 0
		shader_trans(p)
		trans{ time=(tm) }
	end
end
----------------------------------------
-- 色調反映
--[[
function setColortone(id, p)
	local t = p or scr.tone
	if t then
		local m = t.mode
		local c = t.color
		local sw = {
			add	  = function() tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="0", colormultiply=(c)} end,
			multi = function() tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="0", colormultiply=(c)} end,
			nega  = function() tag{"lyprop", id=(id), intermediate_render="1", negative="1", grayscale="0", colormultiply="0xFFFFFF"} end,
			gray  = function() tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="1", colormultiply="0xFFFFFF"} end,
			sepia = function() tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="1", colormultiply=(c)} end,
--			reset = function() tag{"lyprop", id=(id), intermediate_render="0", negative="0", grayscale="0", colormultiply="0xFFFFFF"} scr.tone = nil end,
			anistop = function() end,
			ex = function() end,
		}
		if sw[m] then sw[m]()
		else error_message("色調エラー") end
	end
end
]]
----------------------------------------
-- 時間帯フィルタ / 設置
function timezone(p)
	if init.game_fgzone == "on" then
		local z = p.zone
		scr.zone = z
	end
end
----------------------------------------
-- 時間帯フィルタ
--[[
function setTimezone(id, ch)
	-- fgfフィルタ
	local s = scr.img.fgf
	local f = s and s[ch] and s[ch].zone

	-- 描画
	local c = f or scr.zone
	if c then
		tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="0", colormultiply=(c)}

	-- 立ち絵は結合しておく
	else
		tag{"lyprop", id=(id), intermediate_render="1"}
	end
end
]]
----------------------------------------
-- 
----------------------------------------
-- bg/fgのtween管理
function image_postween(id, p, fade, flag)
	local idx  = addImageID(id, 'move')
	local time = p.speed or p.time or fade and init[fade]
	local ease = p.ease or "out"
	local loop = p.loop
	local yoyo = p.yoyo
	local f1   = not (flag or getSkip() or flg.blj)		-- quickjump時は停止
	local f2   = loop == -1 and nil or f1
	if id == 'base' then idx = getImageID("base") end

	----------------------------------------
	-- disp動作
	if f1 then image_disp(id, p) end

	----------------------------------------
	-- pos x
	local x1 = p.x  and mulpos(p.x)
	local x2 = p.x2 and mulpos(p.x2)
	if f2 and x2 then
		local spd = p.xsp or time
		tween{ id=(idx), x=(x2..","..(x1 or 0)), time=(spd), ease=(ease), loop=(loop), yoyo=(yoyo)}
	elseif x1 then
		tag{"lyprop", id=(idx), left=(x1)}
	end

	-- pos y
	local y1 = p.y  and mulpos(p.y)
	local y2 = p.y2 and mulpos(p.y2)
	if f2 and y2 then
		local spd = p.ysp or time
		tween{ id=(idx), y=(y2..","..(y1 or 0)), time=(spd), ease=(ease), loop=(loop), yoyo=(yoyo)}
	elseif y1 then
		tag{"lyprop", id=(idx),  top=(y1)}
	end

	----------------------------------------
	-- zoom
	local z1 = p.zoom
	local z2 = p.z2
	local w1 = p.w1 or z1
	local w2 = p.w2 or z2
	local h1 = p.h1 or z1
	local h2 = p.h2 or z2
	if f2 and (w2 or h2) then
		local spd = p.zsp or time
		if z2 then
			tween{ id=(idx),  zoom=(z2..","..(z1 or 100)), time=(spd), ease=(ease), loop=(loop), yoyo=(yoyo)}
		else
			if w2 then tween{ id=(idx), xscale=(w2..","..(w1 or 100)), time=(spd), ease=(ease), loop=(loop), yoyo=(yoyo)} end
			if h2 then tween{ id=(idx), yscale=(h2..","..(h1 or 100)), time=(spd), ease=(ease), loop=(loop), yoyo=(yoyo)} end
		end
	elseif w1 or h1 then
		tag{"lyprop", id=(idx), xscale=(w1), yscale=(h1)}
	end

	----------------------------------------
	-- alpha
	local al = p.alpha or p.a
	if f2 and p.a2 then
		local apd = p.asp or time
		tween{ id=(idx), alpha=(p.a2..","..(al or 255)), time=(apd), ease=(ease), loop=(loop), yoyo=(yoyo)}
	elseif al then
		tag{"lyprop", id=(idx), alpha=(al)}
	end

	-- rotate
	local rt = p.rotate or p.r1 or p.r
	if f2 and p.r2 then
		local spd = p.rsp or time
		tween{ id=(idx), rotate=(p.r2..","..(rt or 0)), time=(spd), ease=(ease), loop=(loop), yoyo=(yoyo)}
	elseif rt then
		tag{"lyprop", id=(idx), rotate=(rt)}
	end
end
----------------------------------------
-- disp共通
function image_disp(id, p)
	if p and (p.mx or p.my) and not getSkip() then
		local mx = p.mx
		local my = p.my
		local es = p.me		-- ease
		local tm = p.time or init.fg_fade
		local ix = addImageID(id, 'act')
		local nm = p[1]
		local md = nm == "bg" and 3 or nm == "cgdel" and -2 or p.mode or 3

		-- 表示
		if md >= 2 then
			if mx then tween{ id=(ix), x=(mulpos(mx)..",0"), time=(tm), ease=(es) } end
			if my then tween{ id=(ix), y=(mulpos(my)..",0"), time=(tm), ease=(es) } end

		-- 消去
		elseif md <= -1 then
			if mx then tween{ id=(ix), x=("0,"..mulpos(mx)), time=(tm), ease=(es) } end
			if my then tween{ id=(ix), y=("0,"..mulpos(my)), time=(tm), ease=(es) } end
		end
	end
	return p
end
----------------------------------------
-- cache
----------------------------------------
--[[
function imageCache(nm, p)
	if p and p.file then
		local id = 'cache.'..nm..'.'..p.file
		if nm == 'fg' then	readfgImage(id, p, 'cache')
		else				readImage(id, p, 'cache') end
		tag{"lyprop", id="cache", visible="0"}
	end
end
----------------------------------------
function imageCacheClear(nm)
	if nm then	tag{"lydel", id="cache."..nm}
	else		tag{"lydel", id="cache"} end
end
]]
----------------------------------------
-- 
----------------------------------------
-- image store
function image_store(name, p)
	if not scr.img.buff then scr.img.buff = {} end
	table.insert(scr.img.buff, { name, p })
end
----------------------------------------
-- noに格納されたtagを取り出す
function getImageTag(no)
	return scr.img.buff[tonumber(no)][2]
end
----------------------------------------
-- stack展開 / クリック前処理
function image_loop(flag)
	if not scr.img.buff then return end

	local tr = {}
	local settime = function(p, def, f)
		local tm = tn(p.time) or f and (p.mx or p.my) and init.fg_fade2 or init[def] or def or 0
		local tx = tr.time
		if not tx or tx <= 2 or tx > tm and tm > 2 then tr.time = tm end
		if not tr.rule and p.rule then tr.rule = p.rule end
	end

	for i, v in ipairs(scr.img.buff) do
		local nm = v[1]
		local p  = v[2]

		-- 展開
		if nm == 'bg' then image_view(p, true)		settime(p, 'bg_fade')		-- BG展開
		elseif nm == 'fg'		then fg(p)			settime(p, 'fg_fade', true)	-- fg
		elseif nm == 'fgdel'	then fgdel(p)		settime(p, 'fg_fade', true)	-- fg del
		elseif nm == 'fgdelall' then fgdelall(p)	settime(p, 'fg_fade')		-- fg delall
		elseif nm == 'fgf'		then fgf(p)			settime(p, 'fg_fade', true)	-- fgf
		elseif nm == 'fgfdel'	then fgfdel(p)		settime(p, 'fg_fade', true)	-- fgf del

		elseif nm == 'cgdel_main' then cgdel_main(p) settime(p, 'bg_fade')		-- cg del

		-- その他
		elseif _G[nm] then
			_G[nm](p)

		else
--				if nm == "CG_DEL" then settime{ time=(p.time or 500) }
--			elseif nm == "CG_AN"  then settime{ time=(p.time or 0  ) }
--			elseif nm == "ST_DEL" then settime{ time=(p.time or 250) }
--			elseif nm == "STG"    then settime{ time=(p.time or 250) }
--			end
			e:tag{"calllua", ["function"]=(nm), no=(i)}
		end
	end

	e:enqueueTag{"lydel", id="bgc"}
	if not flag and tr.time then trans{ fade=(tr.time), rule=(tr.rule) } end
	scr.img.buff = nil
	return tr.time
end
----------------------------------------
-- screen
----------------------------------------
--
function screen(p)
	local x2 = p.x2
	local y2 = p.y2
	local w2 = p.w2
	local h2 = p.h2
	if x2 or y2 or w2 or h2 then
		image_postween("base", p)
	else
		tag{"lyprop", id="1.0", left="0", top="0", xscale="100", yscale="100"}
		flip()
	end
end
----------------------------------------
-- アニメーション
----------------------------------------
-- 再描画
function anime_reload()
	local s = scr.img.bg
	if s then
		for i, v in pairs(s) do
			if v.p then
				local id = getImageID('bg', v)
				lydel2(id)
				readImage(id, v.p)
			end
		end
	end
end
----------------------------------------
-- 雨
function anime_rain01(idx, p)
	local t1 = { 0.286, 0.306, 0.323, 0.343, 0.364 }	-- 角度
	local t2 = { 4400, 3600, 2800, 2000, 1200 }			-- 速度
	local v  = ipt[1]
	local fl = p.path..v[1]

	-- 計算
	local g  = game
	local mw = g.width
	local mh = g.height
	local mz = math.floor(math.sqrt(mw^2 + mh^2))	-- 対角線の長さ
	local zh = math.floor(mz / 2)
	local y  = -zh..","..zh

	-- 描く
	local mx = p.num or 400					-- 最大数
	local r  = p.rotate or p.r or 0			-- 角度
	local tm = p.speed or p.time or 400		-- 降る速度

	-- ランダム
	local fr = nil
	if (""..r):sub(1,1) == "r" then
		fr = {}
		local s = explode(",", r:sub(2))
		fr[1] = s[1]
		fr[2] = math.floor(s[1] / 2)
		fr[3] = s[2] or 0
	end

	-- ループ描画
	for i=1, mx do
		-- 遠さ
		local z  = (e:random() % 5) + 1
		local zm = z * 10 + 50
		local al = z * 20 + 50
		local tx = math.ceil(tm * z * 1.5)
		local dl = (e:random() % tx) + 1

		-- 描画
		local cx = (e:random() % mz) - zh
		local cy = (e:random() % mz)
		local rd = r
		if fr then rd = e:random() % fr[1] - fr[2] + fr[3] end
		local id = idx..'.'..i
		local idz = id..".0"
		lyc2{ id=(idz), file=(fl), x=(cx-v.ax), y=(-v.ay), alpha="0"}
		tag{"lyprop", id=(id), zoom=(zm), rotate=(rd), alpha=(al), layermode="add" }
		tag{"tweenset"}
		systween{ id=(idz), y=(cy..","..mh), time=(dl), ease="none" }
		systween{ id=(idz), y=(y), loop=-1, time=(tx), ease="none" }
		tag{"/tweenset"}

		-- alpha
		tag{"tweenset"}
		systween{ id=(idz), alpha="100,255", time=(dl), ease="none" }
		systween{ id=(idz), alpha="255,050", loop=-1, time=(tx), ease="none" }
		tag{"/tweenset"}
	end
	tag{"lyprop", id=(idx), left=(g.ax), top=(g.ay)}
end
----------------------------------------
-- 雪
function anime_snow01(idx, p)
	local v  = ipt[1]
	local fl = p.path..v[1]

	-- 計算
	local g  = game
	local mw = g.width
	local mh = g.height
	local mz = math.floor(math.sqrt(mw^2 + mh^2))	-- 対角線の長さ
	local zh = math.floor(mz / 2)
	local y  = -zh..","..zh
	local x  = p.xmove or 40

	-- 描く
	local mx = p.num or 600					-- 最大数
	local r  = p.rotate or p.r or 0			-- 角度
	local tm = p.speed or p.time or 600		-- 降る速度

	-- ランダム
	local fr = nil
	if (""..r):sub(1,1) == "r" then
		fr = {}
		local s = explode(",", r:sub(2))
		fr[1] = s[1]
		fr[2] = math.floor(s[1] / 2)
		fr[3] = s[4] or 0
	end

	-- ループ描画
	for i=1, mx do
		-- 距離
		local z  = (e:random() % 5) + 1
		local zm = z * 10 + 50
		local al = z * 20 + 50

		-- ランダム
		local cx = (e:random() % mz) - zh
		local cy = (e:random() % mz) - zh
		local rd = r
		if fr then rd = e:random() % fr[1] - fr[2] + fr[3] end
		local tx = math.ceil(tm * z * 1.5)
		local dl = math.ceil((e:random() % tx) * 1.5)

		-- 描画
		local id = idx..'.'..i
		local idz = id..".0"
		lyc2{ id=(idz), file=(fl), alpha="0"}--, x=(cx-v.ax), y=(-v.ay)}
		tag{"lyprop", id=(id), zoom=(zm), rotate=(rd), alpha=(al), layermode="screen"}
		tag{"tweenset"}
		systween{ id=(idz), y=(cy..","..mh), time=(dl), ease="none" }
		systween{ id=(idz), y=(y), loop=-1, time=(tx), ease="none" }
		tag{"/tweenset"}
		tag{"tweenset"}
		systween{ id=(idz), alpha="100,255", time=(dl), ease="none" }
		systween{ id=(idz), alpha="255,050", loop=-1, time=(tx), ease="none" }
		tag{"/tweenset"}

		-- xmove
		local mvx = cx - v.ax
		local rx  = e:random() % x + x
		local tx  = math.ceil((e:random() % tx + tx) / 2)
		systween{ id=(idz), x=((mvx-rx)..","..(mvx+rx)), yoyo=-1, time=(tx), ease="inout" }
	end
	tag{"lyprop", id=(idx), left=(g.ax), top=(g.ay)}
end
----------------------------------------
-- キラキラ
function anime_kira01(idx, p)
	local v  = ipt[1]
	local fl = p.path..v[1]
	local mz = p.num or 50					-- 最大数
	local tm = p.speed or p.time or 1000	-- 点滅速度
	local bm = p.blinkmode or "add"			-- layermode
	local cp = p.blinkarea					-- 除外範囲
	if cp then cp = explode(",", cp) end

	-- 計算
	local g  = game
	local mw = g.width
	local mh = g.height
	local mx = g.ax				-- 中心座標:x
	local my = g.ay				-- 中心座標:y
	local ax = v.ax
	local ay = v.ay
	local px = -ax
	local py = -ay

	-- サイズ/ランダム
	local sz = p.size
	local s1 = 25
	local s2 = 75
	if type(sz) == "string" and sz:find(":") then
		local dx = explode(":", sz)
		s1 = dx[1]
		s2 = dx[2]
	end

	-- 点滅/ランダム
	local bl = p.blink
	local a1 = 20
	local a2 = 160
	if type(bl) == "string" and bl:find(":") then
		local dx = explode(":", bl)
		a1 = dx[1]
		a2 = dx[2]
	end

	-- ループ描画
	for i=1, mz do
		-- 位置
		local x  = px
		local y  = py
		if cp then
			repeat
				local rx = e:random() % 2
				local ry = e:random() % 2
				x = e:random() % mx if rx == 1 then x = -x end
				y = e:random() % my if ry == 1 then y = -y end
				local c1 = cp[1] - mx
				local c2 = cp[2] - my
				local c3 = cp[3] + c1
				local c4 = cp[4] + c2
			until not (c1 < x and x < c3 and c2 < y and y < c4)
		else
			local rx = e:random() % 2
			local ry = e:random() % 2
			x = e:random() % mx if rx == 1 then x = -x end
			y = e:random() % my if ry == 1 then y = -y end
		end

		-- 距離
		local zm = 100
		local al = nil
		if bl == "auto" then
			-- 近いほど薄く透明
			local x1 = percent(x, mx) if x1 < 0 then x1 = x1 * -1 end
			local y1 = percent(y, my) if y1 < 0 then y1 = y1 * -1 end
			if x1 <= 0 or y1 <= 0 then
				zm = 1
				al = 0
			else
				local z1 = sz or zm
				zm = percent(((x1 + y1) / 2), z1)
				local aa = x1	--percent(x1, 200)
				local ab = y1	--percent(y1, 200)
				al = aa + ab if al > 255 then al = al - (255-al) end
			end
		else
			zm = (e:random() % s2) + s1
		end

		-- 描画
		local id = idx..'.br.'..i
		local idz = id..".0"
		lyc2{ id=(idz), file=(fl), alpha=(al), layermode=(bm), x=(x), y=(y)}
		tag{"lyprop", id=(id), left=(px), top=(py), xscale=(zm), yscale=(zm), anchorx=(ax), anchory=(ay)}

		-- 点滅
		local dl = (e:random() % 2) * tm
		tag{"tweenset"}
		systween{ id=(idz), alpha=("1,"..a1), time=(dl), ease="none" }
		systween{ id=(idz), alpha=(a1..","..a2), yoyo=-1, time=(tm), ease="none" }
		tag{"/tweenset"}
	end
	tag{"lyprop", id=(idx), left=(mx), top=(my)}
end
----------------------------------------
