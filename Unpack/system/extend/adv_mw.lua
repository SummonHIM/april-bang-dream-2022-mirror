----------------------------------------
-- adv / MW操作
----------------------------------------
-- MW設置
function init_advmw(f)
--	scr.firsthalf = true

	-- MWベース
	setMWImage("bg01")
--	if getMWID("name") then setMWImage("name", nil, 0) end	-- name
	if getMWID("read") then setMWImage("read", nil, 0) end	-- 既読
	if getMWID("auto") then setMWImage("auto", nil, 0) end	-- auto icon
	if getMWID("skip") then setMWImage("skip", nil, 0) end	-- skip icon

	-- name / adv
	setMWFont()
	mw_alpha()
	set_message_speed()

	chgmsg_adv()	-- advに変更
	init_adv_btn()	-- ボタン設置

	-- 非表示設置
	if not f then
		e:tag{"lyprop", id=(game.mwid), visible="0"}
	end
end
----------------------------------------
-- set mw image
function setMWImage(name, alpha, visible)
	local t = csv.mw[name]
	if t then
		local px = get_uipath()..t.file
		local id = getMWID(name)
		local ix = id..".1"
		lyc2{ id=(ix), file=(px), clip=(t.clip) }

		-- 背景
		local bs = "base"..name
		local b  = csv.mw[bs]
		if b then
			local md = b.clip_a
			local px = game.path.ui..b.file
			local ib = id..".0"
			local ax = math.floor(b.w / 2)
			local ay = math.floor(b.h / 2)
			lyc2{ id=(ib), file=(px), clip=(b.clip), anchorx=(ax), anchory=(ay) }
			if md == "rotate" then
				systween{ id=(ib), rotate="0,360", time=(b.clip_c), ease="none", loop="-1" }
			end
		end
		tag{"lyprop", id=(id), left=(t.x), top=(t.y), alpha=(alpha), visible=(visible) }
	end
end
----------------------------------------
-- mwの透明度
function mw_alpha()
	-- alpha
	local id = getMWID("bg01")
	local p  = scr.mwalpha or repercent(conf.mw_alpha, 255)
	tag{"lyprop", id=(id), alpha=(p)}

	-- RGB
	local md = init.game_mwbgcolor
	if md then
		local ix = id..".1"
		local r  = (conf.mwbg_r or 0) * 2.55
		local g  = (conf.mwbg_g or 0) * 2.55
		local b  = (conf.mwbg_b or 0) * 2.55
		local co = string.format("0x%02x%02x%02x", r, g, b)
		if md == "mul" then
			tag{"lyprop", id=(ix), colormultiply=(co)}
--			tag{"lyprop", id=(ix), intermediate_render="1", colormultiply=(co)}
		elseif md == "cadd" or md == "cmul" then
			shader_lyprop(ix, { style=(md), color=(co) })
		end
	end

	-- name
	local id = getMWID("name")
	if id then e:tag{"lyprop", id=(id), alpha=(p)} end
end
----------------------------------------
-- get mw id
function getMWID(name)
	local t = csv.mw[name]
	return t and game.mwid.."."..t.id
end
----------------------------------------
-- mw切り替え
----------------------------------------
-- 切り替え
function mw(p)
	local no = p.no or scr.mwno or 1
	scr.mwno = no
	scr.mwalpha = p.alpha
	message("通知", no, "番のmwに切り替えます")
	init_adv_btn()
	setMWFont()

	-- novel
	local md = p.mode
	if md == "novel" and getNovel() then
		scr.novel = { no=0 }

	-- 非表示
	else
		scr.novel = nil
		msgcheck("off")
		message_name()
	end
	flip()
end
----------------------------------------
-- fontとglyph
function setMWFont(flag)
	local no = scr.mwno or 1
	local nx = string.format("%02d", no)
	if not flag then
		adv_cls4(true)				-- 文字を消しておく
		setMWImage('bg'..nx)		-- MW書き換え
		setMWImage('name'..nx)		-- MW書き換え
		mw_alpha()					-- alpha再設定
	end

	-- font
	local t  = csv.mw or {}
	local nm = 'bg'..nx
	local md = t[nm] and t[nm].clip_c or 'adv'
	local tb = { adv=1, name=1 }
	if init.game_sublangview == "on" then tb.sub = 1 end	-- sub
	for nm, i in pairs(tb) do
		set_textfont((nm..nx), mw_getmsgid(nm), md)
	end

	-- sm
	if smex then smex.sm_font(nx) end

	-- glyph設置
	local auto = autoskipcheck() and init.game_autoglyph == "del"
	if not auto then glyph_set(no) end
