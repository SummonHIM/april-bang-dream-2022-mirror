----------------------------------------
-- config ui / 設定はadv/conf.luaに分離
----------------------------------------
local ex = {}
----------------------------------------
ex.sampletext	= "500.z.text"	-- sample text id
ex.sampletween	= "500.sample"	-- sample tween id
----------------------------------------
function conf_init()
	message("通知", "設定画面を開きました")
	sysvo("config_open")

	flg.config = { cache=conf.cache }
	flg.config.bgm = tcopy(scr.bgm)		-- bgm情報
	if not gscr.conf then gscr.conf = { page=1 } end
	if not gscr.vosave then gscr.vosave = {} end
	conf.dummy = 100
	set_langnum()		-- 言語を番号に変換

	-- ボタン描画
	config_page(gscr.conf.page)
	set_uihelp("500.z.help", "uihelp")

	uiopenanime("conf")
end
----------------------------------------
-- ボタン再描画
function conf_init2()
	config_page(gscr.conf.page)
end
----------------------------------------
-- 状態クリア
function conf_reset()
	-- 消す前にフラグを取得
	local flag = checkBtnData()
	local cfca = flg.config.cache	-- cache状態

	-- bgm戻し
	local b = flg.config.bgm or {}	-- 開いたときの再生状態
	local s = scr.bgm or {}			-- 現在の再生状態
	if not b.name and s.name then bgm_stop{} end

	-- 削除
	del_uihelp()			-- ui help
	config_textdelete()
	config_delsample()
	delbtn('conf')
	flg.config = nil
	conf.keyconf = nil

	----------------------------------------
	-- 更新があった場合の処理
	if flag and getTitle() then
		pssyssave()

	-- ゲーム画面へ
	elseif flag then
		----------------------------------------
		-- font
		local p = getTextBlock()

		-- [line]以外
		if not scr.line then
			-- 再描画
			adv_cls4(true)
			flg.mw_redraw = true
		end

		----------------------------------------
		-- MWfaceのon/off
--		local n = conf.mwface == 1 and scr.mwf
--		image_mwf(n, true)

		----------------------------------------
		-- その他設定
		conf_reload()

		----------------------------------------
		-- cache / CS機では実行しない
		local c = conf.cache
		if game.pa and cfca ~= c then
			if c == 0 then	delImageStack()
			else			autocache() end
		end
	end
end
----------------------------------------
-- 設定画面 / 再設定
function conf_reload()
	set_message_speed()		-- 文字速度書き換え
	set_volume()			-- 音量再設定
	mouse_autohide()		-- mouse
	setMWFont(true)			-- glyph再設置

	----------------------------------------
	-- mw face再描画
	local t = getTextBlock()
	faceview(t)

	----------------------------------------
	-- 裸立ち絵
	if game.pa and init.game_hadaka == "on" then
		local v = scr.img.fg
		if v then
			for i, z in pairs(v) do
				fg_hadaka_img(i, z)
			end
		end
		fg_hadaka_mwface()
	end

	----------------------------------------
	-- MWの透明度を変更する
	if scr.mw.mode then mw_alpha() end

	----------------------------------------
	-- user
	local nm = "user_configreload"
	if _G[nm] then _G[nm]() end

	----------------------------------------
	-- ctrlskip無効化
	if conf.ctrl == 0 then
		autoskip_disable()
--		autoskip_init()
	end
end
----------------------------------------
-- 設定画面から抜ける
function conf_close()
--	ReturnStack()	-- 空のスタックを削除
	message("通知", "設定画面を閉じました")
	uicloseanime("conf")
end
----------------------------------------
-- セーブ確認
function conf_savecheck()
	if checkBtnData() then
		estag("init")
		estag{"saving_func", { ["0"]="on" }}
		estag{"syssave"}
		estag{"saving_func", {}}
		estag()
	end
