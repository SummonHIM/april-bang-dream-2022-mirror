----------------------------------------
-- 初期化
----------------------------------------
-- ■ lua読み込み
function system_loadinglua()
	e:tag{"skip",		allow="0"}	-- 停止しておく
	e:tag{"automode",	allow="0"}	-- 停止しておく
	e:tag{"autosave",	allow="0"}	-- 停止しておく

	-- luaの登録
	local luafile = {
		-- system
		"adv/var",			-- 内部変数
		"adv/fileio",		-- ファイル入出力 / system
		"adv/fsave",		-- ファイル入出力 / saveload
		"adv/parse",		-- parse csv
		"adv/func",			-- 汎用関数群
		"adv/wasm",			-- wasm

		-- base system
		"adv/system",		-- システム制御
		"adv/conf",			-- システム初期動作
		"adv/mainloop",		-- スクリプト制御
		"adv/vsync",		-- vsync制御
		"adv/autoskip",		-- auto/skip制御
		"adv/button",		-- ボタン制御
		"adv/select",		-- 選択肢制御
		"adv/keyconfig",	-- keyconfig制御
		"adv/keyevent",		-- system event制御
		"adv/quickjump",	-- quickjump制御

		-- game system
		"adv/adv",			-- ADV制御
		"adv/delay",		-- delay制御

		-- message
		"msg/message",		-- メッセージ制御
		"msg/line",			-- メッセージ制御 / LINE
		"msg/lang",			-- メッセージ多言語
		"msg/mw",			-- メッセージウィンドウ
		"msg/ui",			-- UIメッセージ
		"msg/tablet",		-- タブレットUI

		-- image
		"image/boot",		-- 起動関連
		"image/image",		-- 画像汎用
		"image/image_sys",	-- system
		"image/image_bg",	-- BG/EV/CG
		"image/image_fg",	-- 立ち絵
--		"image/e-mote",		-- 立ち絵 / E-mote
		"image/image_act",	-- アクション制御
		"image/shader",		-- シェーダー
		"image/cache",		-- キャッシュ制御

		-- media
		"media/bgm",		-- BGM
		"media/se",			-- SE / Voice
		"media/sysse",		-- SystemSE
		"media/movie",		-- 動画

		-- script
		"extend/adv_mw",	-- ADV MW制御
		"extend/user",		-- user
		"extend/script",	-- スクリプトタグ管理
--		"extend/trophy",	-- PS Trophy

		-- ui
		"ui/menu",			-- 右クリックメニュー制御
		"ui/backlog",		-- バックログ制御
--		"ui/sceneback",		-- シーンバック制御
		"ui/config",		-- config制御
		"ui/conf_mw",		-- pico config制御
		"ui/save",			-- save/load制御
		"ui/favo",			-- お気に入りボイス制御
		"ui/dialog",		-- dialog制御
		"ui/title",			-- タイトル画面

		-- extra
		"extra/extra",		-- 鑑賞共通
		"extra/cg",			-- おまけCG
		"extra/scene",		-- おまけシーン
		"extra/bgm",		-- おまけBGM
		"extra/etc",		-- おまけその他
	}

	-- lua読み込み
	for i, val in ipairs(luafile) do
		local file = 'system/'..val..'.lua'
		if e:isFileExists(file) then
			e:include(file)
		else
			e:debug(file)
		end
	end
	allkeyoff()				-- 入力停止

	----------------------------------------
	-- OSとバージョン
	game = { path={} }
	e:tag{"var", name="t.os", ["system"]="os"}
	local nm = e:var("t.os")
	if nm == "iphone" then nm = "ios" end			-- iOSは名前を書き換えておく
	if nm == "webassembly" then nm = "wasm" end		-- WebAssemblyは名前を変えておく
	game.os		= nm
	game.trueos = nm

	-- 画面サイズ
	e:tag{"var", name="t.w", ["system"]="screen_width"}
	e:tag{"var", name="t.h", ["system"]="screen_height"}
	local w = tn(e:var("t.w"))
	local h = tn(e:var("t.h"))
	game.width	= w
	game.height	= h
	game.centerx = math.floor(w / 2)
	game.centery = math.floor(h / 2)

	----------------------------------------
	-- debug
	local d = "debug/lua/index.lua"
	if e:isFileExists(d) then
		e:include(d)

		-- fake OS
		local d = deb and deb.fake
		if d and game.os ~= "vita" and game.os ~= "ps4" then
			if d == 'auto' then
					if w ==  960 then d = 'vita'
				elseif w == 1920 then d = 'ps4'
				elseif w == 1280 then d = 'switch'
				else d = 'windows' end
			end
			game.os = d
		end
	end

	----------------------------------------
	-- 機種判定
	local tbl = {
		--						PS		CS		SP		touch	exit				PS		CS
		windows = { fakeos = {	nil,	nil,	nil,	true,	true }, trueos = {	nil,	nil  } },
		android = { fakeos = {	nil,	nil,	true,	true,	true }, trueos = {	nil,	nil  } },
		ios		= { fakeos = {	nil,	nil,	true,	true,	nil  }, trueos = {	nil,	nil  } },
		ps4		= { fakeos = {	true,	true,	nil,	nil,	nil  }, trueos = {	true,	true } },
		vita	= { fakeos = {	true,	true,	nil,	true,	nil  }, trueos = {	true,	true } },
		switch	= { fakeos = {	nil,	true,	nil,	true,	nil  }, trueos = {	nil,	true } },
		wasm	= { fakeos = {	nil,	nil,	true,	true,	nil  }, trueos = {	nil,	nil  } },
	}
	local gos = game.os
	local tos = game.trueos
	local os1 = tbl[gos].fakeos		-- 仮想OS
	local os2 = tbl[tos].trueos		-- 実機
	game.ps = os1[1]		-- true : PS4/Vita
	game.cs = os1[2]		-- true : CS機
	game.pa = not os1[2]	-- true : CS機以外
	game.sp = os1[3]		-- true : smartphone
	game.touch  = os1[4]	-- true : touch ok
	game.exitbtn= os1[5]	-- true : exit button ok
	game.trueps = os2[1]	-- true : PS4/Vita
	game.truecs = os2[2]	-- true : CS機
	if gos == "switch" then game.sw = true end

	----------------------------------------
	-- wasm専用
	if wasm and tos == "wasm" then wasm.init() end

	----------------------------------------
	-- 変換したcsv.lua
	local name = "list_"..gos
	e:include("system/table/"..name..".tbl")

	-- script.ini確認
	system_scriptini()

	----------------------------------------
	-- 設定
	screen_init()	-- 画面初期化
	shader_init()	-- シェーダー初期化
