----------------------------------------
-- config / UI以外の固定動作
----------------------------------------
-- message
----------------------------------------
function getMSpeed()
	local ms = 100 - conf.mspeed
	if conf.fl_mspeed == 0 then ms = 0 end
	return ms
end
----------------------------------------
function getASpeed()
	local sp = init.automode_speed	-- 基本待機時間
	local mg = init.automode_magni	-- 基本倍率
	if type(sp) == "table" then
		mg = sp[2] or mg
		sp = sp[1]
	end
	local as = (100 - conf.aspeed) * mg + sp
	if conf.fl_aspeed == 0 then as = init.autooff_speed end
	return as
end
----------------------------------------
-- メッセージ速度を設定する
function set_message_speed()
	local ms = getMSpeed()

	if game and game.mwid then
		-- adv text
		tag{"chgmsg", id=(mw_getmsgid("adv")), layered="1"}
		set_message_speed_tween(ms)
		tag{"/chgmsg"}

		-- adv text / sub language
		if init.game_sublangview == "on" then
			tag{"chgmsg", id=(mw_getmsgid("sub")), layered="1"}
			set_message_speed_tween(ms)
			tag{"/chgmsg"}
		end
	end

	-- オート速度を設定する
	e:tag{"var", name="s.automodewait", data=(getASpeed())}
end
----------------------------------------
function set_message_speed_tween(delay, time, diff)
	local tm = time or init.game_messagetime
	local df = diff or init.game_messagedown
	e:tag{"scetween", mode="init", type="in"}
	e:tag{"scetween", mode="add" , type="in", param="alpha", ease="none", time=(tm), delay=(delay), diff="-255"}
	if df and conf.mspeed < 100 and conf.fl_mspeed == 1 then
	e:tag{"scetween", mode="add" , type="in", param="top",   ease="none", time=(tm), delay=(delay), diff=(df), ease="easeout_quad"}
	end
end
----------------------------------------
-- 音量計算
----------------------------------------
-- ボリュームを設定する
function set_volume()
	volume_master()
	volume_bgm()
	volume_movie()
end
----------------------------------------
-- マスター音量を計算する
function volume_master()
	volume_bgm()
	volume_movie()

	-- SE Master
	local ans = volume_count("master", conf.master, init.config_volumemax)
	e:tag{"var", name="s.sevol", data=(ans)}
end
----------------------------------------
-- BGMの音量を計算する
function volume_bgm()
	local ans = volume_count("bgm", conf.master, conf.bgm, init.config_bgmmax)
	e:tag{"var", name="s.bgmvol", data=(ans)}
end
----------------------------------------
-- movieの音量を設定する
function volume_movie()
	if not game.ps then
		local ans = volume_count("movie", conf.master, (conf.movie or conf.bgm), (init.config_moviemax or init.config_bgmmax))
		e:tag{"var", name="s.videovol", data=(ans)}
	end
end
----------------------------------------
-- volume計算
function volume_count(name, ...)
	local r = 1000
	local c = conf.fl_master == 0 and 0 or conf["fl_"..name]
	if c and c == 0 then
		r = 0
	else
		local t = { ... }
		local m = #t
		local c = 100
		for i, v in ipairs(t) do
			if i == 1 then	r = t[i]
			else			r = r * t[i] / 100 end
		end
		r = math.ceil(r * 10)
		if r > 1000 then r = 1000 end
	end
	return r
end
----------------------------------------
-- volume slider
function config_volume(e, p)
	local tbl = { master="volume_master", bgm="volume_bgm", movie="volume_movie" }

	-- 呼び出し
	local func = function(nm)
		-- artemis変数を書き換える
		if tbl[nm] then
			_G[tbl[nm]]()

		-- sefadeで処理
		else
			sesys_voslider(nm)
		end
	end

	-- ボタン判定
	local bt = p.name
	if bt then
		local v  = getBtnInfo(bt)
		local nm = v.def
		local nx = nm:gsub("fl_", "")

		-- main
		func(nx)

		-- sub
		local s = init["confvol_"..nx]
		local n = conf[nm]
		local f = nm:find("fl_")
		if s then
			if type(s) == "string" then s = { s } end
			for i, z in ipairs(s) do
				if f then conf["fl_"..z] = n
				else	  conf[z] = n end
				func(z)
			end
		end

		-- no
		config_volumeno(bt)
	end
end
----------------------------------------
-- volume num
function config_volumeno(bt)
	local v  = getBtnInfo(bt)
	local p3 = v.p3
	if p3 then
		local nm = v.def:gsub("fl_", "")
		local no = conf[nm]
		if conf["fl_"..nm] == 0 then no = init.conf_mutetext or "off" end

		local ax = explode("|", p3)
		local x  = v.x
		local y  = v.y
		if ax[3] then
			local z = getBtnInfo(ax[3])
			x = z.x
			y = z.y
		end
		local id = "500.z."..ax[2]
		ui_message(id, { ax[1], text=(no) })
		tag{"lyprop", id=(id), left=(x), top=(y)}
	end