end
----------------------------------------
-- 名前画像
----------------------------------------
-- 文字数で長さを変える
function exnameimage(id, tx)
--[[
	tag{"/font"}
	local tbl = {
		[1280] = { 161, 313 },
		[1920] = { 240, 468 },
	}
	local w  = tbl[game.width]
	local no = scr.mwno or 1
	local v  = csv.mw["name0"..no]
	local ct = #tx / 3
	if ct <= 6 then
		tag{"lyprop", id=(id), clip=(v.clip_a)}
		tag{"font", width=(w[1]), kerning="2"}
	else
		tag{"lyprop", id=(id), clip=(v.clip)}
		tag{"font", width=(w[2]), kerning="2"}
	end
]]
end
----------------------------------------
-- ボタン制御
----------------------------------------
-- ボタンを配置
function init_adv_btn()
	local r = select_extend("reload")
	local n = "ui_adv" if init.game_mwchange == "on" then n = n..string.format("%02d", (scr.mwno or 1)) end
	local v = lang[n]
	if v and v[1] and r then
		sys.adv = { dummy=0 }
		local id = game.mwid
--		lydel2(id..".mw.bb")
		csvbtn3("adv", id, v)

		-- tablet
		if init.mwtabid and game.pa then
			tag{"lyprop", id=(id..".tb.tb"), visible="0"}
			tag{"lyprop", id=(id..".tb.mask"), visible="0"}
		end

		-- mw face
		if v.face01 then
			local c = scr.mwfropen and 255 or 0
			tag{"lyprop", id=(id..".mw.bb"), alpha=(c)}
			scr.mwframe = true
		else
			scr.mwfropen = nil
		end

		-- help
--		local ix = getBtnID("help")
--		if ix then tag{"lyprop", id=(ix), visible="0"} end

		-- popup help
		init_popuphelp()

		----------------------------------------
		-- mw button
		mw_tablet()				-- tablet ui
		mwdock_lock()			-- mw btn lock
		check_adv_btn("adv")	-- ボタンを塞ぐ処理
	end
end
----------------------------------------
-- ボタン状態の確認
function check_adv_btn(name)
	local tbl = { all=1, last=1, quick=1, auto=1, cont=1, title=1 }
	local ext = getExtra()
	local sel = scr.select
	local was = checkWasmsync()
	local vo  = name == "menu" and scr.voice and table.maxn(scr.voice.stack) == 0
	local r   = {}

	----------------------------------------
	-- check
	local check = function(nm, bt)
		-- wasm					   選択肢					 シーン鑑賞				  セーブデータ確認				  voice(menu専用)
		if nm == "wasm" and was or nm == "select" and sel or nm == "scene" and ext or tbl[nm] and sv.checkopen(nm) or nm == "voice" and vo then
			setBtnStat(bt, 'c')
			r[bt] = true

		-- 非表示処理
		elseif nm == "hide" and r[bt] then
			tag{"lyprop", id=(getBtnID(bt)), visible="0"}
		else
			tag{"lyprop", id=(getBtnID(bt)), visible="1"}
			setBtnStat(bt, nil)
		end
	end

	----------------------------------------
	-- loop
	local p = csv.advbtn
	if p and p[name] then
		for bt, nm in pairs(p[name]) do
			setBtnStat(bt, nil)				-- 一回開けておく
			if type(nm) == "string" then
				check(nm, bt)
			else
				for i, v in ipairs(nm) do
					check(v, bt)
				end
			end
		end
	end
end
----------------------------------------
-- ボタンが押されたときに消してしまう
function advmw_clear(flag)
	local bt = btn.cursor
	if not flag and conf.tablet == 1 then
		-- tablet mode
		if conf.dock == 0 and scr.mwlock and not scr.select then
			mwarea_close()
		end
	end

	-- mwボタン
	if bt and (not flag or flag == "sp" and game.sp) then
		btn_nonactive(bt, true)
		btn.cursor = nil
		mwarea_out()				-- mwbtn lock
	end
	flg.mwsplock = nil