end
----------------------------------------
-- ■ script.ini確認
function system_scriptini()
	local px = "script.ini"
	local md = "init"
	if isFile(px) then
		local p = parseIni(px)
		for i, v in ipairs(p) do
			if v:find(";") then v = v:gsub(";.*", "") end

			-- mode
			if v:sub(1, 1) == '[' then
				local s = v:gsub("%[(.+)%].*", "%1")
				md = s

			-- init param
			elseif md == 'init' then
				local a = explode("=", v)
				if a[2] then
					if debug_flag then console("overwrite : "..a[1].." => "..a[2]) end
					init[a[1]] = a[2]
				end
			end
		end
	end
end
----------------------------------------
-- ■ データ読み込み
function system_dataloading()
	load_system()	-- $g→sys
	load_global()	-- $g→gscr
	conf = fload_pluto(init.save_config)

	-- 初回起動
	local s = init.game_savedatacheck
	if not conf then

		-- save check
		if s then sys.savecheck = s end

		-- config初期化
		config_default()

		-- 復旧を試みる
		e:tag{"var", name="t.c", system="get_exe_parameter"}
		local c = e:var("t.c.recovery")
		if c == "save" then
			message("通知", "セーブデータをの復元を試みます")

			local px = e:var("s.savepath")
			local mx = game.qsavehead
			local hd = init.save_prefix
			local c  = nil
			local t  = {}
			for i=1, mx do
				local fl = px.."/"..hd..string.format("%04d.dat", i)
				if isFile(fl) then
					table.insert( t, i )
					c = i
				end
			end
			if c then
				local z  = {}
				local d  = {}
				local mx = #t
				for i, v in ipairs(t) do
					local fl = hd..string.format("%04d", v)
					z[i] = {
						text = { text="is broken" },
						title = {},
						date = 0,
						file = fl,
					}
					d[fl] = true
				end
				sys.saveslot = z			-- slot情報
				sys.saveslot.check = d		-- 保存状態
				sys.saveslot.count = c		-- 使用数
			end
		end

	-- 初回以外
	else
		-- セーブデータのver確認
		if s and sys.savecheck ~= s then
			tag_dialog({ title="error", message="Bad savedata." }, "exit")

		-- configのデータが壊れていたら初期化する
		elseif conf and ( not conf.bgm or not conf.se or not conf.voice or not conf.aspeed or not conf.mspeed ) then
			tag_dialog({ title="caution", message="System data has been initialized." })
			config_default()
		end
	end
