----------------------------------------
-- ADVシステム
----------------------------------------
-- ■ セーブされない
--adv = {}
----------------------------------------
-- ADV初期化
----------------------------------------
function adv_flagreset()
	flg = {}
--	adv = {}
--	setadvbtn()			-- mwボタン再設置
	scr.menu = nil		-- メニューフラグoff
	scr.fsize = getFontSize()
end
----------------------------------------
-- 全部停止
function adv_reset()
	message("通知", "adv reset")
	adv_cls4()					-- text clear
	reset_bg()					-- bg reset
	delImageStack()				-- cache delete

	allsound_stop{ time=0 }		-- 全音停止
	sesys_reset()				-- sound reset

	-- 
	sv.delpoint()				-- saveflag delete
	select_reset()				-- select reset
	mw_facedel(true)			-- mwface delete (emote用)
	menuon()					-- menu on
	mw_time()					-- mw timeを戻す
	mwline_reset()				-- line
	scr.tone = nil				-- tone color
	scr.zone = nil				-- 時間帯
	scr.novel = nil				-- novel
	scr.flowposition = nil		-- フローチャート位置情報削除

	-- user reset
	local nm = "user_advreset"
	if _G[nm] then _G[nm]() end

	-- msgoff
	msg_reset()
	autoskip_init()
	allkeyon()
end
----------------------------------------
-- 初期化
function adv_init()
	if not scr.advinit then
		message("通知", "ADVで使用するパラメータを初期化しました")

		-- uiの初期化
		e:tag{"lydel", id="500"}

--		scr.adv = {
--			title = "",		-- スクリプトのタイトル
--			stack = {},		-- スクリプトスタック
--		}

		reset_bg()		-- BG/EVリセット
--		reset_fg()		-- 立ち絵リセット
--		reset_voice()	-- 音声リセット
--		reset_delay()	-- delayリセット
--		autoskip_init()	-- autoskip有効
		init_advmw()	-- MW設置
		scr.mw.mode = "adv"
		scr.advinit = true
	end
--	bgcache("save")		-- cache clear
end
----------------------------------------
-- UI呼び出し
----------------------------------------
function adv_makepoint() sv.makepoint() end
----------------------------------------
function open_ui(name)
	if menu_check() then
		releaseStack()

		local exec = {
--			stop = true,
		}
		if not getTitle() then table.insert(exec, { "msg_hide", name}) end

		-- 開いてなかったら初期化
		if not flg.ui then
			se_ok()
			flg.ui = {}
			sesys_stop("pause")	-- SE一時停止
			autoskip_disable()	-- automode/skip停止
			advmw_clear()		-- advボタンクリア
			notification_clear()-- 通知消去
--			if name == "menu" then se_ok() end

			-- サムネイル保存 / menu|save|load
			local tbl = init.takess or { menu=1, save=1, load=1, favo=1, blog=1 }
			if tbl[name] then
				local md = init.game_takessmode or "on"
				if md == 'on' then sv.makepoint()
				else table.insert(exec, { adv_makepoint }) end
			end
		end

		-- 開いてる画面があれば閉じる
		if scr.uifunc then
			local nm = scr.uifunc
			if openui_table[nm] then
--				message("通知", nm, "を閉じます")
				table.insert(exec, { conf_savecheck })				-- config保存確認
				table.insert(exec, { openui_table[nm][2], {} })		-- ui閉じ
			end
		end
		scr.uifunc = name

		-- L/R
		setonpush_ui()

		-- 関数呼び出し
		if openui_table[name] then
--			message("通知", name, "を開きます")
			table.insert(exec, { openui_table[name][1] })
		else
			error_message(func, "は不明な関数です")
		end
		fn.push("ui", exec)
	end
end
----------------------------------------
-- ui画面から抜ける処理／共通
function close_ui()
	local name = scr.uifunc
	sv.delpoint()
	del_uihelp()

