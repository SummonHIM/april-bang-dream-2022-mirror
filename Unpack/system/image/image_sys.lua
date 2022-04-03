----------------------------------------
-- image / system系
----------------------------------------
-- scale pos
function getScalePos(p)
	local r = tn(p or 0)
	local g = game.scale or 1
	if p and g ~= 1 then r = math.ceil(r * g) end
	return r
end
----------------------------------------
-- tween time
function getTweenTime(time, def)
	local tm = tonumber(time or def)
	if tm and getSkip() then tm = 0 end
	return tm
end
----------------------------------------
-- trans
----------------------------------------
-- trans
function trans(p)
	flg.trans = nil
	if flg.notrans then flg.notrans = nil return end

	-- system
	if p.sys then
		estag("init")
		estag{"trans_main", p}
		if p.sys == 2 then estag{"trans_flag", p} end
		estag{"wt"}
		estag()

	-- effect off
	elseif getSkip(true) then
		estag("init")
		estag{"trans", type="0"}
		estag{"trans_flag", {}}
		estag()

	-- effect on
	else
		estag("init")
		estag{"trans_main", p}
		estag{"trans_flag", p}
		estag()
	end
end
----------------------------------------
function trans_main(p)
	local ani	= true
	local sys	= p.sys
	local input	= p.input or 1
	local time	= p.time or p.fade or "bg_fade"
	if init[time] then time = init[time] end

	if sys then
		if not stf and conf.sysani == 0 then time = 0 end
		if sys == 2 then flg.trans = true end
	else
		-- trans中フラグ
		e:tag{"var", name="s.clickskip", data="0"}
		flg.trans = true
	end

	-- ruleが指定されているかどうか
	local r = getRule(p, true)
	if time == 0 or not r then
		eqtag{"trans", type="1", input=(input), time=(time)}
	else
		local rule = r[1] or ""
		local vague= r[2] or init.vague
		local path = game.path.rule
		local exp  = game.ruleext

		-- 多言語切り替え
		if r[3] == "on" then
			local ln = get_language(true)
			local fl = rule.."_"..ln
			if ln ~= "ja" and isFile(path..fl..exp) then rule = fl end
		end
		eqtag{"trans", type="2", input=(input), time=(time), rule=(path..rule..exp), vague=(vague)}
	end
end
----------------------------------------
-- trans終了
function trans_flag(p)
	if e:var("s.clickskip") == "0" then
		eqwait(p.wait or 0)
	else
		wt()	-- クリックで飛ばされたときにも一応呼んでおく
	end
	flg.trans = nil
	scr.mode  = nil
	scr.fgflag= nil
	notification()		-- 場所名／bgm名

	-- trans command
	local c = flg.transcom
	if c then
		if _G[c] then _G[c]() flip() end
		flg.transcom = nil
	end
end
----------------------------------------
-- extrans / nosyncを実行してしまう
function extrans(p)
	if scr.img.buff then
		image_loop(true)
		shader_trans(p)		-- 全体シェーダー反映
		trans(p)
	end
end
----------------------------------------
-- ui共通
function uitrans(p)
	if not p then p = {} elseif type(p) == 'number' then p = { fade=(p) } end
	p.fade = not stf and conf.sysani == 0 and 0 or p.fade or p["0"] or init.ui_fade
	p.sys  = tn(p.sys) or true
	trans(p)
end
----------------------------------------
function getRule(p)
	local r  = nil
	local ru = p
	local vg = init.vague
	local la = nil
	if type(p) == 'table' then
		ru = p.rule  or nil
		vg = p.vague or vg
	end
	if ru then
		if type(ru) == "number" then
			ru = string.format("%03d", ru)
		elseif init[ru] then
			local z = init[ru]
			if type(z) == "table" then
				ru = z[1]
				vg = z[2]
				la = z[3]
			else
				ru = z
			end
		end
		r = { ru, vg, la }
	end
	return r
end
----------------------------------------
-- 画像処理汎用
----------------------------------------
function flip()  e:tag{"flip"} end
function eqflip(f)
	if f then eqtag{"trans", type="0"}
	else	  eqtag{"flip"} end
