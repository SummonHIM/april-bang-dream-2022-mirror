----------------------------------------
-- save / load共通
----------------------------------------
sv = {}
----------------------------------------
-- 現在のポインタを保存しておく
function sv.makepoint()
	if not sv.no then
		debmessage("通知", "セーブ情報を保存しました")
		sv.no = 1		-- noを1で初期化しておく
		sv.fl = nil		-- quick flag
		tag{"takess"}	-- SSをメモリに保存
	end
end
----------------------------------------
function sv.delpoint()
	if sv.no then
		debmessage("通知", "セーブ情報を削除しました")
	end
	sv.no = nil
end
----------------------------------------
-- wasmsync or new savemode
function sv.getsavemode()
	return checkWasmsync() or init.game_savemode == "new"
end
----------------------------------------
-- noからファイル名を求める
function sv.makefile(no)
	local r
	local s = sys.saveslot[no]
	local m = game.savemax

	-- 番号をそのまま返す
	if init.save_moveno ~= "on" or no > m then
		r = init.save_prefix..string.format("%04d", no)

	-- slotから読み出す
	elseif s then
		r = s.file

	-- 新規作成
	elseif scr.savecom == "save" then
		if not sys.saveslot.check then sys.saveslot.check = {} end
		local c = sys.saveslot.count or 0
		c = c + 1
		if c <= m then
			sys.saveslot.count = c
		else
			-- slotを調べて空いてたらそこを使う
			for i=1, m do
				local s = init.save_prefix..string.format("%04d", i)
				if not sys.saveslot.check[s] then
					c = i
					break
				end
			end
		end
		r = init.save_prefix..string.format("%04d", c)
		sys.saveslot.check[r] = true
	end
	return r
end
----------------------------------------
-- セーブ存在チェック
function sv.checkopen(mode)
	local r = nil
	local s = sys.saveslot or {}
	if mode == "all" then
		r = s.last or s.quick or s.auto or s.cont
	elseif mode == "title" then
		r = s.last or s.auto
	else
		r = s[mode]
	end
	return not r
end
----------------------------------------
-- save
----------------------------------------
-- quicksave
function sv.quicksave()
	allkeyoff()
	sv.makepoint()
	if not flg.ui then sesys_stop("pause") end	-- SE一時停止

	-- セーブ番号
	local no = sys.saveslot.quick or 0
	no = no + 1
	if no > init.qsave_max then no = 1 end
	sys.saveslot.quick = no
	sv.no = game.qsavehead + no
	sv.fl = true

	-- save
	scr.quicksave = true
	sv.exec = "qsaveend"

	eqwait{ se=(flg.sysvoid) }
	eqtag{"jump", file="system/save.asb", label="save"}
end
----------------------------------------
-- qsave終了
function qsaveend(flag)
	if scr.menu then
		menu_refresh(true)		-- メニュー再描画
	else
		sv.delpoint()
		if not flg.ui then
			sesys_resume()		-- SE再開
			init_adv_btn()		-- ボタン再設置
			flip()
		end
		if not flag then info_qsaveload("qsave") end		-- 通知
	end
	scr.quicksave = nil
	sv.fl = nil
end
----------------------------------------
-- autosave / tag実行
function sv.autosavecheck()
	if flg.exautosavetag then
		sv.autosave("asave")
	end
	flg.exautosavetag = nil
end
----------------------------------------
-- autosave
function sv.autosave(name)
	if not flg.autosave and not getExtra() and conf[name] == 1 then
		allkeyoff()
		sv.makepoint()

		-- セーブ番号
		local no = sys.saveslot.auto or 0
		no = no + 1
		if no > init.asave_max then no = 1 end
		sys.saveslot.auto = no
		sv.no = game.asavehead + no
		sv.fl = true

		-- save
		scr.autosave = true
		sv.exec = "asaveend"
		e:tag{"call", file="system/save.asb", label="save"}
	end
	flg.autosave = nil
end
----------------------------------------
-- autosave終了
function asaveend()
	sv.delpoint()
	scr.autosave = nil
	notify('autosaveok')	-- オートセーブしました