--	message("通知", name, "を閉じます")

	-- タイトル画面へ
	if getTitle() and not getExtra(true) then
		ReturnStack()			-- 空のスタックを削除
		sesys_stop("pause")		-- SE一時停止
		se_cancel()
		sysvo("return")
		estag("init")
		estag{ openui_table[name][2], name }
		estag{"title_init"}
		estag()

	-- menu以外ならmenuに戻る
	elseif name ~= 'menu' and scr.menu then
		scr.menuopen = name
		sesys_stop("pause")		-- SE一時停止
		se_cancel()
		sysvo("return")
		open_ui('menu')

	-- 閉じる
	else
		sesys_stop("pause")		-- SE一時停止
		se_cancel()
		sysvo("return")

		local s = flg.closecom	-- com
		estag("init")
		estag{ openui_table[name][3], name }
		estag{"sesys_resume"}		-- se再開
		if s ~= "adv_msgoff" then estag{"msg_show", name} end
		estag{"ui_confcheck"}		-- config check
		if s then				  estag{"closeui_go"} end
		estag()
		scr.uifunc = nil
		flg.ui = nil
	end
end
----------------------------------------
-- uiを閉じたあとテキストを再描画する
function ui_confcheck()
	local m = flg.mw_redraw
	if m then
		mw_redraw()
		flg.mw_redraw = nil
	end
end
----------------------------------------
-- 閉じたあとに呼び出す
function closeui_go()
	local nm = flg.closecom
	if nm and (not scr.select or nm == "adv_qsave" or nm == "adv_selback") then
		e:tag{"calllua", ["function"]=(flg.closecom)}
	end
	flg.closecom = nil
end
----------------------------------------
-- windows / button active処理
function reload_ui()
	if game.os ~= "windows" then
	elseif flg.ui then
		button_autoactive()		-- UI
	elseif scr.select then
		select_refresh()		-- 選択肢
		init_adv_btn() flip()	-- ボタン設置
	else
		init_adv_btn() flip()	-- ボタン設置
	end
end
----------------------------------------
function adv_backlog()	open_ui('blog')	end
function adv_config()	open_ui('conf') end
function adv_save()		if not getExtra() then open_ui('save') end end
function adv_load()		if not getExtra() then open_ui('load') end end
--function adv_menu()		open_ui('menu')	end
function adv_manual()	open_ui('mnal')	end

function adv_cgmode()	open_ui('cgmd')	end
function adv_scene()	open_ui('scen')	end
function adv_bgmmode()	open_ui('bgmd')	end
function adv_evmode()	open_ui('exev')	end

function adv_menu()		open_ui('menu')	end
----------------------------------------
function adv_flow()
	if not getExtra() and flow_check() then
		open_ui('flow')
	end
end
----------------------------------------
-- ボタン動作
function call_ui(name, flag)
	if menu_check() then
		local bt = btn.cursor
		se_ok()
		advmw_clear()			-- advボタンクリア
		notification_clear()	-- 通知消去
		if not flg.ui then advmw_clear() end
		if flag == "func" then
			if _G[name] then _G[name]()
			else error_message(name.."は実行できない関数です") end
		elseif flag == "ast" then
			tag{"jump", file="system/ui.asb", label=(name)}
		else
			flg.btnactive = bt
			dialog(name)
		end
--	else se_none()
	end
end
----------------------------------------
function adv_click()	setexclick() end				-- CLICK
function adv_exit()		call_ui("exit")  end			-- exit
function adv_s_back()	call_ui('sceneback', 'ast') end	-- sceneback
function adv_msgoff()	call_ui("msgoff", 'ast') end	-- MW OFF
--function adv_manual()	call_ui("manual", true) end		-- manual
function adv_info()		call_ui("info", 'ast')  end		-- info
function adv_auto()		adv_autostart() end				-- automode
function adv_skip()		adv_skipstart() end				-- skipmode
function adv_screen()	windowmax() end					-- fullscreen / window
----------------------------------------
-- title
function adv_title()
	if getExtra() then
		local nm = init.game_sceneexit or "scene"
		if nm == "title" then
			titlepage = nil
		end
		call_ui(nm)
	else
		call_ui("title")
	end
end
----------------------------------------
-- auto/skip用
function autoskip_check()
	local ret = nil
	if menu_check() then
		if not scr.select and not flg.skipmode and not flg.automode then ret = true end
--	else
--		se_none()
	end
	return ret
end
----------------------------------------
-- auto開始
function adv_autostart()
	if scr.select then return end
	advmw_clear()		-- advボタンクリア
	if autoskip_check() then
		se_ok()
		automode_start()
	end