end
----------------------------------------
-- 
----------------------------------------
-- sback / 設定行戻す
function mw_autoback()
	local ct = conf.scback
	local mx = #log.stack
	if mx > 1 then
		local bc = mx - ct
		if bc < 1 then bc = 1 end

		message("通知", ct, "行戻します", bc)

		se_ok()
--		ReturnStack()	-- 空のスタックを削除
		quickjumpui(bc)
	end
end
----------------------------------------
-- glyph
----------------------------------------
-- glyph設置	name,x,y,w,h,loop,time,homing
function glyph_set(no)
	local s = conf.glyph or 1
	if s == 0 then
		chgmsg_adv(true)
		glyph_del()
		chgmsg_adv("close")
		return
	end

	-- name
	local t  = csv.mw or {}
	local nm = "glyph01"
	local nx = "glyph"..string.format("%02d", no)
	if t[nx] then nm = nx end

	-- 設置
	chgmsg_adv(true)
	local g    = csv.mw[nm]
	local id   = game.mwid.."."..g.id
	local path = game.path.ui
	local max  = g.loop
	local time = g.time

	-- back
	local b = csv.mw.baseglyph
	if b then
		local md = b.clip_a
		local ib = id..".0"
		local px = path..b.file
		local ax = math.floor(b.w / 2)
		local ay = math.floor(b.h / 2)
		lyc2{ id=(ib), file=(px), clip=(b.clip), anchorx=(ax), anchory=(ay) }
		if md == "rotate" then
			systween{ id=(ib), rotate="0,360", time=(b.clip_c), ease="none", loop="-1" }
		end
	end

	-- anime
	local ix = id..".1"
	e:tag{"glyph"}
	e:tag{"anime",		id=(ix), mode="init", file=(path..g.file), clip=("0,0,"..g.w..","..g.h)}
	for i=1, max do
		e:tag{"anime",	id=(ix), mode="add",  file=(path..g.file), clip=((i*g.w)..",0,"..g.w..","..g.h), time=(i*time)}
	end
	e:tag{"anime",		id=(ix), mode="end",  time=(max * time)}

	-- homing
	local h = g.homing or 0
	if h == 0 then
		e:tag{"lyprop",		id=(id), left=(g.x), top=(g.y)}
		e:tag{"glyph",	 layer=(id), homing=(g.homing)}
	else
		e:tag{"glyph",	 layer=(id), homing=(g.homing), left=(g.x), top=(g.y)}
	end
	chgmsg_adv("close")
end
----------------------------------------
-- glyph消去
function glyph_del()
	e:tag{"glyph"}