end
----------------------------------------
-- save画面 / クリックされた
function sv.saveclick()
	allkeyoff()
	sv.no = flg.save.no
	sv.exec = "saveload_reload"

	eqwait{ se=(flg.sysvoid) }
	eqtag{"jump", file="system/save.asb", label="save"}
end
----------------------------------------
-- suspend
function sv.suspend()
	allkeyoff()
	sv.makepoint()

	sv.no = init.save_suspend
	sv.exec = "suspend_exit"
	e:tag{"jump", file="system/save.asb", label="save"}
end
----------------------------------------
-- suspend
function suspend_exit()
	sv.go_exit()
end
----------------------------------------
-- 
----------------------------------------
-- save本体
function sv.save()
	local no   = sv.no or 1		-- save no
	local flag = sv.fl			-- quick flag
	local file = sv.makefile(no)

	----------------------------------------
	-- サムネイル作成
	local th = true
	if flag then
		if scr.autosave then th = init.asave_thumb == "on"		-- autosave のサムネイルを作る
		else				 th = init.qsave_thumb == "on" end	-- quicksaveのサムネイルを作る
	end

	-- evmask check
	if scr.evmask then th = nil end

	-- サムネイル作成
	if th then
		local t = csv.mw.savethumb			-- サムネイルサイズ
		e:tag{"savess", file=(file), width=(t.w), height=(t.h)}
		local t = csv.mw.savethumb_l			-- サムネイル大サイズ
		if t then e:tag{"savess", file=(file..'_l'), width=(t.w), height=(t.h)} end
	end

	----------------------------------------
	-- セーブ直前に表示されていたメッセージを保存
	local tx = "autosave"		-- 本文
	if not scr.autosave then
		local r = getTextBlockText()	-- テキスト取得
		if scr.select then
			tx = { select="select" }
		elseif r then
			tx = r
		else
			tx = ""
		end
	end

	----------------------------------------
	-- ロード判定用
	local bl = scr.ip.block		-- script block
	local ax = ast[bl]
	scr.ip.save = { text=(tx), txno=(ax.lang), crc=(ax.crc) }

	----------------------------------------
	-- suspend以外
	if no < init.save_suspend then

		-- 情報をスロットに保存する
		sys.saveslot[no] = {
			text  = tx,					-- セーブ時のテキスト
			title = sv.getsavetitle(),	-- セーブタイトル
			date  = get_unixtime(),		-- 現在時刻(unixtime)
			file  = file,				-- セーブしたファイル
			evmask= scr.evmask,			-- HEVマスク
		}
		sys.saveslot.cont = no			-- 『続きから』で読み込む番号

		-- qsave / autosaveは実行しない
		if not flag then
			sys.saveslot.actv = flg.save.p1		-- 押されたボタン
			sys.saveslot.last = no				-- セーブされた番号
			sys.saveslot.page = flg.save.page	-- ページ保存
		end
	end

	----------------------------------------
	-- セーブ実行
	if sv.getsavemode() then
		local nm = "g.savedata."..file.."."
		tag{"var", name=(nm.."scr"), data=(pluto.persist({}, scr))}		-- script
		tag{"var", name=(nm.."log"), data=(pluto.persist({}, log))}		-- backlog
		tag{"var", name=(nm.."btn"), data=(pluto.persist({}, btn))}		-- btn
		syssave()
	else
		eqtag{"save", file=(file..".dat")}
	end
end
----------------------------------------
-- save完了後に呼ばれる
function sv.savenext()
	if sv.exec then
		_G[sv.exec]()
		sv.exec = nil
	end
	allkeyon()
end
----------------------------------------
-- 
----------------------------------------
-- qload開始
function sv.quickload()
	local no = game.qsavehead + sys.saveslot.quick
	if no then
--		message("通知", no, "をロードします")
		sv.load(no, {})
	end
end
----------------------------------------
-- load開始
function sv.loadclick()
	local no = flg.save.no
	if no then
		message("通知", no, "をロードします")
		sv.load(no, {})
	end