end
----------------------------------------
-- 
----------------------------------------
-- config／再描画
function config_resetview()
	config_default()				-- 初期化
	se_default()					-- ここでseを鳴らす
	set_langnum()					-- lang番号変換
	setWindowsScreenSize()			-- windows size
	config_page(gscr.conf.page)		-- 再表示
	flip()
	btn.renew = true
end
----------------------------------------
function config_p1() se_ok() config_page(1) flip() end
function config_p2() se_ok() config_page(2) flip() end
function config_p3() se_ok() config_page(3) flip() end
function config_p4() se_ok() config_page(4) flip() end
function config_p5() se_ok() config_page(5) flip() end
----------------------------------------
-- config／ページ切り替え
function config_page(page)
	local p  = page or 1
	local vo = gscr.conf.char or 1
	local bt = btn.cursor
	config_delsample()
	config_textdelete()
	flg.config.vsync  = nil

	-- screen mode
	if p == 1 and game.trueos == "windows" then
		e:tag{"var", name="t.screen", system="fullscreen"}
		conf.window = tn(e:var("t.screen"))
		flg.config.vsync = true
	end

	----------------------------------------
	-- ボタン描画
	local help = "config"
	if game.os == "windows" then
		local c = conf.keys[2] conf.keyconf = config_keytonum(c)		-- key
		local name = "ui_config"..p
		csvbtn3("conf", "500", lang[name])
	else
		-- android
		local c = conf.keys[153] conf.keyconf = config_keytonum(c)		-- key
		local name = "ui_config"..p
		csvbtn3("conf", "500", lang[name])
	end

	if game.wasm_os ~= 'android' then
		setBtnStat('window1', 'd')
		setBtnStat('window2', 'd')
	end

	----------------------------------------
	-- font select制御
	if p == (init.conf_page_fontselect or -1) then
		conf_fontselect()	-- font選択
	end

	----------------------------------------
	-- sample text制御
	if p == (init.conf_page_sampletext or -1) then
		conf_mwsample()		-- text sample
		config_textex()
	end

	----------------------------------------
	-- sample bgm制御
	if p == (init.conf_page_samplebgm or -1) then
		-- bgm test
		if checkBtnExist("test_bgm") then
			local b = flg.config.bgm or {}
			if b.file then setBtnStat('test_bgm', 'c') end
		end
	end

	----------------------------------------
	-- text sliderのあるページ処理(数値表示)
	local tbl = init.conf_sliderpage
	if type(tbl) == "number" then tbl = { tbl } end
	if tbl then
		for i, no in ipairs(tbl) do
			if p == no then
				config_volumenoloop()
				break
			end
		end
	end

	----------------------------------------
	-- 多言語切り替えカーソル制御
	local cl = init.game_conflangpage or 0
	if game.cs and cl == p and bt and bt:sub(1, 4) == "mark" then
		btn_active2(bt)
	end

	----------------------------------------
	-- タイトル画面
	if getTitle() and not game.cs then
		setBtnStat('bt_title', 'c')
--		tag{"lyprop", id=(getBtnID("bt_title")), visible="0"}
	end

	----------------------------------------
	-- iOSはexitボタンを封鎖
	local ox = game.os
	if ox == "ios" or ox == "wasm" then
--		setBtnStat('bt_end', 'c')
		tag{"lyprop", id=(getBtnID("bt_end")), visible="0"}
	end
	gscr.conf.page = p
end
----------------------------------------
-- text消去
function config_textdelete()
	local id = "500.z."
	local z  = init.conf_sliderlayer or {"p01","p02","p03","p04","p05","p06","p07"}
	for i, v in ipairs(z) do ui_message(id..v) end
	ui_message(ex.sampletext)
