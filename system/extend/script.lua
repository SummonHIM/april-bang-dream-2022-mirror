----------------------------------------
-- 中間スクリプト
----------------------------------------
-- system
----------------------------------------
-- MW
function tags.sysshow(e, p)		msg_show(p.skip) return 1 end		-- [sysshow] / system
function tags.syshide(e, p)		msg_hide(p.skip) return 1 end		-- [syshide] / system
function tags.msgon(e, p)		msgon(p) return 1 end				-- [msgon]
function tags.msgoff(e, p)		msgoff(p) return 1 end				-- [msgoff]
function tags.menuon(e, p)		mwmenu_check("on")  return 1 end	-- [menuon]  / メニュー許可
function tags.menuoff(e, p)		mwmenu_check("off") return 1 end	-- [menuoff] / メニュー禁止
------------------------
-- [msg]
function tags.msg(e, p)
	estag("init")
	estag{"msgoff"}
	estag{"mw", p}
	estag()
	return 1
end
------------------------
-- image
function tags.bg_reset(e, p)	reset_bg() return 1 end				-- [bg_reset]
function tags.extrans(e, p)		extrans(p) return 1 end				-- [extrans]
------------------------
-- jump
function tags.excall(e, p)		excall(p) return 1 end				-- [script]
function tags.exreturn(e, p)	exreturn(p) return 1 end			-- [exreturn]
function tags.select(e, p)		exselect(p) return 1 end			-- [select]
function tags.selback(e, p)		exselback(p) return 1 end			-- [selback]
function tags.selnext(e, p)		exselnext(p) return 1 end			-- [selnext]
function tags.brandlogo(e, p)	brandlogo(p) return 1 end			-- [brandlogo]
function tags.staffroll(e, p)	staffroll(p) return 1 end			-- [staffroll]
------------------------
-- extra
function tags.scene(e, p)		tag_scene(p) return 1 end			-- [scene]
------------------------
-- key
function tags.keyskip(e, p)		keyskip(p) return 1 end				-- [keyskip]
function tags.skipstart(e, p)	autoskip_init() return 1 end		-- [skipstart]
------------------------
-- [skipstop]
function tags.skipstop(e, p)
	estag("init")
	estag{"exskip_stop"}		-- exskip停止
	estag{"autoskip_stop"}		-- skip停止
	estag{"skip", allow="0"}	-- 無効化
	estag()
	return 1
end
------------------------
-- save
function tags.savetitle(e, p)	sv.savetitle(p) return 1 end		-- [savetitle]
function tags.loading(e, p)		loading_func(p) return 1 end
function tags.saving(e, p)		saving_func(p) return 1 end
function tags.uimask(e, p)		uimask_func(p) return 1 end
function tags.loadmask(e, p)	loadmask_func(p) return 1 end
----------------------------------------
-- [exautosave]
function tags.exautosave(e, p)
	flg.exautosavetag = true	-- あとで実行する
	return 1