end
----------------------------------------
-- load本体
function sv.load(no, p)
	title_cachedelete()		-- cache delete / title
	delImageStack()			-- cache delete
	sv.loadparam = { no, p }
	if getTitle() then
		sysvowait(p, "loadcont")
	elseif p.mode ~= "cont" then
		sysvowait(p, "loadok")
	end
	tag{"call", file="system/ui.asb", label="load"}
end
----------------------------------------
-- load実行
function sv.loadstart()
	local no   = sv.loadparam[1]
	local file = sv.makefile(no)

	----------------------------------------
	-- 
	local func = function(file, name)
		local r  = nil
		if file and name then
			local nm = "g.savedata."..file.."."..name
			local p  = e:var(nm)
			if p ~= "0" then r = pluto.unpersist({}, p) end
		end
		return r
	end

	----------------------------------------
	-- load
	if sv.getsavemode() then
		local s = func(file, "scr")	-- script
		if s and s.ip and s.ip.file then
			local px = init.script_path..s.ip.file..init.script_ext
			if isFile(px) or checkWasmsync() then
				----------------------------------------
				-- ui処理
				local nm = scr.uifunc
				local v  = openui_table[nm]					-- 開かれていたui(主にsave画面)を閉じる
				if v then _G[v[2]]() end
				if flg.title then	title_reset() end		-- title reset
				if scr.select then	select_reset() end		-- select reset
				mw_facedel()								-- mw face delete

				----------------------------------------
				-- 変数の読み込み
				loadconv()				-- pluto
				scr = func(file, "scr")	-- script
				log = func(file, "log")	-- backlog
				btn = func(file, "btn")	-- btn
				sv.newloadstart()
			end
		end
	else
		tag{"load", file=(file..".dat")}
	end
end
----------------------------------------
function sv.newloadstart()
	----------------------------------------
	-- ui close
	local nm = scr.uifunc
	if scr.menu and nm ~= 'menu' then
		sv.delpoint()
	end
	if nm then
		local v = openui_table[nm]		-- 開かれていたui(主にsave画面)を閉じる
		if v then _G[v[2]]({}) end
	end
	flg.ui = nil

	----------------------------------------
	lydel2("startmask")
--	adv_init()
	init_advmw(true)		-- ボタン設定
	adv_reset()				-- 画面reset
	allkeyoff()				-- キー入力禁止
	appex = nil				-- extra flag
	extra = nil				-- extra flag
	titlepage = nil			-- title flag
	scr.menu = nil			-- menu flag
	scr.uifunc = nil		-- ui flag
	scr.adv.memory = nil	-- autoskip flag
	flg = {}

	----------------------------------------
	-- 読み直し
	local fl = scr.ip.file
	readScriptFile(fl)

	----------------------------------------
	-- 下処理
	estag("init")
	if checkWasmsync() then
		uimask_off()
		estag{"uitrans", 0}
		estag{"cache_wasmloading"}		-- wasmsync
		estag{"uimask_on"}
		estag{"uitrans", 0}
	end
	estag{"sv_newloadstart2"}
	estag()
end
----------------------------------------
function sv_newloadstart2()
	ResetStack()				-- stackを空にする

	-- quickjump
	local no = #log.stack
	quickjump(no, true)

	----------------------------------------
	tag{"lydel", id="zzlogn"}	-- loading
	loading_off()				-- loading off
	init_adv_btn()				-- ボタン再設定
	allkeyon()					-- キー入力許可

	-- 再開
	e:tag{"jump", file="system/script.asb", label="main_blj"}		-- 普通に進行
end
----------------------------------------
-- 
----------------------------------------
-- 削除
function sv.delete()
	local no = sv.delparam
	local t  = isSaveFile(no)			-- セーブデータ確認
	if t then
		sv.deleteno(no)
		sv.delparam = nil
	end