end
----------------------------------------
function config_volumenoloop()
	local nm = btn.name
	if nm and btn[nm] then
		for i, v in pairs(btn[nm].p) do
			if v.com == "xslider" then
				config_volumeno(i)
			end
		end
	end
end
----------------------------------------
function config_volumeupdate(bt, tx)
	local v  = getBtnInfo(bt)
	local p3 = v.p3
	if p3 then
		local ax = explode("|", p3)
		local id = "500.z."..ax[2]
		ui_message(id, tx)
	end
end
----------------------------------------
-- dialog
----------------------------------------
-- dialog on/off切り替え
function config_dialogset(e, p)
	local no = conf.dlg_all
	config_dialogreset(no)
	sys.dlgreset = nil
end
----------------------------------------
-- dialogを出すかどうか確認するテーブル
function config_dialogreset(no)
	local t = init.dlg
	local b = {}
	for k, v in pairs(t) do
		local nm = v.name
		if v.mode == "yesno" and not b[nm] then
			local df = v.def
			local dt = df == 0 and no or df
			conf[nm] = dt
			b[nm] = true
--			message(nm, dt)
		end
	end
end
----------------------------------------
-- confからdialogパラメータを取得
function get_dlgparam(name)
	local r = nil
	local t = init.dlg[name]
	if init.game_exdialog ~= "on" and name:find("ex[0-9]+") then
--		message(name, "はon/off設定がありません")
	elseif conf.dlg_all == 1 then
		r = 1
	elseif t then
		r = conf[t.name]
	end
	return r
end
----------------------------------------
-- confにdialogパラメータを書き込む
function set_dlgparam(name, no)
	local t = init.dlg[name]
	if t then conf[t.name] = tn(no) end
end
----------------------------------------
-- 初期化
----------------------------------------
function config_default()
	local ln = get_language(true)

	message("通知", "設定を初期化しました")

	----------------------------------------
	-- バッファクリア
	local osx = game.os
	local def = conf and conf.dlg_reset
	local dck = sys  and sys.dlgreset
	conf = {}
	config_dialogreset()
	conf.keys = {}		-- keyconfig [key] = name
	if def and dck then conf.dlg_reset = def end

	----------------------------------------
	-- text
	conf.autostop	= init.config_autostop or 1		-- オートモード時音声待機
	conf.autoclick	= init.config_autoclick or 0	-- オートモード時クリック動作
	conf.glyph		= init.config_glyph or 1		-- glyph表示
	conf.font		= init.config_fonttype or 1		-- フォント変更
	conf.shadow		= init.config_textshadow or 1	-- 文字の影
	conf.outline	= init.config_textoutline or 1	-- 文字の縁

	-- message window
	conf.mw_alpha	= init.config_mw_alpha			-- ウインドウ濃度
	conf.mw_aread	= init.config_mw_aread			-- テキスト既読色
	conf.mwface		= init.config_mw_face			-- 立ち絵が出てるface絵のon/off
	conf.mwhelp		= init.config_mw_help			-- mwbtn help
	conf.aread_fast	= init.config_aread_fast or 0	-- 既読時瞬間表示
	conf.aread_skip	= init.config_aread_skip or 0	-- 既読時スキップ
	conf.aread_icon	= init.config_aread_icon or 0	-- 既読アイコン
	conf.dock		= init.config_mw_dock			-- dock
	conf.mwbg_r		= init.config_mwbg_r			-- MW背景色／赤
	conf.mwbg_g		= init.config_mwbg_g			-- MW背景色／緑
	conf.mwbg_b		= init.config_mwbg_b			-- MW背景色／青

	conf.bgname		= init.config_bgname			-- 場所名				0:なし	1:あり
	conf.bgmname	= init.config_bgmname			-- 曲名					0:なし	1:あり
	conf.notify		= init.config_notify or 1		-- 通知					0:なし	1:あり

	-- select / skip
	conf.ctrl		= init.config_ctrl				-- ctrlキー
	conf.exskip		= init.config_sceneskip			-- シーンスキップ
	conf.messkip	= init.config_areadskip			-- メッセージスキップ既読設定
	conf.skip		= init.config_sel_skip			-- 選択肢後のスキップ継続
	conf.auto		= init.config_sel_auto			-- 選択肢後のオート継続
	conf.selcolor	= init.config_sel_color			-- 選択肢の文字色
	conf.finish01	= init.config_finish01			-- 挿入時				0:膣内	1:外	2:選択
	conf.finish02	= init.config_finish02			-- フェラ				0:口内	1:顔面	2:選択

	-- graphic
	conf.window		= init.config_window			-- windows専用 / 画面モード
	conf.winsize	= init.config_winsize			-- windows専用 / 画面サイズ			x_y
	conf.winvmr		= init.config_winvmr			-- windows専用 / VMR再生方式を切り替える
	conf.effect		= init.config_effect			-- 画面効果
	conf.sysani		= init.config_sysani or 1		-- 画面効果 / システム

	-- save system
	conf.qsave		= init.config_qsave or 0		-- qsave / qload
	conf.asave		= init.config_asave				-- オートセーブ / [autosave]タグ
	conf.selsave	= init.config_asave_select		-- オートセーブ / 選択肢
	conf.savenew	= init.config_save_newicon		-- new icon on/off

	-- system