end
----------------------------------------
-- テキスト
----------------------------------------
--function tags.name(e, p)	mw_name(p)		return 1 end	-- 
function tags.text(e, p)	mw_text(p)		return 1 end	-- 
function tags.line(e, p)	mw_line(p)		return 1 end	-- 
function tags.rt2(e, p)		rt2()			return 1 end	-- 
function tags.nrt(e, p)		nrt()			return 1 end	-- 
function tags.gaiji(e, p)	gaiji(p)		return 1 end	-- 
function tags.exfont(e, p)	exfont(p)		return 1 end	-- 
function tags.txkey(e, p)	txkey(p)		return 1 end	-- 
function tags.tximg(e, p)	tximg(p)		return 1 end	-- 
function tags.txnb(e, p)	txnb(p)			return 1 end	-- 
function tags.txnc(e, p)	txnc(p)			return 1 end	-- 
function tags.heroname(e, p) heroname(p)	return 1 end	-- 
----------------------------------------
-- 画像
----------------------------------------
function tags.bg(e, p)		image_bg(p)		return 1 end	-- 
function tags.ev(e, p)		image_bg(p)		return 1 end	-- 
function tags.cg(e, p)		image_bg(p)		return 1 end	-- 
function tags.cgdel(e, p)	cgdel(p)		return 1 end	-- 
function tags.cgact(e, p)	tag_cgact(p)	return 1 end	-- 
function tags.fg(e, p)		image_fg(p)		return 1 end	-- 
function tags.fgf(e, p)		image_fgf(p)	return 1 end	-- 
function tags.fgact(e, p)	tag_fgact(p)	return 1 end	-- 
function tags.fgfact(e, p)	tag_fgfact(p)	return 1 end	-- 
function tags.evset(e, p)	evset(p)		return 1 end	-- 
----------------------------------------
function tags.colortone(e, p)	colortone(p)	return 1 end	-- 
function tags.cacheclear(e, p)	delImageStack("change")	return 1 end	-- 
----------------------------------------
-- media
----------------------------------------
function tags.bgm(e, p)		bgm(p)				return 1 end	-- 
function tags.movie(e, p)	movie_init(p)		return 1 end	-- 
function tags.se(e, p)		sesys_se(p)			return 1 end	-- 
function tags.vo(e, p)		sesys_vostack(p)	return 1 end	-- voice / stackする
function tags.vostop(e, p)	sesys_vostop(p)		return 1 end	-- voice stop
function tags.lvo(e, p)		sesys_lvo(p)		return 1 end	-- loop voice
--function tags.vo2(e, p)		vo2(p)		return 1 end	-- 
----------------------------------------
function tags.allsoundstop(e, p) allsound_stop(p) return 1 end
----------------------------------------
function tags.sysvo(e, p)		sysvo_func(p)	return 1 end	-- [sysvo]
function tags.sysse(e, p)		sysse(p.file)	return 1 end	-- [sysse]
function tags.se_ok(e, p)		se_ok()		 return 1 end		-- [se_ok]
function tags.se_cancel(e, p)	se_cancel()  return 1 end		-- [se_cancel]
function tags.se_active(e, p)	se_active()  return 1 end		-- [se_active]
function tags.se_none(e, p)		se_none()	 return 1 end		-- [se_none]
function tags.se_saveok(e, p)	sysvowait(p, "saveok") return 1 end		-- [se_saveok]
function tags.se_loadok(e, p)	sysvowait(p, "loadok") return 1 end		-- [se_loadok]
function tags.se_exitok(e, p)	sysvowait(p, "exitok") return 1 end		-- [se_loadok]
----------------------------------------
-- 演出
----------------------------------------
function tags.quake(e, p)	tag_quake(p) return 1 end			-- [quake]
function tags.flash(e, p)	tag_flash(p) return 1 end			-- [flash]
----------------------------------------
function tags.ex(e, p)
	local sw = {

		-- wait
		wait = function(p)
			if scr.img.buff then
				estag("init")
				estag{"image_loop"}
				estag{"eqwait", p.time}
				estag()
			else
				eqwait(p.time)
			end
		end,
	}

	local nm = p.func
	if nm and sw[nm] then
		sw[nm](p)
	else
dump(p)
	end
	return 1
end
----------------------------------------
-- 拡張
----------------------------------------
function tags.sysimg(e, p)
	local id = getImageID("sys")
	local tm = p.time or init.bg_fade

	-- 表示
	if p.file then
		local px = get_uipath()..(p.file or init.black)
		if p.ps and get_psswap() then px = px.."_x" end
		lyc2{ id=(id), file=(px), x=(p.x), y=(p.y) }
	else
		lydel2(id)
	end
	uitrans{ fade=(tm), rule=(p.rule), vague=(p.vague) }
	return 1
end
----------------------------------------
function tags.exdlg(e, p)
	local nm = p.name
	if nm then
		autoskip_disable()
		estag("init")
		estag{"exskip_stop"}
		estag{"dialog", nm}
		estag()
	end
	return 1
