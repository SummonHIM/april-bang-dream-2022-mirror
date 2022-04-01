----------------------------------------
-- file入出力
----------------------------------------
-- ■ セーブ時に自動で呼ばれる
function store(e, p)
	message("通知", p.file, "をセーブしました")
	saveconv(true)	-- pluto
--	elseif param.file == "system_emergency.dat" then
end
----------------------------------------
-- ■ ロード時に自動で呼ばれる
function restore(e, p)
	message("通知", p.file, "をロードしました")
	loadconv(true)		-- pluto
	loadstart = true	-- load開始フラグ

	-- ctrlキーreset
	e:tag{"var", name="s.status.controlskip", data="0"}

	----------------------------------------
	-- ui close
	local uinm = scr.uifunc
	if scr.menu and uinm ~= 'menu' then
		sv.delpoint()
	end
	if uinm then
		local v = openui_table[uinm]	-- 開かれていたui(主にsave画面)を閉じる
		if v then _G[v[2]]({}) end
	end
	appex = nil
	extra = nil
	titlepage = nil
	scr.menu = nil
	scr.uifunc = nil
	scr.adv.memory = nil
	scr.bgmfade = nil			-- [load]でsetonsoundfinishが動作した場合に備えて0クリア

	----------------------------------------
--	save_message_del()		-- セーブ文字列を削除
--	set_message_speed()		-- メッセージ速度を再設定
--	scr.adv.memory = nil	-- オートモード／スキップを念のため停止しておく
	adv_flagreset()			-- ADVフラグリセット
	allkeyon()				-- 念のためキー入力開放
	autoskip_init()			-- 念のためautoskip再初期化
--	flg.loadrestore = true	-- skip中にsaveされるとsetoncommandskipoutが呼ばれてしまう
--	mw_alpha()				-- MW alpha
	sv.delpoint()			-- セーブ情報を念のため初期化しておく
	init_adv_btn()			-- ボタン再設定

	-- emote復帰
--	if emote then emote.cachereset() end
--	autocache()				-- 自動キャッシュ
--	if emote then emote.loading() end

	----------------------------------------
	-- バージョンが変わっていたら念のためバックログをリセット
--	if scr.gamever ~= game.ver then
--		message("通知", "セーブデータのバージョンが違います")
--		reset_backlog()		-- リセット
--		set_backlog_next()	-- １個入れておく
--	end

	----------------------------------------
	-- 選択肢
--[[
	if scr.select then
--		setonpush_select()

	----------------------------------------
	-- 選択肢じゃない時はclick on
	elseif not scr.autosave then
		adv_cls4(true)
		flg.click = true
	end

	-- stackを空にする
	ResetStack()
]]
	----------------------------------------
	-- temp_dialogがあったらdialogのチェック状態を書き込む
	if temp_dialog then
		set_dlgparam(temp_dialog, 1)
		temp_dialog = nil
		asyssave()
	end

	----------------------------------------
	-- suspend
	if suspend_load then