end
----------------------------------------
-- ■ 初期化
function system_initialize()
	----------------------------------------
	-- 各種操作を禁止する
	e:tag{"alreadyread",  mode="0"}	-- 既読データを保存しない
	e:tag{"writebacklog", mode="0"}	-- 使用しないので常に"0"にしておく
	e:tag{"backlog",	allow="0"}	-- 使用しないので常に"0"にしておく
	e:tag{"hide",		allow="0"}	-- 使用しないので常に"0"にしておく
	e:tag{"rclick",		allow="0"}	-- 使用しないので常に"0"にしておく
	e:tag{"skip",		allow="0"}	-- 停止しておく
	e:tag{"automode",	allow="0"}	-- 停止しておく
	e:tag{"autosave",	allow="0"}	-- 停止しておく

	-- setonpushを停止しておく
	for i=1, init.max_keyno do e:tag{"delonpush", key=(i)} end

	-- keyconfigを停止しておく
	for i=0, 16 do e:tag{"keyconfig", role=(i), keys=""} end
--	e:tag{"keyconfig", role="0", keys="1,13"}
--	e:tag{"keyconfig", role="1", keys="2,27"}
	e:tag{"keyconfig", role="0", keys=(getexclick())}	-- dummy click

	e:setUseMultiTouch(3)			-- マルチタッチ数を制限
--	e:setFlickSensitivity(-1)		-- エンジンのフリックを無効化
	e:setEventFilter(eventFilter)	-- イベント捕捉

	-- ctrlスキップ制御 / eventFilter()で処理するため飛び先はダミー
	e:tag{"setoncontrolskipin" , label="last"}
	e:tag{"setoncontrolskipout", label="last"}

	----------------------------------------
	-- 初期化
	windows_screeninit()-- screen size
	vartable_init()		-- 変数初期化
	storage_path()		-- storage path
	system_cache()		-- ui cache
	font_init()			-- font設定
	setonpush_init()	-- key設定
	key_reset()			-- key flag
	reset_backlog()		-- 念のためバックログをリセット
	sesys_reset()		-- SE初期化
	volume_master()		-- ボリューム復帰
	sysse("boot")		-- 無音SEを再生してエンジンを初期化しておく

	----------------------------------------
	-- システムスクリプトをキャッシュしておく
	e:enqueueTag{"call", file="system/ui.asb",		 label="last"}
	e:enqueueTag{"call", file="system/save.asb",	 label="last"}
	e:enqueueTag{"call", file="system/script.asb",	 label="last"}

	----------------------------------------
	-- ■ 登録
	e:setEventHandler{
		onSave		   = "store",			-- セーブ直前に呼ばれる
		onLoad		   = "restore",			-- ロード直後に呼ばれる
		onClickWaitIn  = "keyClickStart",	-- キークリック待ち開始時に呼ばれる
		onClickWaitOut = "keyClickEnd",		-- キークリック待ち終了時に呼ばれる
		onDebugSkipOut = "exskip_end",		-- debugSkip停止時
		onEnterFrame   = "vsync"
	}

	----------------------------------------
	-- 認証
	if game.os == "windows" then
		local nm = "system/extend/auth.lua"
		if isFile(nm) then
			e:include(nm)		-- 認証
			authentication()	-- 認証開始
		end

	-- loading
	elseif game.trueos == "wasm" then
		scr.ip = { file="brandlogo" }
		estag("init")

		-- お気に入りボイスloading
		if init.game_favovoice == "on" then
			wasm_favolock()
			estag{"cache_wasmfavo"}
		end

		-- 素材loading
		estag{"cache_wasmloading"}
		estag()
	end