end
----------------------------------------
--[[
-- glyph check
function glyph_check()
	-- voice
	if scr.voice.glyph then
		glyph_set("glyph_voice")

	-- normal
	else
		glyph_set("glyph_adv")
	end
end
----------------------------------------
-- glyph delete
function glyph_del()
--	message("通知", "glyph delete")
	e:tag{"lydel", id="1.90"}
	e:tag{"glyph"}
	flg.glyph = nil
	scr.adv.glyph = nil
end
----------------------------------------
-- glyph
function glyph_set(name, f)
	local id	= "1.90"
	local time	= init.glyph_time
	local p		= init[name]
	if not f then glyph_del() end
	flg.glyph = {}

--	message("通知", "glyph を設定しました")

	if p and not p[3] then
		-- alpha点滅
		lyc2{  id=(id), file=(p[1]), clip=(p[2])}
		tween{ id=(id), alpha="255,0", time=(time), yoyo="-1"}
	elseif p then
		-- 1    2   3     4     5     6     7
		-- file,max,sizeX,sizeY,clipX,clipY,max2
		local max = p[2] + p[7]
		local cx  = p[5]
		local cy  = p[6]
		for i = 0, max do
			lyc2{ id=(id..'.'..i), file=(p[1]), clip=((cx + i*p[3])..","..cy..","..p[3]..","..p[4]), alpha=0}
		end
		scr.adv.glyph = 0
		tween{ id=(id..".0"), c=0, name=(name), max=(p[2]), max2=(max), time2=(time), alpha="254,255", time=1, delay=(time), handler="calllua", ["function"]="glyph_anime", eq=true }

		flg.glyph.max = max
--[ [
		-- アニメ
		local max = p[2] - 1
		local cx  = p[5]
		local cy  = p[6]

		-- ループ
		e:tag{"anime", id=(id), mode="init", file=(p[1]), clip=(cx..","..cy..","..p[3]..","..p[4])}
		for i = 1, max do
			e:tag{"anime", id=(id), mode="add", file=(p[1]), clip=((cx + i*p[3])..","..cy..","..p[3]..","..p[4]), time=(i*time)}
		end
		e:tag{"anime", id=(id), mode="end", time=(max*time)}
		tween{ id=(id), alpha="254,255", time=(max*time), handler="calllua", ["function"]="glyph_anime", name=(name), eq=true }
] ]
	end

	-- 表示位置
	local p = init.glyph_pos
	e:tag{"lyprop", id=(id), left=(p[1]), top=(p[2])}
	if not f then e:tag{"glyph", layer=(id), homing=(init.glyph_homing)} end
--	e:tag{"glyph", layer=(id), left=(p[1]), top=(p[2]), homing=(init.glyph_homing)}
end
----------------------------------------
function glyph_anime(e, p)
	local c	= tonumber(p.c)
	if scr.mw.msg and flg.glyph and scr.adv.glyph == c then
		local id	= "1.90."
		local time	= tonumber(p.time2)
		local delay	= time

		-- 消す
		tween{ id=(id..c), alpha="1,0", time=1 }

		-- 計算
		c = c + 1
		if c >= 0 + p.max2 then c = 0 + p.max end
		if c >= 0 + p.max  then delay = time * 4 end
		scr.adv.glyph = c
		tween{ id=(id..c), c=(c), name=(p.name), max=(p.max), max2=(p.max2), alpha="254,255", time=1, time2=(time), delay=(delay), handler="calllua", ["function"]="glyph_anime" }

	-- 消しておく
	elseif flg.glyph then
		tween{ id=("1.90."..c), alpha="1,0", time=1 }
	end
end
]]
----------------------------------------
-- mw dock
----------------------------------------
-- mw dock on/offボタンが押された
function mwdock()
	local t = getMWDockDir()
	local c = conf.dock or 1
	if c == 0 then conf.dock = 1 if t then flg.mwsplock = nil  if game.sp then scr.mwlock = true end end
	else		   conf.dock = 0 if t then flg.mwsplock = true if game.sp then scr.mwlock = nil  end end end
	btn_over(e, { key="bt_lock" })
	flip()
end
----------------------------------------
-- dock lock
function mwdock_mover(e, p)
	local c  = conf.dock or 1
	if c == 0 then btn_clip("bt_lock", 'clip_d') end
	popuphelp_over(e, { name="bt_lock"} )		-- popup
end
----------------------------------------
function mwdock_mout(e, p)
	local c  = conf.dock or 1
	if c == 0 then btn_clip("bt_lock", 'clip_c') end
	popuphelp_out(e, { name="bt_lock"} )		-- popup
end
----------------------------------------
-- volume
function mwdock_vover()
	if conf.fl_master == 0 or conf.master == 0 then btn_clip("bt_mute", 'clip_d') end
end
----------------------------------------
function mwdock_vout()
	if conf.fl_master == 0 or conf.master == 0 then btn_clip("bt_mute", 'clip_c') end
end
----------------------------------------
--
----------------------------------------
-- lock状態 / 初期設定(init_adv_btnから呼ばれる)
function mwdock_lock()
	if checkBtnExist("dockarea") then
		-- dock area
		local ix = getBtnID("dockarea")
		tag{"lyprop", id=(ix), alpha="0", clickablethreshold="128"}
		lyevent{ name="adv", id=(ix), over="mwarea_over", out="mwarea_out"}

		-- lock button
		local id = init.mwbtnid
		local c  = conf.dock or 1				-- dock状態 : 0   :隠す / 1  :固定
		local sl = scr.select 					-- 選択肢は表示
		local mb = game.sp and flg.mwsplock		-- SPでは表示
		if c == 1 or sl or mb then
			mwdock_status(true)		-- show
		else
			mwdock_status(false)	-- hide
			del_uihelp()
		end
		set_uihelp(id..".dc.help", "mwhelp")	-- help
		mwdock_mout()							-- dock clip
	end