end
----------------------------------------
-- noから削除
function sv.deleteno(no)
	message("通知", no, "番のセーブデータを削除しました")

	-- 実ファイルの削除
	if not game.truecs then
		local file = sv.makefile(no)
		local path = e:var("s.savepath")..'/'..file
		deleteFile(path..'.dat')
		deleteFile(path..'.png')
		local t = csv.mw.savethumb_l	-- サムネイル大サイズ
		if t then deleteFile(path..'_l.png') end
		if sys.saveslot.check then sys.saveslot.check[file] = nil end
	end
	sys.saveslot[no] = nil

	-- 最新ファイルの確認
	if no == sys.saveslot.last then sv.checknewfile() end

	-- 再描画
	saveload_reload()
	pssyssave()
end
----------------------------------------
-- 最新ファイルを更新する
function sv.checknewfile()
	-- time変換
	local timeadd = function(v)
		local r = v
		if type(v) == "table" then
			r = ""
			for i=0, 6 do r = r..string.format("%02d", v[i] or 0) end
		end
		return tn(r)
	end

	-- 最新変更
	local t = sys.saveslot
	if t then
		local max  = init.save_column * init.save_page
		local last = 0	-- last:最後にセーブしたもの
		local cont = 0	-- cont:continueで呼び出す
		local tmls = 0	-- time:最後にセーブしたもの
		local tmct = 0	-- time:continue
		local ct   = 0
		for i, v in pairs(t) do
			if type(i) == "number" then
				local time = timeadd(v.date)

				-- last save
				if i <= max and tmls < time then
					tmls = time
					last = i
				end

				-- continue
				if tmct < time then
					tmct = time
					cont = i
				end
				ct = ct + 1
			end
		end

		-- データなし
		if ct == 0 then
			last = nil
			cont = nil
		end

		-- 最後にセーブしたページを更新
		local page = nil
		if t[last] then
			page = math.floor(last / init.save_column) + 1
		end

		-- 書き込み
		sys.saveslot.last = last	-- last:最後にセーブしたもの
		sys.saveslot.cont = cont	-- cont:continueで呼び出す
		sys.saveslot.page = page	-- 最後にセーブしたページ
	end
end
----------------------------------------
-- 
----------------------------------------
-- セーブタイトル
function sv.savetitle(p)
	local n = tcopy(p)
	n[1] = nil
	message("通知", "セーブタイトルを保存しました")
	scr.adv.title = n
	set_caption()		-- ウインドウタイトル設定
	return 1
end
----------------------------------------
-- セーブタイトル取得
function sv.getsavetitle()
	return scr and scr.adv and scr.adv.title or {}
end
----------------------------------------
-- セーブタイトル変換
function sv.changesavetitle(tbl)
	local r = nil
	local p = tbl or sv.getsavetitle()		-- tblがなければ現在のセーブタイトルを取得
	local n = get_language(true)
	local s = p[n] or p.text
	if s then
		r = mb_substr(s, 1, init.save_title_max)
	end
	return r
end
----------------------------------------
-- 抜ける
----------------------------------------
-- タイトルへ
function sv.go_title()
	delImageStack()						-- cache delete
	if emote then emote.bgreset() end	-- emote reset

	-- uiが開かれていたら閉じておく
	local nm = scr.uifunc
	if nm then
		if openui_table[nm] then
			message("通知", nm, "を閉じます")
			_G[openui_table[nm][2]]()
		end
	end

	-- extra
	if getExtra(true) then
		local nm = init.game_sceneexit or "scene"
		if nm == "scene" then
			tag{"jump", file="system/ui.asb", label="exscene_jumpend"}
		else
			appex = nil
			sys.extr = nil
			systemreset = true
			tag{"jump", file="system/ui.asb", label="go_title"}
		end
	else
		systemreset = true
		tag{"jump", file="system/ui.asb", label="go_title"}
	end
end
----------------------------------------
-- ゲーム終了
function sv.go_exit()
	if not gameexitflag then
		gameexitflag = true				-- 黒フェードを飛ばすためのフラグ
		local nm = "staffroll_reset"	-- staffroll中断
		if _G[nm] then _G[nm]() end
		tag{"jump", file="system/ui.asb", label="go_exit"}
	end
end
----------------------------------------