end
----------------------------------------
-- ■ 起動チェック
function system_starting()

	e:tag{"autosave",	allow="1"}	-- autosave有効化
	allkeyon()						-- キー入力許可
	autoskip_uiinit(true)			-- ui用ctrlskip有効

	-- フルスクリーン
	if not flag_fullscreen then
		fullscreen_on()
		flag_fullscreen = true		-- reset時に実行しない
	end
	mouse_autohide()				-- windows : mouse自動消去設定
	window_button()					-- windows : OSボタン設定
	loading_off()

	--------------------------------
	-- suspend
	local sus = init.save_suspend
	if sus then
		local file = sv.makefile(sus)..".dat"
		if e:isFileExists(e:var("s.savepath").."/"..file) then
			suspend_load = true
			eqtag{"load", file=(file)}
			return
		end
	end

	--------------------------------
	-- debug
	local dflag = true
	if debug_flag and not androidreset then dflag = debugInit() end

	-- スクリプトから起動
	local fl = getScriptStartup()

	-- movie復帰
	if androidreset then
		local p = androidreset
		local b = p.ip.block
		local c = p.ip.count or 0
		scr = p
		readScript(p.ip.file)
		scr.ip.block = b		-- p.ip.block
		scr.ip.count = c + 1	-- p.ip.count
		androidreset = nil
--		scriptMainAdd()
		movie_play_exit(e)
		scr.advinit = nil
		adv_init()
		flip()
		e:tag{"jump", file="system/script.asb", label="main"}

	-- logo skip
	elseif systemreset then
		systemreset = nil
		base_fontcache()
		eqtag{"jump", file="system/first.iet", label="title"}

	-- game start / script
	elseif dflag and fl then
		title_start2(fl)

	-- game start
	elseif dflag then
		eqtag{"jump", file="system/first.iet", label="game_start"}
	end
end
----------------------------------------
-- ■ 起動時に１回だけ読み込まれる
function screen_init()

	-- 中心座標
	game.ax = game.centerx
	game.ay = game.os == 'vita' and game.centery - 2 or game.centery

	-- ゲーム倍率 	1:1280 0.75:960  1.5:1920
	--				1:1920 0.75:1280 0.5:960
	local s = init.game_scale
	game.scalewidth  = s[1]
	game.scaleheight = s[2]
	game.sax = s[1] / 2
	game.say = s[2] / 2
	game.scale = 1
	if game.width ~= s[1] then game.scale = game.width / s[1] end

	-- フリックエリア
	local a = 100
	if init.menu_area then a = repercent(init.menu_area, game.width) end
	game.flickarea = a

	-- システムバージョンチェック
	game.sysver = e:var("s.engineversion")

	-- セーブデータの最大値などを作っておく
	game.savemax = init.save_page * init.save_column		-- ページ数×１ページに表示できる数
	if init.save_etcmode == "quick" then
		game.qsavehead = game.savemax						-- quicksaveの先頭番号
		game.asavehead = game.qsavehead + init.qsave_max	-- autosaveの先頭番号
	else
		game.asavehead = game.savemax						-- autosaveの先頭番号
		game.qsavehead = game.asavehead + init.asave_max	-- quicksaveの先頭番号
	end

	-- windows check
	if game.os == "windows" then
		-- windows check / 古いOSは弾く
		local n = init.game_windowscheck
		if n then
			local v = tn(e:var("s.windowsversion"))
			if n > v then
				tag_dialog({ title="error", message="This OS is not supported." })
			end
		end
	end
end
----------------------------------------
-- パス初期化
function storage_path()
	local s = init.system
	local tros = game.trueos
	local gmos = game.os
	local image = s.image_path
	local sound = s.sound_path
	local movie = s.movie_path
	local vita  = gmos == "vita" and tros == "windows" and s.fake
	if vita then sound = vita.sound_path end

	----------------------------------------
	-- magicpathcheck
	local setpath = function(nm, path)
		local s = path:sub(-1)
		if s == '/' then
			e:debug(nm.." "..path.." パスの末尾に / が付いていると正しく動作しません")
		else
			e:setMagicPath{nm,	path}
		end
	end

	----------------------------------------
	-- magicPath
	for k, v in pairs(init.mpath.image) do setpath(k, image..v) end
	for k, v in pairs(init.mpath.sound) do setpath(k, sound..v) end