--	conf.rclick		= init.config_rclick			-- 右クリック動作
	conf.dialogact	= init.config_dialogactive		-- 自動カーソルでアクティブにするボタン
	conf.mouse		= init.config_autocursor		-- 自動カーソル
	conf.cursor		= init.config_autohide			-- 自動消去
	conf.scback		= init.config_textback			-- テキストバック

	----------------------------------------
	-- soundとslider
	local tbl = {
		mspeed	= "config_mspeed",			-- メッセージ速度	- slider
		aspeed	= "config_aspeed",			-- オートモード速度 - slider

		master	= "config_volume",			-- マスター音量
		bgm		= "config_bgm",				-- BGM
		se		= "config_se",				-- SE
		voice	= "config_voice",			-- Voice
		sysse	= "config_sysse",			-- SysSe
		sysvo	= "config_sysvo",			-- SysVoice
		movie	= "config_movie",			-- movie
		lvo		= "config_bgv",				-- BGV音量
		bgmvo	= "config_bgm_voice",		-- ボイス再生時のBGM音量
	}
	for nm, tx in pairs(tbl) do
		local s = init[tx]
		if s then
			conf[nm] = s
			conf["fl_"..nm] = 1
		end
	end

	-- 各キャラボイスのon/offはvoice_tableから取得する	0:off 1:on
	local lvo = init.game_bgvvolume == "on"
	for nm, v in pairs(csv.voice) do
		if v.id and not v.mob then
			conf[nm] = 100
			conf["fl_"..nm] = 1
			if lvo then
				conf["lvo"..nm] = init.config_bgv	-- bgv音量を個別に持つ
				conf["fl_lvo"..nm] = 1
			end
		end
	end
	conf.voiceskip	= init.config_voiceskip			-- 1:on 0:off クリックで音声を停止する
	conf.voicepan	= init.config_voicepan			-- 1:on 0:off 

	-- system voice
	local z = csv.sysse.sysvo.charlist
	if z then
		for i, v in ipairs(z) do conf["svo_"..v] = 1 end
	end

	-- secat
	local z = init.secat
	if z then
		for nm, v in pairs(z) do
			local vo = v.vol or 100
			conf[nm] = vo
			conf["fl_"..nm] = 1
		end
	end

	----------------------------------------
	-- cache / smartphoneのみ初期値0
	local r = init.system.autocache			-- cache mode : none/small/middle/large
	local m = init.system.cachemax or 500
	local c = game.sp == 0 or 1
	conf.cache		= c			-- 0:off 1:on
	conf.cachemode	= r			-- none/small/middle/large
	conf.cachelevel = 100		-- 0～100%
	conf.cachemax	= m			-- cacheファイル数最大値

	----------------------------------------
	-- tablet
	local t1 = init.config_tablet					-- タブレットモード
	local t2 = init.config_tabletui					-- タブレットUI
	if osx == "windows" then
		local tb = tn(e:var("s.windowstouch"))		-- 対応有無を取得
		if not t1 then t1 = tb end
		if not t2 then t2 = tb end
	elseif game.sp then t1 = 1						-- スマホ設定
--	elseif osx == "switch"  then t1 = 1
	end
	conf.tablet		= t1							-- タブレットモード
	conf.tabletui	= t2							-- タブレットUI

	----------------------------------------
	-- 言語
	lang_confreset(ln)

	----------------------------------------
	-- 拡張
	if _G.user_conf then _G.user_conf() end

	----------------------------------------
	-- debug設定があれば上書きする
	if debug_flag then debug_configinit() end

	----------------------------------------
	-- キーショートカット(キー番号管理)
	for i=1, init.max_keyno do
		local k = init["config_key"..i]
		if k then conf.keys[i] = k end
	end

	----------------------------------------
	-- windowsかつフルサイズのときは上書き
	e:tag{"var", name="t.screen", system="fullscreen"}
	local s = tn(e:var("t.screen"))
	if osx == "windows" and s == 1 then
		conf.window = 1
	end

	----------------------------------------
	set_volume()		-- ボリュームを設定する
	set_message_speed()	-- メッセージ速度を設定する

	-- lua側システム変数のセーブ
--	asyssave()
end
----------------------------------------