end
----------------------------------------
-- lyc2
function tags.lyc2(e, p) lyc2(p) return 1 end
function lyc2(p)
	if p.add then p.id = p.id..p.add end

	-- lyc
	tag{"lyc", id=(p.id), file=(p.file), mask=(p.mask), width=(p.width), height=(p.height), color=(p.color), eq=(p.eq)}

	-- lyprop
	local v = p
	v[1] = "lyprop"
	v.left	 = v.left	or v.x
	v.top	 = v.top	or v.y
	v.xscale = v.xscale or v.zoom
	v.yscale = v.yscale or v.zoom
	tag(v)
end
----------------------------------------
-- lydel簡易版
function lydel(id, eq)
	if not eq then e:tag{"lydel", id=(id)}
	else	e:enqueueTag{"lydel", id=(id)} end
end
----------------------------------------
-- lydel2
function lydel2(id, eq)
	if debug_flag then
		local s = type(id)
			if s == 'nil'	then error_message("lydelにidが設定されていませんでした")
		elseif s == 'table' then error_message("lydelの値がテーブルです") dump(id)
		end
	end
	if not eq then	e:tag{"lydel", id=(id)}
	else			eqtag{"lydel", id=(id)} end
end
----------------------------------------
-- tween
----------------------------------------
function tags.systween(e, p) systween(p) return 1 end
----------------------------------------
function systween(p)
	p.sys = true
	if not stf and conf.sysani == 0 then p.time = 0 end
	tween(p)
end
----------------------------------------
function systween2(p)
	if conf.sysani == 1 then
		p.sys = true
		tween(p)
	end
end
----------------------------------------
-- lytween簡易版	[tween id="" alpha="0,255" time="" ease="inout"]
function tween(param)
	-- skip
	if conf.effect == 0 and not param.sys and not param.yoyo and not param.loop and not param.event then param.time = 0 end

	local p = tcopy(param)
		if param.x		then tween_loop(p, "x", "left")
	elseif param.y		then tween_loop(p, "y", "top")
	elseif param.alpha	then tween_loop(p, "alpha" , "alpha")
	elseif param.rotate	then tween_loop(p, "rotate", "rotate")
	elseif param.xscale	then tween_loop(p, "xscale", "xscale")
	elseif param.yscale	then tween_loop(p, "yscale", "yscale")
	elseif param.zoom	then
		tween_loop(p, "zoom", "xscale")
		tween_loop(p, "zoom", "yscale")
	end
end
----------------------------------------
-- effect timeを見る
function get_tweentime(p, ex)
	local time = p or 0
	if not ex and getSkip() then time = 0 end
	return time
end
----------------------------------------
function tween_loop(param, key, com)
	local ex  = param.event or param.sys
	local a   = split(param[key], ",")
	local max = table.maxn(a)
	param[1] = "lytween"

	-- ease変換
	if not param.ease then param.ease = 'easeout_quad'
	elseif param.ease ~= "none" and not string.find(param.ease, "_") then param.ease = "ease"..param.ease.."_quad" end

	-- keyの値が不明
	if max < 2 then
		param.time = get_tweentime(param.time, ex)
		tag(param)

	-- 通常のtween
	elseif max == 2 then
		param.param = com
		param.from	= (param.time == 0) and a[2] or a[1]
		param.to  	= a[2]
		param.time  = get_tweentime(param.time, ex)
		tag(param)

	-- 複数tween
	else
		local tx = {}
		local eq = param.eq
		local time = param.time
		if type(time) == "string" and time:find(",") then
			tx = split(param.time, ",")
			time = tx[1]
		end
		tag{"tweenset", eq=(eq)}
		param.param = com
		local p = tcopy(param)
		p.from	= a[1]
		p.to  	= a[2]
		p.time  = get_tweentime(time, ex)
		p.yoyo	= nil
		p.loop	= nil
		tag(p)
		for i=2, max-1 do
			if eq then
--				local p = tcopy(param)
				local p = param
				p.from	= a[i]
				p.to  	= a[i+1]
				p.time  = tx[i] or time
				tag(p)
				time = p.time
			else
				param.from	= a[i]
				param.to  	= a[i+1]
				param.time  = tx[i] or time
				tag(param)
				time = param.time
			end
		end
		tag{"/tweenset", eq=(eq)}
	end
end
----------------------------------------