--	for k, v in pairs(init.mpath.movie) do setpath(k, movie..v) end

	----------------------------------------
	-- movieはmagicpathが使えないので特殊処理
	game.path.movie	= movie			-- movie path

	----------------------------------------
	-- etc path
	game.path.rule		= image..init.mpath.image.rule..'/'
--	game.path.facemask	= image..init.face_path..'/mask'

	----------------------------------------
	-- ui path
	set_uipath()

	----------------------------------------
	-- 拡張子
	game.fgext	  = s.fg_ext		-- 立ち絵
	game.ruleext  = s.rule_ext		-- rule
	game.movieext = s.movie_ext		-- movie
	game.soundext = s.sound_ext		-- sound
	if vita then game.soundext = s.fake.sound_ext end

	----------------------------------------
	-- etc
	game.mwid			= init.mwid				-- mwid
	game.se_track		= s.se_track or 20		-- se track		

	----------------------------------------
	-- 何か読み込んでおかないとVRAMのゴミが残る問題の回避
--	lyc2{ id="-273", file=(init.black), x=(-game.centerx), y=(-game.centery), anchorx=(game.centerx), anchory=(game.centery)}
	lyc2{ id="-273", file=(init.black) }

	-- emote cache
	if emote then emote.cacheinit() end

	-- mask
	game.clip = "0,0,"..game.width..","..game.height
	if init.vita_crop and game.os == 'vita' then
		if tros == 'vita' then
			game.clip = "0,0,960,540"
			game.crop = 4
			lyc2{ id="zzzz.dw", width="960", height="4", color="0xff000000", y="540"} 
		else
			game.clip = "0,2,960,540"
			game.crop = 2
			lyc2{ id="zzzz.up", width="960", height="2", color="0xff000000", y="0"} 
			lyc2{ id="zzzz.dw", width="960", height="2", color="0xff000000", y="542"} 
		end
	end

	----------------------------------------
	-- debug
	if debug_flag then
		setpath("help", "debug/image/help")
	end

	----------------------------------------
	-- loading
	local v = csv.mw or {}
	if v.loading and v.saving then
		local pl = v.loading
		local ps = v.saving
		local path = game.path.ui
		lyc2{ id=(pl.id), file=(path..pl.file), clip=(pl.clip), x=(pl.x), y=(pl.y)}
		lyc2{ id=(ps.id), file=(path..ps.file), clip=(ps.clip), x=(ps.x), y=(ps.y)}
		loading_icon = true
		loading_on()
	end
	flip()
end
----------------------------------------
-- ui path / 多言語切り替え
function set_uipath()
	local ln = get_ui_lang() or get_language(true)
	local nm = init.lang[ln]
	local px = init.system.ui_path..nm
	game.path.ui = px
	e:setMagicPath{"ui", px:sub(1, -2)}
end
----------------------------------------
function get_uipath() return game.path.ui end
----------------------------------------
-- 
----------------------------------------
-- ゲーム動作状態を返す
function getGameMode(mode)
	local r = "init"						-- 初期化中
	if flg then
			if flg.dlg2	then r = "system"	-- windows exit dialog
		elseif flg.dlg	then r = "dlg"		-- dialog
		elseif flg.ui	then r = "ui"		-- ui
		else				 r = "adv" end	-- ゲーム画面
	end

	-- キー入力判定
	if mode == "key" and r ~= "adv" then r = "ui"
	elseif mode == "all" then
		if  flg.waitflag then r = "wait"
		elseif flg.trans then r = "trans" end
	end
	return r
end
----------------------------------------
-- wasmチェック
function checkWasm()
	return game.os == "wasm"
end
----------------------------------------
-- wasmsyncチェック
function checkWasmsync()
	return game.os == "wasm" and init.game_wasmsync
end
----------------------------------------
-- 画面サイズより大きい範囲は切る
function screen_crop(id)
	tag{"lyprop", id=(id), intermediate_render="2", clip=(game.clip)}
end
----------------------------------------