end
----------------------------------------
--
function tags.exclick(e, p)
--	local time = flg.automode and 5000 or 33554431
	estag("init")
	estag{"image_loop"}
--	estag{"eqwait", time}
	estag{"exclick_wait"}
	estag()
	return 1
end
----------------------------------------
function exclick_wait()
	flg.clickwait = true
	tag{"@"}
end
----------------------------------------
-- [keycode key="NAME"]
function tags.keycode(e, p)
	local k  = p.key and string.upper(p.key)
	local s  = k or "1"
	local v  = csv.advkey.list
	local z  = nil
	local no = getexclick()

	-- list
	if v[s] then
		z = {}
		for k, t in pairs(v[s]) do
			z[k] = no
		end

	-- 数値
	elseif tn(s) then
		local n = tn(s)
		if n then z = { [n] = no } end

	-- カンマ区切り
	elseif s:find(",") then
		local a = explode(",", s)
		z = {}
		for k, t in pairs(a) do
			local n = tn(t)
			if n then z[n] = no end
		end
	end

	-- 実行
	if z then
		-- ctrlskip off
		local ct = p.ctrl == "off"
		if ct then 	autoskip_ctrl() end
		flg.waitnums = z
		estag("init")
		estag{"keycode_click"}	-- key待ち
		if ct then estag{"autoskip_ctrl", true} end
		estag{"keycode_exit"}	-- key reset
		estag()
	end
	return 1
end
----------------------------------------
function keycode_click() tag{"@"} end
function keycode_exit()  flg.waitnums = nil flg.exclick  = nil end
----------------------------------------
function tags.autoplay(e, p)
	if p.mode == "stop" then
		message("通知", "autoplay停止")
		allkeyon()
		e:tag{"exec", command="automode", mode="0"}
		msg_reset()
		flg.autoplay = nil
		set_message_speed()
		autoskip_init()
		menuon()
		autoskip_stopimg()
	else
		-- autoflagが1なら飛ばせる
		local s = p.autoflag
		local m = s and tn(get_eval(s))
		if m == 1 then
			message("通知", "autoplay開始 flag:", s, m)
		else
--			if s then allkeyoff() end
			allkeyoff()			-- 入力禁止
			message("通知", "autoplay開始")
		end

		-- 文字速度と待機時間
		local sp = p.speed or init.autoplay_speed
		local dl = p.wait  or 500
		local at = p.auto  or init.autoplay_delay
		chgmsg_adv()
		set_message_speed_tween(sp, dl)
		chgmsg_adv("close")
		e:tag{"var", name="s.automodewait", data=(at)}

		-- memo:あとでsyncseを書き換える機構が必要
		menuoff()
		e:tag{"automode", allow="1", stopbyclick="0", stopbystop="0", syncse=(sesys_getvoauto())}
		e:tag{"exec", command="automode", mode="1"}
		flg.autoplay = true
		autoskip_startimg("autoplay")
	end
	return 1
end
----------------------------------------
-- global flag書き換え
function tags.systemflag(e, p)
	local n = p.name or p.exp
	local f = nil
	if n and init[n] then
		local nm = "g."..init[n]
		local fl = tn(e:var(nm))
		if fl == 0 then
			message("通知", nm, "フラグを立てます")
			tag{"var", name=(nm), data="1"}
			f = true
		end
	elseif n then
		set_eval(n)
		flg.eval = nil
		f = true
	end
	if f then asyssave() end
	return 1
end
----------------------------------------
-- 
----------------------------------------
-- フローチャート登録
function tags.flow(e, p)
	-- 開放
	local name = p["0"] or p.name
	if name then
		local c = gscr.vari[name]
		if c ~= 1 then
			message("通知", name, "を開放します")
			gscr.vari[name] = 1
			if not p.sys then asyssave() end
		end
	end

	-- 現在位置
	local pos = p.pos
	if pos then
		message("通知", "現在位置を", pos, "に設定しました")
		scr.flowposition = pos
	end
	return 1
end
----------------------------------------