end
----------------------------------------
-- 
----------------------------------------
-- sample text
function config_textex()
	local z  = lang.sample or getLangHelp("system")
	local t0 = init.textsample
	local t1 = z.conf_text01
	local t2 = z.conf_text02
	if t0 == "on" and t1 and t2 then
		config_volumeupdate("mspeed", conf.mspeed)	-- num更新
		config_volumeupdate("aspeed", conf.aspeed)

		-- sample timeを算出するための画像
		lyc2{ id=(ex.sampletween), width="1", height="1", color="0x00ffffff", left="-20"}

		-- 初期化
		if not flg.config.tx then
			set_textfont("config01", ex.sampletext, true)
			tag{"var", system="length", name="t.s1", source=(t1), mode="1"}
			tag{"var", system="length", name="t.s2", source=(t2), mode="1"}
			local s1 = tn(e:var("t.s1"))
			local s2 = tn(e:var("t.s2"))
			local ln = get_language(true)
			if type(t1) == "table" then t1 = t1[ln] or t1.ja end
			if type(t2) == "table" then t2 = t2[ln] or t2.ja end
			flg.config.tx = {
				{ s1, t1 },
				{ s2, t2 },
			}
		end

		-- font
		local ms = getMSpeed()
		local fo = get_fontdata("config01", "adv")
		e:tag{"chgmsg", id=(ex.sampletext), layered="1"}
		e:tag{"rp"}
		if fo then e:tag(fo) end
		set_message_speed_tween(ms)
		e:tag{"/chgmsg"}

		-- 開始
		flg.config.addcount = 0
		config_samplestart(300)
	end
end
----------------------------------------
-- text start
function config_samplestart(time)
	local id = ex.sampletween
	tag{"var", id=(id), system="delete", name="t"}
	tag{"var", id=(id), system="get_layer_info", name="t.ly", style="map"}
	if e:var("t.ly.alpha") == "255" then
		tag{"lytweendel", id=(id)}
		tag{"lytween", id=(id), param="alpha", from="254", to="255", time=(time), handler="calllua", ["function"]="config_sampletext"}
	end
end
----------------------------------------
-- text clear
function config_delsample()
	tag{"lytweendel", id=(ex.sampletween)}
	tag{"chgmsg", id=(ex.sampletext)}
	tag{"rp"}
	tag{"/chgmsg"}
end
----------------------------------------
-- text
function config_sampletext()
	local v = flg.config
	if v then
		local t = v.tx
		local c = flg.config.addcount
		c = c + 1
		if c > #t then c = 1 end

		-- 表示
		e:tag{"chgmsg", id=(ex.sampletext)}
		e:tag{"rp"}
		e:tag{"print", data=(t[c][2])}
		flip()
		eqwait()
		eqtag{"/chgmsg"}

		-- timer
		local ms = getMSpeed()
		local as = getASpeed()
		local tx = ms * t[c][1] + as
		flg.config.addcount= c

		-- restart
		config_samplestart(tx)
	end
end
----------------------------------------
-- text 再開チェック
function config_sampletextcheck()
	local c = flg.config
	if c then
		local pg = gscr.conf.page or 1
		local os = game.os
		if os == "windows" and pg == 2 then
			config_sampletext()
		end
	end
end
----------------------------------------
-- サンプルウィンドウ
function config_sample()
	local p = repercent(conf.mw_alpha, 255)
	e:tag{"lyprop", id=(getBtnID("alpha")), alpha=(p)}
end
----------------------------------------
-- 
function config_samplewindow(e, p)
	if p.old and p.old ~= p.p then
		config_sample()
	end
end
----------------------------------------
-- start リセットチェック
function config_resetcheck()
	se_ok()
	dialog('reset')
end
----------------------------------------
-- ボタン制御
----------------------------------------
-- クリックされた
function config_click(e, p)		config_clickex(btn.cursor) end
function config_clickui(e, p)	config_clickex(p.bt) end
function config_clickex(bt)
	if bt then