end
----------------------------------------
-- dock状態制御
function mwdock_status(vs, flag)
	if checkBtnExist("dockarea") then
		local sl = scr.select 			-- 選択肢は表示
		local dc = init.mwbtnid..".dc"
--		local cl = init.mwbtnid..".cl"
		tag{"lytweendel", id=(dc)}

		-- reset
		if type(vs) == "boolean" or sl then
			local fl = sl or vs
			local vi = fl and "1" or "0"
			local al = fl and "255" or "0"
			tag{"lyprop", id=(dc), visible=(vi), alpha=(al), top="0", left="0"}
--			tag{"lyprop", id=(cl), visible=(vi)}
			scr.mwlock = fl

		-- tween
		elseif vs == "open" or vs == "close" then
			local tm = init.mwbtn_fade
			local v  = getBtnInfo("dockarea")
			local dr = v.p1 or "y"
			local sz = v.p2 or mulpos(48)
			if vs == "open" then
				tag{"lyprop", id=(dc), visible="1"}
				systween{ id=(dc), time=(tm), [dr]=(sz..",0") }
				systween{ id=(dc), time=(tm), alpha="0,255" }
				scr.mwlock = true
			else
				tag{"lyprop", id=(dc), visible="0"}
				systween{ id=(dc), time=(tm), [dr]=("0,"..sz) }
				systween{ id=(dc), time=(tm), alpha="255,0" }
				scr.mwlock = false
			end
			if flag then uitrans(tm) end
		end
	end
end
----------------------------------------
-- mwdock表示
function mwdock_show()
	if not scr.adv.menu and scr.mwhide then
		mwdock_status("open", true)
	end
end
----------------------------------------
-- mwdock消去
function mwdock_hide()
	if not scr.mwhide then
		mwdock_status("close", true)
	end
end
----------------------------------------
-- 
function mwarea_over()
	if conf.dock == 0 and not scr.mwlock then
		if flg.delay then
			flg.delay = "skip"
			flg.delaykey = { "delayfunc", "mwarea_over" }
			e:tag{"exec", command="skip", mode="1"}

		-- open
		elseif not scr.select and not flg.mwmute and not autoskipcheck() then
			mwarea_open()
		end
	end
end
----------------------------------------
function mwarea_out()
	if conf.dock == 0 and scr.mwlock and not scr.select then

		-- tablet mode
		if conf.tablet == 1 then
			flg.mwsplock = true

		-- mute
		elseif not flg.mwmute then
			mwarea_close()
		end
	end
end
----------------------------------------
-- dockを開く動作
function mwarea_open()
	-- mwhelpを消しておく
	local id = flg.uihelp
	if id then ui_message(id) end

	-- 開く
	mwdock_status("open", true)

	-- tablet mode
	if conf.tablet == 1 then flg.mwsplock = true end
end
----------------------------------------
-- dockを閉じる動作
function mwarea_close()
	mwdock_status("close", true)
	btn.cursor = nil
end
----------------------------------------
function mwdock_mute()
	if not flg.mwmute then
		flg.mwmute = true

		local tm = init.mwbtn_fade
		if not scr.mwlock then mwdock_status("open") end		-- dock show

		-- slider位置
		sys.adv.dummy = 100 - conf.master
		local y = percent(sys.adv.dummy, 100)
		local v = getBtnInfo("sl_vol")
		local s = repercent(y, v.h - v.p2)
		e:tag{"lyprop", id=(v.idx..".10"), top=(s)}
		tag{"lyprop", id=(getBtnID("sl_vol")), visible="1"}
		uitrans(tm)
	end
end
----------------------------------------
function mwdock_volume(e, p)
	conf.master = 100 - sys.adv.dummy
	volume_master()
end
----------------------------------------
-- 閉じる
function mwdock_muteclose()
	if flg.mwmute then
		flg.mwmute = nil

		local tm = init.mwbtn_fade
		if not scr.mwlock then mwdock_status("open") end
		tag{"lyprop", id=(getBtnID("sl_vol")), visible="0"}
		estag("init")
		estag{"uitrans", tm}
		estag{"asyssave"}
		estag()
	end