--		suspend_load = nil
		local file = e:var("s.savepath").."/"..sv.makefile(init.save_suspend)..".dat"
		tag{"file", command="delete", target=(file)}

	-- オートセーブ
	elseif scr.autosave then
		if scr.select then flg.autosave = true end		-- 選択肢のときはフラグを立てないと実行してしまう
		scr.autosave = nil
	end

	----------------------------------------
	-- quickjumpで読み出す
	local fl = scr.ip.file
	local bl = scr.ip.block
	readScriptFile(fl)

	conf_reload()			-- config再設定
	anime_reload()			-- アニメ再描画
	checkAread()			-- 既読チェック
	set_caption()			-- ウインドウタイトル設定

	loading_off()
	uimask_on()
	tag{"lydel", id="zzlogn"}

	local p  = log.stack or {}
	quickjumpui(#p, "load")
--[[
	-- suspend
	if suspend_load then
		suspend_load = nil
		local file = e:var("s.savepath").."/"..sv.makefile(init.save_suspend)..".dat"
		tag{"file", command="delete", target=(file)}
		tag{"call", file="system/ui.asb", label="load_nextsuspend"}

	-- オートセーブ
	elseif scr.autosave then
		flg.autosave = true		-- autosave
		scr.autosave = nil
		tag{"jump", file="system/script.asb", label="main"}

	-- 選択肢
	elseif scr.select then
		msg_reset()
		local r = select_extend("load")
		if r then
			local m = scr.select.mwsys and "sys" or "on"
			estag("init")
			estag{"select_resetimage"}		-- １回画像を消す
			estag{"uitrans"}
			estag{"msgon", { mode=(m) }}	-- 強制msgon
			estag{"setonpush_select"}		-- キーボード登録
			estag{ sesys_resume }			-- se再開
			estag{"select_view"}			-- 表示
			estag{"select_event"}			-- lyevent割り当て
			estag()
		end

	-- クリック待ち
	else
		tag{"call", file="system/ui.asb", label="load_next"}
	end
]]
end
----------------------------------------
-- ■ ロード時に自動で呼ばれる / suspend
function load_suspendcheck()
	if suspend_load and get_dlgparam("sus") == 0 then
		suspend_load = nil
		dialog("oksus")
	end
end
----------------------------------------
-- ■ ロード時に自動で呼ばれる / dialog事後処理
function load_suspendcheck2()
	ResetStack()
	quickjumpmsgmain()
end
----------------------------------------
--[[
-- ■ ロード時に自動で呼ばれる / MW
function restoreNext()
	scr.areadflag = nil
	init_advmw(true)	-- MW再設定
	mw_alpha()			-- MW alpha再設定
	checkAread()		-- 既読マーク再設定
end
----------------------------------------
-- ■ ロード時に自動で呼ばれる / text
function restoreText()
	if not scr.select then
		local bl = scr.ip.block

		----------------------------------------
		-- bgv
		sesys_resume()			-- se再開

		-- 音声があったら再生する
		local v = getTextBlock()
		if v.vo then
			sesys_voreplay(v.vo)
		end

		----------------------------------------
		-- text再描画
		mw_redraw()
	end

	-- qload icon
	if scr.quicksave then
		info_qsaveload("qload")
		scr.quicksave = nil
	end
end
]]
----------------------------------------
-- system save/load
----------------------------------------
function save_system()	fsave_pluto(init.save_system, sys ) end			-- system data
function save_global()	fsave_pluto(init.save_global, gscr) end			-- global data
function save_config()	fsave_pluto(init.save_config, conf) end			-- config data
----------------------------------------
function load_system()	sys  = fload_pluto(init.save_system) or {} end	-- system data
function load_global()	gscr = fload_pluto(init.save_global) or {} end	-- global data
function load_config()	conf = fload_pluto(init.save_config) or {} end	-- config data
----------------------------------------
-- tableをpluteで固める
function saveconv(flag)
	save_playtime()
	save_system()	-- sys →$g
	save_global()	-- gscr→$g
	save_config()	-- conf→$g
	if flag then
		fsave_pluto("scr", scr)		-- script
		fsave_pluto("log", log)		-- backlog
		fsave_pluto("btn", btn)		-- btn
	end
end
----------------------------------------
-- tableを展開する
function loadconv(flag)
	save_playtime()
	load_system()	-- $g→sys
	load_global()	-- $g→gscr
	load_config()	-- $g→conf
	if flag then
		scr = fload_pluto("scr")	-- script
		log = fload_pluto("log")	-- backlog
		btn = fload_pluto("btn")	-- btn
	end
end
----------------------------------------
-- システムファイルのみセーブする
function tags.syssave(e, param) syssave() return 1 end
function syssave()
	message("通知", "system dataをセーブしました")
	saveconv()	-- pluto
	eqtag{"save"}
end
----------------------------------------
-- windows / androidのみ保存する
function asyssave()
	if not game.cs then syssave() end
end
----------------------------------------
-- vita / PS4はsaving logoを出す
function pssyssave()
	if game.cs then
		tag{"call", file="system/ui.asb", label="pssyssave"}
	else
		syssave()
	end
end
----------------------------------------
-- プレイ時間
function save_playtime()
	local t = gscr.playtime or 0
	t = t + e:now() - playtime
	gscr.playtime = t
	playtime = e:now()
end
----------------------------------------
-- 関数
----------------------------------------
-- ■ fload関数 / saveフォルダから読み出す
function fload(file, flag)
	local path = ""
	if not flag then path = e:var("s.savepath")..'/' end

	-- 読み込み
	local r = e:file(path..file)
	if r then r = pluto.unpersist({}, r) end
	return r
end
----------------------------------------
-- ■ fsave関数 / saveフォルダに書き込む
function fsave(file, tbl, flag)
	local path = ""
	if not flag then path = e:var("s.savepath")..'/' end

	-- 書き込み
	local fp = io.open((path..file), "wb")
	if fp then
		fp:write(pluto.persist({}, tbl))
		io.close(fp)
	end
	return fp
end
----------------------------------------
-- ■ fload_pluto関数
function fload_pluto(name)
	local r = nil
	local p = e:var(name or "t.dummy")
	if p ~= "0" then r = pluto.unpersist({}, p) end
	return r
end
----------------------------------------
-- ■ fsave_pluto関数
function fsave_pluto(name, tbl)
	e:tag{"var", name=(name), data=(pluto.persist({}, tbl))}
end
----------------------------------------
-- ■ deleteFile関数
function deleteFile(path)
	e:tag{"file", command="delete", target=(path)}
end
----------------------------------------
-- ■ readtable関数
function readtable(file, name)
	local tbl = { ui=(game.path.ui) }
	local path = (name and tbl[name] or "")..file
	if e:isFileExists(path) then
		e:include(path)
	else
		error_message(path.."はみつかりませんでした")
	end
end
----------------------------------------
-- ■ isFile関数
function isFile(path)
	return path and e:isFileExists(path)
end
----------------------------------------
-- ■ isSaveFile関数 / 有:timestamp 無:nil
function isSaveFile(num, name)
	local ret = nil
	local no = tonumber(num) or 1

	-- name
		if name == "quick" then no = no + game.qsavehead		-- quicksave
	elseif name == "auto"  then no = no + game.asavehead end	-- autosave

	-- saveslotから保存時間を読み出す
	local file = nil
	local mask = nil
	local s  = sys.saveslot[no]
	if s then
		file = s.file
		ret  = s
		mask = s.evmask
	end

	-- ps4 / vita以外は実際のファイル有無も確認しておく
	if not game.cs and file then
		if init.game_savemode == "new" then
			if mask then
				local ss = ":hev/"..mask
				if not isFile(ss..".png") and not isFile(ss..".jpg") and not isFile(ss..".jpeg") then
					ret = nil
				end
			elseif not isFile(e:var("s.savepath")..'/'..file..".png") then
				ret = nil
			end
		elseif not isFile(e:var("s.savepath")..'/'..file..".dat") then
			ret = nil
		end
	end
	return ret
end
----------------------------------------
-- ■ open_savepath関数 / セーブフォルダを開く
function open_savepath()
	if game.trueos == "windows" then
		se_ok()
		local fl = "explorer"
		local cm = code_sjis(e:var("s.savepath"))
		e:callShellExecute{ file=(fl), option=(cm) }
	end
end
----------------------------------------
-- 
----------------------------------------
-- ■ opensli関数 /  voice/sliを読み込んでtableに格納
function opensli(path, num)
	local ret = {}
	local frq = num or init.voice_freq

	-- 拡張子が指定されているか
	if not path:find(".ogg") then path = path..".ogg.sli" end

	-- sliがあれば読み込み
	if isFile(path) then
		for i, line in pairs(split(e:file(path), "\n")) do
			if string.sub(line, 0, 5) == "Label" then
				local s = line:gsub("[ ']", ""):gsub("=", ";")
				local ax = split(s, ";")
				table.insert(ret, math.floor(ax[2] / frq))
			end
		end
	else
--		error_message(path.."が見つかりませんでした")
		ret = nil
	end
	return ret
end
----------------------------------------