--		ReturnStack()	-- 空のスタックを削除
--		se_ok()
--		message("通知", bt, "が選択されました")

		local v = getBtnInfo(bt)
		local n = bt:sub(1, 3)
		local p1 = v.p1
		local p2 = tn(v.p2)
		local sw = {
			-- p1 command
			page = function()
				sesys_stop("pause")
				se_ok()
--				flg.config.pause = true		-- sample textを進めない
				config_page(p2)
				uitrans()
			end,

			voice = function()	se_ok() config_voicechar(p2) end,
--			sch = function()	se_ok() config_samplevoice((gscr.conf.char or 1), p2) end,

			reset = function() config_resetcheck() end,
			title = function() adv_title() end,
			exit  = function() adv_exit() end,

			change = function()
				local nm  = v.p2
				local sw2 = {
					save  = function() adv_save() end,
					load  = function() adv_load() end,
					qload = function() flg.saveqload = true adv_load() end,
					favo  = function() flg.favoopen  = true adv_favo() end,
				}
				if sw2[nm] then se_ok() sw2[nm]() end
			end,
		}
			if n == 'btn' then config_nameclick(bt, 10)
--		elseif n == 'cha' then config_charclick(bt)
--		elseif p1 == 'page' then se_ok() config_page(p2) flip()
		elseif sw[bt] then sw[bt]()
		elseif sw[p1] then sw[p1]()
		else sysmessage("エラー", bt, "は登録されていないボタンです") end
	end
end
----------------------------------------
-- config_toggle
function config_toggle(e, p)
	local bt = btn.cursor
	if bt then
		local v = getBtnInfo(bt)
		local a = explode("|", v.p2)
		for i, nm in pairs(a) do
			setBtnStat(nm, nil)
		end

		se_ok()
		btn_clip(bt, 'clip_c')
		setBtnStat(bt, v.def)	-- 自分 disable
		btn.cursor = a[1]
		if v.def and v.p1 then saveBtnData(v.def, tn(v.p1)) end
		if v.p4 then e:tag{"calllua", ["function"]=(v.p4), name=(v.name)} end
		flip()
	end
end
----------------------------------------
-- キーコンフィグ
----------------------------------------
function config_numtokey(no)
	local tbl = { "MWOFF", "AUTO", "CONFIG", "SKIP", "LOAD", "SAVE", "FLOW" }
	return tbl[no]
end
----------------------------------------
function config_keytonum(key)
	local tbl = { MWOFF=1, AUTO=2, CONFIG=3, SKIP=4, LOAD=5, SAVE=6, FLOW=7 }
	return tbl[key]
end
----------------------------------------
function config_keyconfig02(e, p)
	local bt = p.name
	if bt then
		local v = getBtnInfo(bt)
		local n = tn(v.p1)
		if n then
			local k = game.os == "windows" and 2 or 153
			conf.keyconf = n
			conf.keys[k] = config_numtokey(n)
		end
	end
end
----------------------------------------
-- ボタン名クリック
function config_nameclick(name, add)
	se_ok()
	local v = getBtnInfo(name)
	local n = v.p1
	if n then
		local t = getBtnInfo(n)
		local c = t.com
		if c == 'toggle' then		toggle_change(n)			-- toggle
		elseif c == 'xslider' then	xslider_add(n, add) end		-- slider
		flip()
	end
end
----------------------------------------
-- 
function config_charclick(bt)
	-- サンプルボイス
	if flg.config.lock then
		if bt then
			local t  = getBtnInfo(bt)
			local nm = t.p2
			local vx = csv.voice[nm]
--			voice_stopallex(0)
--			voice_play({ ch=(nm), file=(vx.name), path=":vo/" }, true)
		end

	-- キャラボイスモード
	else
		se_ok()
		flg.config.lock = true
		if bt then
			config_vochar(bt)
			flip()
		end
	end
end
----------------------------------------
-- 戻る処理
function config_back()
	-- キャラボイスモードを抜ける
	if flg.config.lock then
		se_ok()
		flg.config.lock = nil

	-- 終了
	else
		close_ui()
	end