end
----------------------------------------
-- skip開始
function adv_skipstart()
	if autoskip_check() then
		if flg.ex2skip then
			se_ok()
			flg.ex2skip = nil
			advmw_clear()					-- advボタンクリア
			allsound_stop{ time="500" }		-- sount停止

			-- 画像
			local fl = init.debug_exskip
			if fl and fl:sub(1, 1) ~= ":"   then fl = get_uipath()..fl
			elseif not fl or not isFile(fl) then fl = init.black end
			lyc2{ id="zzamask", file=(fl)}

			-- 呼び出し
			e:tag{"jump", file="system/ui.asb", label="exskip"}

		elseif scr.areadflag or conf.messkip == 1 then
			se_ok()
			advmw_clear()			-- advボタンクリア
			skipmode_start()
		else
			advmw_clear("sp")		-- advボタンクリア
			se_none()
			notify('unread')		-- 未読です
		end
	end
end
----------------------------------------
function adv_exskipstart()
	ResetStack()	-- スタックリセット
	flg.exskip = true
	e:debugSkip{ index=99999 }
end
----------------------------------------
-- qsave
function adv_qsave()
	if getExtra() then
		message("通知", "シーンモードではqsaveできません")
	elseif menu_check() then
		scr.autosave = nil
		sv.makepoint()
		call_ui("qsave")
	end
end
----------------------------------------
-- qload
function adv_qload()
	advmw_clear("sp")			-- advボタンクリア
	if getExtra() then
		message("通知", "シーンモードではqloadできません")
	elseif menu_check() then
		if quickloadCheck() then
			call_ui("qload")
		else
			se_none()
			notify('noqsave')	-- 'クイックセーブのデータがありませんでした
		end
--	else
--		se_none()
	end
end
----------------------------------------
function adv_cont()
	advmw_clear("sp")			-- advボタンクリア
	if getExtra() then
		message("通知", "シーンモードでは使用できません")
	elseif menu_check() then
		if not sv.checkopen("cont") then
			call_ui("cont")
--		title_load()
		else
			se_none()
			notify('nocont')	-- 'セーブデータがありませんでした
		end
	end