end
----------------------------------------
-- タブレットモード有効確認
function getMWDockDir(nm)
	local r  = nil
	local dr = init.game_mwdockdir
	if dr and conf.tablet == 1 then
		if nm then r = nm == dr else r = true end
	end
	return r
end
----------------------------------------
-- 
----------------------------------------
function mwmenu_check(nm)
	if nm == "on" then
		menuon()
		mwdock_show()
	elseif nm == "off" then
		menuoff()
		mwdock_hide()
	end
end
----------------------------------------
-- popup help
------------------------------------------
-- popup初期化
function init_popuphelp()
	if init.game_mwpopup == "on" then
		local gr = btn.name
		local p  = btn[gr].p
		local ib = btn[gr].id
		for nm, v in pairs(p) do
			if v.p1 == "popup" then
				tag{"lyprop", id=(ib..v.id), visible="0"}
			end
		end
	end
end
----------------------------------------
-- popup over
function popuphelp_over(e, p)
	local bt = p.name
	if bt and init.game_mwpopup == "on" then
		local nm = bt:gsub("bt_", "help_")
		tag{"lyprop", id=(getBtnID(nm)), visible="1"}
	end
end
----------------------------------------
-- popup out
function popuphelp_out(e, p)
	local bt = p.name
	if bt and init.game_mwpopup == "on" then
		local nm = bt:gsub("bt_", "help_")
		tag{"lyprop", id=(getBtnID(nm)), visible="0"}
	end
end
----------------------------------------
-- auto / skip
----------------------------------------
-- autoskip開始時に呼ばれる
function autoskip_startimg(name)
	if menu_check() then
--		message("通知", name, "開始")

		advmw_clear()

		-- glyph削除
		if name == "auto" and init.game_autoglyph == "del" then glyph_del() end

		-- icon
		local idx = getMWID(name)
		if idx then tag{"lyprop", id=(idx), visible="1"} end

		-- MWボタン
		local id = init.mwbtnid
		if id and game.pa then
			-- tablet ui
			if tabletCheck("ui") then
				tag{"lyprop", id=(init.mwtabid), visible="0"}
			end

			-- mwbtn
			if name == 'auto' or name == 'autoplay' then
				mwdock_status("close", true)
			else
				mwdock_status(false)	-- dock hide
				flip()
			end
		else
			flip()
		end
		flg.autoskipflag = name
	end
end
----------------------------------------
-- autoskip停止時に呼ばれる
function autoskip_stopimg()
	if menu_check() then
		local name = flg.autoskipflag
		local tm = init.mwbtn_fade
		local id = init.mwbtnid

		-- glyph設置
		if name == "auto" and init.game_autoglyph == "del" then
			local no = scr.mwno or 1
			glyph_set(no)
		end

		-- tablet ui
		if tabletCheck("ui") then
			tag{"lyprop", id=(init.mwtabid), visible="1"}
		end

		-- icon
		local idx = getMWID(name)
		if idx then tag{"lyprop", id=(idx), visible="0"} end

		-- dock
		local op = (conf.dock or 1) == 1	-- dock状態 : 0   :隠す / 1  :固定
		if id and game.pa and op then
--			if name == 'auto' or name == 'autoplay' then
				mwdock_status("open")		-- dock open
--			elseif name == 'skip' then
--				mwdock_status(true)			-- dock show
--			end
		end
		flip()
		flg.tapclear = true		-- 指が離されるまでtap無効化
	end
	flg.autoskipflag = nil
end
----------------------------------------
-- 通知
----------------------------------------
-- qsave/qload通知
function info_qsaveload(name)
	local v = csv.mw[name]
	if v then
		local id = getMWID(name)
		local px = game.path.ui..v.file
		local dr = v.clip_a or "left"
		local ad = v.clip_c or 100
		lyc2{ id=(id..".0"), file=(px), x=(v.x), y=(v.y), clip=(v.clip) }
		if dr == "left" then	tag{"lyprop", id=(id), left=(ad)}
		else					tag{"lyprop", id=(id),  top=(ad)} end

		-- tween
		tag{"lytweendel", id=(id)}
		tag{"tweenset"}
		tag{"lytween", id=(id), param=(dr), from=(ad), to="0", time="500", ease="easeinout_quad"}
		tag{"lytween", id=(id), param=(dr), from="0", to=(ad), time="500", ease="easeinout_quad", delay="2000", delete="1"}
		tag{"/tweenset"}
		flip()
	end