end
----------------------------------------
-- 
----------------------------------------
-- UP
function config_up(e, p)
	local bt = btn.cursor or 'UP'
	btn_up(e, { name=(bt) })
	config_markcheck()
	flg.config.lock = nil
end
----------------------------------------
-- DW
function config_dw(e, p)
	local bt = btn.cursor or 'DW'
	btn_down(e, { name=(bt) })
	config_markcheck()
	flg.config.lock = nil
end
----------------------------------------
-- 左キー
function config_lt(e, p)
	local bt = btn.cursor
	if flg.config.lock then
		xslider_add("sl_char", -10)
	elseif bt then
		local t  = getBtnInfo(bt)
		local cm = t.com
		if t.lt then				btn_left(e, { name=(bt) })		-- 移動
		elseif cm == "mark" then	config_markmove(-1)				-- mark
		elseif cm == "single" then	config_singlecheck(bt, "lt") -- singleボタン
		end
	end
end
----------------------------------------
-- 右キー
function config_rt(e, p)
	local bt = btn.cursor
	if flg.config.lock then
		xslider_add("sl_char", 10)
	elseif bt then
		local t  = getBtnInfo(bt)
		local cm = t.com
		if t.rt then				btn_right(e, { name=(bt) })		-- 移動
		elseif cm == "mark" then	config_markmove(1)				-- mark
		elseif cm == "single" then	config_singlecheck(bt, "rt")	-- singleボタン
		end
	end
end
----------------------------------------
-- single
function config_singlecheck(bt, dr)
	local v  = getBtnInfo(bt)
	local nm = v.def
	local no = conf[nm]
	local tb = { lt=1, rt=0 }
	if tb[dr] == no then
		se_ok()
		single_change(bt)
		btn_active2(bt)
		flip()
	end
end
----------------------------------------
-- mark
function config_markcheck()
	local bt = btn.cursor
	local t  = bt and getBtnInfo(bt)
	if t and t.com == 'mark' then
		local p1 = t.p1
		local v  = p1 and getBtnInfo(p1)
		if v.com == "toggle" then
			p1 = v.p2
			if p1:find("|") then
				local ax = explode("|", p1)
				p1 = ax[1]
			end
		end
		uihelp_over{ name=(p1) }
		flip()
	end