end
----------------------------------------
-- お気に入りボイス
function adv_favoopen() flg.favoopen = true adv_favo() end
function adv_favo()
	advmw_clear("sp")			-- advボタンクリア
	if menu_check() then
		-- favo画面を開く
		if flg.favoopen then
			flg.favoopen = nil
			flg.favo = nil
			open_ui('favo')

		-- ゲーム画面から呼び出された(保存)
		elseif table.maxn(scr.voice.stack) > 0 then
			local v = getTextBlockText()	-- テキスト取得
			local z = log.stack[#log.stack]
			v.face  = tcopy(z.face)
			flg.favo = v
			open_ui('favo')

		-- データがなかった
		else
			se_none()
			notify('novoice')				-- ボイスがありませんでした
		end
	end
end
----------------------------------------
-- pico設定
function adv_mwconf()
	advmw_clear("sp")			-- advボタンクリア
	if menu_check() then
		autoskip_disable()		-- automode/skip停止
		notification_clear()	-- 通知消去
		mwconf_init()
	end
end
----------------------------------------
-- 前の選択肢に戻る
function adv_selback()
	if init.game_selback == "on" and menu_check() then
		advmw_clear("sp")				-- advボタンクリア
		if getExtra() and init.game_scene_sback == "on" then
			notify('noscene')			-- シーン鑑賞では実行できません
		else
			local s = getBselPoint()
			if s > 0 then
				call_ui("back")
			else
				se_none()
				notify('nobacksel')		-- これ以上戻れません
			end
		end
	end
end
----------------------------------------
-- 次の選択肢に移動
function adv_selnext()
	if init.game_selnext == "on" and menu_check() then
		advmw_clear("sp")				-- advボタンクリア
		if getExtra() and init.game_scene_snext == "on" then
			notify('noscene')			-- シーン鑑賞では実行できません
		else
			if autoskip_check() then
				if scr.areadflag or conf.messkip == 1 then
					call_ui("next")
				else
					se_none()
					notify('unread')	-- 未読です
				end
			end
		end
	end
end
----------------------------------------
-- 
function adv_tweet()
	if getExtra() then
		se_none()
		notify('tweetscene')	-- シーンモードではツイートできません
	elseif scr.scenearea then
		se_none()
		notify('tweeth')		-- Ｈシーンではツイートできません
	else
		call_ui("tweet")
	end
end
----------------------------------------
-- 
function adv_suspend()
	if getExtra() then
		se_none()
		notify('noscene')		-- シーン鑑賞では実行できません
	else
		call_ui("sus")
--		se_ok()
--		if not flg.ui then advmw_clear() end
--		sv.suspend()
	end
end
----------------------------------------
function adv_mute()
	if menu_check() then mwdock_mute() end
end
----------------------------------------
-- 左フリック座標チェック / 右だけメニューになる
function adv_lflick()
	if menu_check() then
		local n = init.game_flickmenu == "on"
		local m = flg.m or e:getMousePoint()
		local p = m.x >= game.width - game.flickarea
		if p and getMWDockDir("rt") then
			flg.mwsplock = true
			mwdock_show()
		elseif p and n then
			adv_menu()
		else
			adv_msgoff()
		end
	end
end
----------------------------------------
-- 上フリック座標チェック / 下だけメニューになる
function adv_upflick()
	if menu_check() then
		local m = flg.m or e:getMousePoint()
		local s = mulpos(init.menu_areapx or 100)
		if m.y >= game.height - s and getMWDockDir("dw") then
			flg.mwsplock = true
			scr.mwhide = true
			mwdock_show()
		else
			adv_backlog()
		end
	end
end
----------------------------------------
-- ボイスリプレイ
function adv_replay()
	advmw_clear("sp")		-- advボタンクリア
	if menu_check() then
		-- スタックに音声があったらリプレイ
		if table.maxn(scr.voice.stack) > 0 then
			-- automode中なら停止する
			autoskip_stop()
			sesys_voreplay(scr.voice.stack)
	
		else
			se_none()
			notify('novoice')	-- ボイスがありませんでした
		end
	end
end
----------------------------------------
-- MW dock
function adv_dock()
	if menu_check() then
		se_ok()
		mwdock()
	end
--	call_ui("mwdock", 'func')
end
----------------------------------------
function adv_dummy()
	message("通知", "何もしない")
end
----------------------------------------
-- windows
----------------------------------------
-- windows / OSボタン設定
function window_button()
	if game.os == "windows" then
		if init.window_maxwindow == "on" then e:tag{"var", name="s.enablemaximizedwindow", data="1"} end	-- 最大化フラグ
		local b1 = init.window_close
		local b2 = init.window_max
		local b3 = init.window_min
		if b1 then e:tag{"setonwindowbutton", button="0", handler="calllua", ["function"]=(b1)}
		else	   e:tag{"setonwindowbutton", button="0", handler="calllua", ["function"]="windowclose_default"} end
		if b2 then e:tag{"setonwindowbutton", button="1", handler="calllua", ["function"]=(b2)} end
		if b3 then e:tag{"setonwindowbutton", button="2", handler="calllua", ["function"]=(b3)} end
	end
end
----------------------------------------
-- ×ボタン / 初期値
function windowclose_default()
	saveWindowsSize()			-- windowsサイズ保存
	store(e, { file="exit" })	-- 変数を変換しておく
	tag{"exit"}
end
----------------------------------------
-- ×ボタン
function windowclose()
	if not gameexitflag then
		if get_dlgparam("exit") == 0 then
			se_ok()
--			tag{"call", file="system/ui.asb", label="windowclose"}
			local v  = getLangHelp("dlgmes")
			local tl = v and v.check or "確認"
			local ms = v and v.exit  or "ゲームを終了しますか？"
			tag_dialog({ varname="t.yn", title=(tl), message=(ms)}, "windowclose_next")
		else
			sv.go_exit()
		end
	end
end
----------------------------------------
function windowclose_next()
	local yn = tn(e:var("t.yn"))
	if yn == 1 then
		se_ok()
		sv.go_exit()
	else
		se_cancel()
	end
end
----------------------------------------
-- 
----------------------------------------
-- カーソル追尾
function mouse_autocursor(name, time)
	if game.os == "windows" and conf.mouse == 1 then
--		local tbl = { 3,3,3,3,3,4,5,7,10,15 }
		local tbl = { 0.05, 0.05, 0.05, 0.05, 0.05, 0.07, 0.10, 0.13, 0.19, 0.26 }
		local m = e:getMousePoint()
		local v = getBtnInfo(name)
		local x = v.x + math.floor(v.w / 2)
		local y = v.y + math.floor(v.h / 2)
		local t = time or 60

		-- 計算
		local c  = 0
		local fx = math.floor((x - m.x) / 10)
		local fy = math.floor((y - m.y) / 10)
		for i=1, 10 do
			local tx = math.floor(t * tbl[i])
			eqtag{"calllua", ["function"]="mouse_autocursorlp", x=(fx), y=(fy)}
			eqwait(tx)
			c = c + tx
		end
		if c < time then eqwait(time - c) end
		eqtag{"calllua", ["function"]="mouse_autocursored", name=(name)}
	end
end
----------------------------------------
function mouse_autocursorlp(e, p)
	local m = e:getMousePoint()
	tag{"mouse", left=(m.x + p.x), top=(m.y + p.y)}
end
----------------------------------------
function mouse_autocursored(e, p)
	btn_active2(p.name)
	flip()
end
----------------------------------------
-- info
----------------------------------------
function advinfo_init()
	flg.ui = {}

	message("通知", [[infoを表示します]])

	-- info生成
	local h  = init.info_header
	local tx = init.trial and init.trial_title or init.game_title
	local info	= tx..h[1]..game.ver.."\n"
	info = info..h[2]..init.game_year.." "..init.game_author.."\n\n"
	info = info..e:var("s.copyright").."\n"

	local f = init.info_footer
	if f and e:isFileExists(f) then
		local s = e:file(f)
		for a, z in ipairs(split(s, "\r\n")) do
			info = info..code_utf8(z).."\n"
		end
	end

	local is = init.info_status
	flg.info = {
		text  = split(info, "\n"),
		max   = 0,
--		page  = 0,
--		count = 0,
		line  = is[1]
	}
	flg.info.max  = table.maxn(flg.info.text)
--	flg.info.page = math.floor(flg.info.max / flg.info.add) + 1

	set_textfont("info", "info.1")
	e:tag{"chgmsg", id="info.1", layered="0"}
--	e:tag{"rp"}

	-- show
	e:tag{"scetween", mode="init", type="in"}
	e:tag{"scetween", mode="add" , type="in",  param="alpha",  time=(is[2]), delay=(is[3]), diff="-255", ease="none"}
	e:tag{"scetween", mode="add" , type="in",  param="left",   time=(is[2]), delay=(is[3]), diff="40",   ease="easeout_quad"}
	e:tag{"scetween", mode="add" , type="in",  param="top",    time=(is[2]), delay=(is[3]), diff="20",   ease="easeout_quad"}
	e:tag{"scetween", mode="add" , type="in",  param="xscale", time=(is[2]), delay=(is[3]), diff="600",  ease="easein_quad"}
	e:tag{"scetween", mode="add" , type="in",  param="yscale", time=(is[2]), delay=(is[3]), diff="600",  ease="easein_quad"}
	e:tag{"scetween", mode="add" , type="in",  param="rotate", time=(is[2]), delay=(is[3]), diff="180",  ease="easeout_quad"}

	-- hide
	e:tag{"scetween", mode="init", type="out"}
	e:tag{"scetween", mode="add" , type="out", param="alpha",  time=(is[4]), delay=(is[5]), diff="-255", ease="none"}
	e:tag{"scetween", mode="add" , type="out", param="xscale", time=(is[4]), delay=(is[5]), diff="800",  ease="easeout_quad"}
	e:tag{"scetween", mode="add" , type="out", param="yscale", time=(is[4]), delay=(is[5]), diff="-100", ease="easeout_quad"}
	e:tag{"/chgmsg"}
	e:tag{"chgmsg", id="info.1", layered="0"}
end
----------------------------------------
-- info loop
function advinfo_loop(e, p)
	local v = flg.info
	local c = v.count or 1
	local p = v.page  or 0
	local m = v.line

	e:tag{"rp"}
	for i=1, m do
		e:tag{"print", data=(v.text[p+i])}
		e:tag{"rt"}
	end
--	eqwait{ scenario="1" }
	eqwait()

	-- 計算
	local f = 1
	flg.info.page = p + m
	if flg.info.page > v.max then f = 0 end
	e:tag{"var", name="t.exit", data=(f)}
end
----------------------------------------
-- info抜ける
function advinfo_exit(e, param)

	message("通知", "infoを終了します")

	e:tag{"rp"}
	e:tag{"/chgmsg"}
	flg.info = nil
	flg.dlg = nil
end
----------------------------------------