end
----------------------------------------
-- bg / bgm
function set_notification(mode, file)
	local t = csv.mw or {}

	-- 背景名
	local v  = t.bgname
	if v and mode == "bg" then
		local ct = v.clip_a or 4
		local fl = file:gsub("z", ""):sub(1, ct)
		local hd = fl:sub(1, 2)
		if hd == "bg" then flg.notification_bg = fl end
	end

	-- 曲名
	local v  = t.bgmname
	if v and mode == "bgm" then
		local ct = init.game_bgmsetcut or 5
		local fl = file:sub(1, ct)
		flg.notification_bgm = fl
		notification()
	end
end
----------------------------------------
-- bg / bgm
function notification()
	local t  = csv.mw or {}
	local fl = nil
	if not flg.notify then flg.notify = {} end

	----------------------------------------
	-- 背景名
	local func = function(md, nm, v)
		local z  = lang[md] or {}
		local r  = nil
		local id = v.id
		tag{"lytweendel", id=(id)}

		-- ipt
		local px = get_uipath()..v.file
		if isFile(px..".ipt") then
			e:include(px..".ipt")
			if ipt[nm] then
				lyc2{ id=(id..".0"), file=(px), clip=(ipt[nm]) }
				r = true
			end

		-- 画像
		elseif z[nm] then
			lyc2{ id=(id..".0"), file=(px), clip=(v.clip) }
			ui_message(id..".1", { md, text=(z[nm]) })
			r = true
		end

		-- tween
		if r then
			local tm = init.ui_fade
			local ct = v.clip_c or "lt"
			local x  = v.x or 0
			local y  = v.y or 0
			local w  = v.w or 0
			local h  = v.h or 0

			tag{"lyprop", id=(id), alpha="255", left=(x), top=(y)}
			tween{id=(id), alpha="255,0", time=(tm), delay="3000"}

			local sw = {
				lt = function() tween{id=(id), x=((x-w)..","..x), time=(tm)} end,		-- 左から
				rt = function() tween{id=(id), x=((x+w)..","..x), time=(tm)} end,		-- 右から
				up = function() tween{id=(id), y=(-h..","..y)   , time=(tm)} end,		-- 上から
				dw = function() tween{id=(id), y=((y-h)..","..y), time=(tm)} end,		-- 下から
			}
			if sw[ct] then sw[ct]() end
		end
		return r
	end

	----------------------------------------
	-- 背景名
	local md = "bgname"
	local v  = t[md]
	local nm = flg.notification_bg
	if nm and nm ~= flg.notify[md] and conf[md] == 1 then
		flg.notification_bg = nil
		local r = func(md, nm, v)
		if r then flg.notify[md] = nm fl = r or fl end
	end

	----------------------------------------
	-- 曲名
	local md = "bgmname"
	local v  = t[md]
	local nm = flg.notification_bgm
	if nm and nm ~= flg.notify[md] and conf[md] == 1 then
		flg.notification_bgm = nil
		local r = func(md, nm, v)
		if r then flg.notify[md] = nm fl = r or fl end
	end

	-- flip
	if fl then flip() end
end
----------------------------------------
-- 通知消去
function tags.ntclear() notification_clear() return 1 end
function notification_clear(name)
	-- 曲名 / 背景名
	if not flg.notify then flg.notify = {} end
	local tb = { bg="bgname", bgm="bgmname" }
	local t  = csv.mw or {}
	local f  = flg.notify
	for nm, md in pairs(tb) do
		local v = t[md]
		if v and f[md] and (not name or name == nm) then
			local id = v.id
			tag{"lytweendel", id=(id)}
			tag{"lyprop", id=(id), alpha="0"}
			ui_message(id..".1")
		end
	end

	-- 通知
	if not name then
		local qs = getMWID("qsave") if qs then tag{"lytweendel", id=(qs)} end	-- qsave
		local ql = getMWID("qload") if ql then tag{"lytweendel", id=(ql)} end	-- qload
		notify()
	end
end
----------------------------------------