end
----------------------------------------
-- click / 左右カーソル共通(addの有無で判定)
config_markchange = {
	----------------------------------------
	xslider = function(bt, add) if add then se_ok() end xslider_add(bt, (add or 1)*10) end,		-- X slider
	yslider = function(bt, add) if add then se_ok() end yslider_add(bt, (add or 1)*10) end,		-- Y slider
	single  = function(bt, add) single_change(bt) end,	-- singleボタン

	----------------------------------------
	-- トグルボタン
	toggle = function(bt, add, p)
		local fl = nil
		local nm = p.def
		local dx = conf[nm]		-- 現在の値 
		local p1 = tn(p.p1)		-- 指定ボタンの値
		local p2 = p.p2			-- 指定ボタンのペア
		if p2:find("|") then
			local t1 = explode("|", p2)		-- ３個以上のトグルボタン処理
			local t2 = {}
			table.insert(t1, 1, bt)			-- 先頭のボタンを足す

			-- 各ボタンからp1の値を取り出す
			local ct = 1
			local mx = #t1
			for i, v in ipairs(t1) do
				local t = getBtnInfo(v)
				local n = tn(t.p1)
				t2[i] = n
				if n == conf[nm] then ct = i end
			end

			-- 範囲内であれば隣のボタンへ移動
			local cx = ct + (add or 1)
			if not add and cx > mx then cx = 1 end
			if cx >= 1 and cx <= mx then
				if add then se_ok() end
				local n1 = t1[ct]
				local n2 = t1[cx]
				setBtnStat(n1, nil)		-- 自分 enable
				setBtnStat(n2, nm)		-- 相棒 disable
				btn_clip(n1, 'clip')
				btn_clip(n2, 'clip_c')
				flip()

				-- save
				local t = getBtnInfo(n2)
				saveBtnData(nm, tn(t.p1))
				fl = t.p4
				bt = n2
			end
		else
			-- ボタンが左側にある
			if dx == p1 and (not add or add == 1) then
				if add then se_ok() end
				setBtnStat(bt, nil)		-- 自分 enable
				setBtnStat(p2, nm)		-- 相棒 disable
				btn_clip(bt, 'clip')
				btn_clip(p2, 'clip_c')
				flip()

				-- save
				local t = getBtnInfo(p2)
				saveBtnData(nm, tn(t.p1))
				fl = t.p4
				bt = p2

			-- ボタンが右側にある
			elseif dx ~= p1 and (not add or add == -1) then
				if add then se_ok() end
				setBtnStat(p2, nil)		-- 自分 enable
				setBtnStat(bt, nm)		-- 相棒 disable
				btn_clip(p2, 'clip')
				btn_clip(bt, 'clip_c')
				flip()

				-- save
				saveBtnData(nm, p1)
				fl = p.p4
			end
		end

		-- p4があれば実行
		if fl then e:tag{"calllua", ["function"]=(fl), name=(bt)} flip() end
	end,
}
----------------------------------------
-- mark click
function config_markclick(bt)
	if bt and get_gamemode('ui2', bt) then
		local t  = getBtnInfo(bt)		-- mark
		local bx = t.p1
		if bx then
			local v  = getBtnInfo(bx)	-- button
			local cm = v.com
			if config_markchange[cm] then config_markchange[cm](bx, nil, v) end
		end
	end
end
----------------------------------------
-- ボタン移動
function config_markmove(add)
	local bt = btn.cursor
	if bt and get_gamemode('ui2', bt) then
		local t  = getBtnInfo(bt)		-- mark
		local bx = t.p1
		if bx then
			local v  = getBtnInfo(bx)	-- button
			local cm = v.com
			if config_markchange[cm] then config_markchange[cm](bx, add, v) end
		end
	end
end
----------------------------------------
-- test voice再生(F1)
function config_f1_test(e, p)
	local bt = btn.cursor
	if bt and get_gamemode('ui2', bt) then
		local t  = getBtnInfo(bt)
		local cm = t.com
		local nm = t.p3
		if nm and cm == "mark" then
			local v = getBtnInfo(nm)
			if v then
				local ex = v.exec
				if ex then _G[ex](e, { btn=(nm) }) end
			end
		end
	end
end
----------------------------------------
-- mute(F2)
function config_f2_mute(e, p)
	local bt = btn.cursor
	if bt and get_gamemode('ui2', bt) then
		local t  = getBtnInfo(bt)
		local cm = t.com
		local nm = t.p2
		if nm and cm == "mark" then
			local v = getBtnInfo(nm)
			local cm = v and v.com
			if	   cm == "single" then se_ok() single_change(nm)
			elseif cm == "check"  then se_ok() check_change(nm) end
		end
	end
end
----------------------------------------
-- アクティブ
--[[
function config_over(e, p)
	local bt = p.name
	if bt then
		local nm = bt:sub(1, 4)
		if nm == 'char' then
			config_vochar(bt)
			flip()
		end
	end
end
]]
----------------------------------------
-- bgm/se/se2ボタン
function config_volumeadd(e, p)
	local bt = p.btn
	if bt then
		se_ok()
		local v  = getBtnInfo(bt)
		local p1 = v.p1
		local p2 = tn(v.p2)
		xslider_add(p1, p2)
	end
end
----------------------------------------
-- sample
----------------------------------------
-- sample voice / list_sysse.csvにsampleとして登録
function config_samplesound(e, p)
	-- sample
	local sample = function(nm)
		local sv = csv.sysse or {}
		local sm = sv.sample or {}
		local vo = sv.sysvo.sample or {}

		-- sample再生
		if nm and sm[nm] then
			local z = sm[nm]
			if nm == "sysvo" then
				local r  = {}
				local vv = sv.sysvo or {}
				for i, nx in pairs(z) do
					if vv[nx] then
						for i2, v2 in pairs(vv[nx]) do
							for i3, v3 in ipairs(v2) do table.insert(r, v3) end
						end
					end
				end
				z = r
			end
			local fl = z[1]
			local mx = #z
			if mx > 1 then
				local no = (e:random() % mx) + 1
				fl = z[no]
			end

			-- 再生
			local px = ":"..nm.."/"..fl..game.soundext
			sesys_play(nm, px, {})

		-- sysvo sample
		elseif not nm or vo[nm] then
			local fl = nil
			if not nm then
				local z = {}
				for i, nx in pairs(vo) do table.insert(z, i) end
				local no = (e:random() % #z) + 1
				local ch = z[no]
				local nn = (e:random() % #vo[ch]) + 1
				fl = vo[ch][nn]
				nm = ch
			else
				local no = (e:random() % #vo[nm]) + 1
				fl = vo[nm][no]
			end

			-- 再生
			if fl then
				if init.game_samplevoice == "on" then
					local px = ":sysvo/"..fl..game.soundext
					sesys_voplay({ ch=(nm), file=(px) }, "conf")
				else
					sesys_voplay({ ch=(nm), file=(fl) }, true)
				end
			else
				message("エラー", nm, fl, "が設定されていません")
			end
		else
			message("エラー", nm, "が設定されていません")
		end
	end

	-- 振り分け
	local sw = {

	bgm = function()
		local nm = nil
		local v1 = init.conf_samplebgm
		local v2 = init.titlebgm_title
		if v1 then
			if type(v1) == "table" then
				local no = (e:random() % #v1) + 1
				nm = v1[no]
			else
				nm = v1
			end
		elseif type(v2) == "table" then
			nm = v2[1]
		else
			nm = v2
		end

		-- 再生
		if nm then bgm_play{ file=(nm) } end
	end,

	voice = function() sample() end,
	se	  = function() sample("se") end,
	sysse = function() sample("sysse") end,
	sysvo = function() sample("sysvo") end,
	}
	local bt = p.btn
	if bt then
		local v  = getBtnInfo(bt)
		local nm = v.p1

		sesys_stop("pause")		-- SE一時停止

		if sw[nm] then sw[nm]() else sample(nm) end
	end
end
----------------------------------------
-- mw sample
function conf_mwsample()
	local a = conf.mw_alpha
	local p = repercent(a, 255)
	tag{"lyprop", id=(getBtnID("mw")), alpha=(p)}	-- alpha更新
	config_volumeupdate("mw_alpha", conf.mw_alpha)	-- num更新
end
----------------------------------------
-- sub menu
----------------------------------------
--[[
function config_submenu(e, p)
	local bt = p.btn
	local vx = getBtnInfo(bt)

	-- shortcut
	if bt == "short" then
		se_ok()
		csvbtn3("csub", "510", lang.ui_config13)
		flg.config.sub = { page=13 }
		uitrans()

	-- custom
	elseif bt == "custom02" then
		se_ok()
		csvbtn3("csub", "510", lang.ui_config12)
		tag{"lyprop", id="510.help", visible="0"}
		local nm = "short0"..conf.custom
		setBtnStat(nm, 'c')
		flg.config.sub = { page=12 }
		uitrans()

	-- ショートカット
	elseif bt then
		se_ok()
		csvbtn3("csub", "510", lang.ui_config11)
		tag{"lyprop", id="510.help", visible="0"}
		local p1 = tn(vx.p1)
		local p2 = tn(vx.p2)
		local mx = conf.keys[p2]
		flg.config.sub = { page=11, key=(p2) }
		for i=1, 8 do
			local nm = "short0"..i
			local v  = getBtnInfo(nm)
			if mx == v.p1 then
				setBtnStat(nm, 'c')
				break
			end
		end
		uitrans()
	end
end
----------------------------------------
-- 
function config_subclick(e, p)
	local bt = p.btn
	if bt and bt ~= "EXIT" then
		local s  = flg.config.sub
		local v  = getBtnInfo(bt)
		local p1 = v.p1

		-- shortcut
		if p1 and s.page == 11 then
			se_ok()
			conf.keys[s.key] = p1
			btn.renew = true

		-- custom
		elseif p1 and s.page == 12 then
			se_ok()
			local p1 = tn(p1)
			conf.custom = p1
			gscr.vari.custom = p1	-- 初回特典
			btn.renew = true
		end
	else
		se_cancel()
	end

	-- 画面を戻す
	delbtn('csub')
	config_page(gscr.conf.page)
	uitrans()
	flg.config.sub = nil
end
]]
----------------------------------------
-- 
----------------------------------------
-- リセット
function config_reset(e, param)
	config_default()	-- 初期化
	set_message_speed()	-- 文字速度書き換え

	-- uiの初期化
	e:tag{"lydel", id="500"}

	-- ボタン描画
	config_page(gscr.conf.page)
end
----------------------------------------
-- dialog初期化
function config_dialog(e, p)
	local v = getBtnInfo(p.name)
	local p = loadBtnData(v.def)
	if p == 1 then
		message("通知", [[dialogを再表示します]])
		config_dialogreset()
	end
end
----------------------------------------
-- 言語
----------------------------------------
-- 現在の言語をlangnumにセット
function set_langnum()
	local v = init.langnum
	if v then
		local ln = get_language(true)
		local r  = 1
		for i, z in ipairs(v) do
			if z == ln then
				conf.langnum = i
				break
			end
		end
	end
end
----------------------------------------
-- 言語変更
function conf_langchange(e, p)
	local bt = p.name
	if bt then
		local z  = init.lang
		local v  = getBtnInfo(bt)
		local p3 = v.p3
		if z[p3] then
			set_language("main", p3)	-- 保存
			flg.config.tx = nil			-- sample textクリア
			reloadSystemData()			-- システム再読み込み
			config_page(gscr.conf.page)	-- config再表示
		else
			message("通知", p3, "は不明な言語指定です")
		end
	end
end
----------------------------------------
-- font
----------------------------------------
-- font切り替え
function conf_fontselect()
	local no = conf.font or 1
	local v  = fonttable or {}
	local nm = v[no]
	if nm then
		local z = lang.uihelp.conf or {}
		if z[nm] then nm = z[nm] end
		ui_message('500.z.p99', { 'conffont', text=(nm) })
	end
end
----------------------------------------
function conf_fontdw() conf_fontadd(-1) end		-- 前へ
function conf_fontup() conf_fontadd( 1) end		-- 次へ
----------------------------------------
function conf_fontadd(add)
	local no = (conf.font or 1) + add
	local v  = fonttable or {}
	local mx = #v
	if no < 1 then no = mx elseif no > mx then no = 1 end
	conf.font = no

	se_ok()
	conf_fontselect()	-- 再設定
	config_textex()		-- sample
	btn.renew = true	-- 更新flag

	-- 保存
	conf.fontsize = flg.conf_fontsize
end
----------------------------------------
-- 
----------------------------------------
-- パッチチェック
function patch_checkfg()
	return game.os == "windows" and conf.patch == 1
end
----------------------------------------
-- パッチチェック
function patch_check()
	conf.patch = nil
	if game.os == "windows" then
		local path = "裸パッチ.ini"
		if isFile(path) then
			conf.patch = 0
		end
	end
end
----------------------------------------
