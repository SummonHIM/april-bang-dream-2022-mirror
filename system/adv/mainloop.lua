----------------------------------------
-- スクリプト管理
----------------------------------------
-- スクリプトを読み込む / reset
function readScriptStart(file, label, p)
	flg = nil
	scr = nil
	vartable_init()
	allkeyon()

	-- 初期値を埋め込む
	if p then
		for k, v in pairs(p) do scr[k] = v end
	end

	readScript(file, label)
	adv_reset()
	reset_backlog()
	checkAread()		-- ファイル先頭の既読処理
	autocache(true)		-- 自動キャッシュ
	e:tag{"jump", file="system/script.asb", label="main"}
end
----------------------------------------
-- スクリプトを読み込む
function readScript(file, label)
	local z = scr.ip
	local r = readScriptFile(file)
	if not ast then
		return
	elseif ast and not r and scr.ip and scr.ip.file then
		file = scr.ip.file
	end

	-- 保存しておく
	scr.ip = {
		file  = file,	-- 実行中のファイル
		block = nil,	-- 実行中のブロック
		count = 1,		-- 実行中の行
	}

	-- labelがあればラベル行をセット
	local lt = ast.label or {}
	local lb = label or "top"
	local l  = lt[lb] or lt.top
	if l then
		scr.ip.block = l.block
		scr.ip.count = l.label
		message("通知", scr.ip.file, "(", label, ")", "を呼び出します")
	else
		scr.ip.block = "block_00000"
		scr.ip.count = 1
		error_message(scr.ip.file.."("..label..")が見つかりませんでした")
	end
	scr.areadflag = "reset"		-- 既読リセット

	-- 初期化
	adv_init()
--	pushGSS()
end
----------------------------------------
-- スクリプトファイルの読み込みだけを行う／ast[]に格納される
function readScriptFile(file, flag)
	ast = nil
	local ret = nil
	local fo  = init.script_format
	local fl  = file
	if tn(fl) and fo then fl = string.format(fo, fl) end
	local path = init.script_path..fl..init.script_ext
	if e:isFileExists(path) then
		if not flag then delImageStack() end	-- cache delete
		e:include(path)							-- script include
		if astver >= 2 then
			ret = true
		else
			tag_dialog({ title="エラー", message=(file.."は読み込めない形式です") }, "stop")
		end
	else
		tag_dialog({ title="エラー", message=(file.."が見つかりませんでした") }, "stop")
	end
	return ret
end
----------------------------------------
-- goto処理
function gotoScript(p)
	local file	= p.file or scr.ip.file
	local label	= p.label
	readScript(file, label)
	if ast then
		checkAread()		-- ファイル先頭の既読処理
		if game.trueos == "wasm" then
			flg.wasmcache = p.file
			e:tag{"jump", file="system/script.asb", label="wasmcache"}
		else
			autocache(true)		-- 自動キャッシュ
			e:tag{"jump", file="system/script.asb", label="main"}
		end
	end
end
----------------------------------------
-- jumpex
function tags.jumpex(e, p)
	local o = game.os
	local r = nil
	if (p.mode == "not" and o ~= p.os) or (p.mode == "not" and o ~= p.os) then r = true end

	message("分岐", o, p.mode, p.os, r)

	if r then
		gotoScript{ file=(scr.ip.file), label=(p.label) }
	end
end
----------------------------------------
-- uiからスクリプトを呼ぶ
function callscript(mode, file, label)
	readScript(file, label)
	if ast then
		if mode == "adv" then
			adv_reset()
			reset_backlog()
			init_adv_btn()
		end
		tag{"jump", file="system/script.asb", label="main"}
	end
end
----------------------------------------
-- 
----------------------------------------
-- メインループ
function scriptMainloop()
	local b = scr.ip.block			-- block
	local c = scr.ip.count or 1		-- block count
	local v = ast[b] and ast[b][c]

	-- cond処理を無視するタグ
	local ng = { select=1 }

	-- exskipで実行するタグ
	local st = init.exskip or {}		-- 実行する
	local ss = init.exskipstop or {}	-- 抜けたときにskipを止める
	local nm = v and v[1]
	local tagst = {
		fg = function(p) exskip_fg(p) end,
		bg = function(p)
			local st = p.set
			local no = (p.id or 0) + 1
			if st then evset(p)			-- ev登録
			else	   bgset(p) end		-- bg登録
			if no > 1 then cgset(p) end	-- cg登録

			-- 立ち絵処理
			if st or no == 1 then
				fgdelall()		-- 立ち絵情報削除
				timezone(p)		-- 時間帯フィルタ
			end
		end,
		bgm = function(p)
			if p.file then bgm_unlock(p) end
		end,
	}

	-- 終端到達
	if not v then
		exreturn()

	-- テキストブロック
	elseif not nm then

	-- tag実行
	elseif tags[nm] then
		if ng[nm] or not v.cond or cond(v.cond) == 1 then
			storeQJumpStack(nm, v)

			-- exskip
			if flg.exskip then
				if st[nm] then			tags[nm](e, v)		-- exskip中も実行する
				elseif tagst[nm] then	tagst[nm](v)		-- exskip中は部分実行する
				end

			-- exskip停止時に無効化するタグ
			elseif flg.exskipjump then
				if nm ~= "eval" then
					estag("init")
					if ss[nm] then
						flg.exskipjump = nil
						tag{"exec", command="skip", mode="0"}
						estag{"lydel2", "exskip"}
						estag{"uitrans"}
					end
					estag{"scriptMainTag", { nm, v }}
					estag()
				end

			-- 実行
			else
				tags[nm](e, v)
			end
		end

	-- artemis tag
	elseif not flg.exskip then
		e:tag(v)
	end
end
----------------------------------------
-- タグ呼び出し
function scriptMainTag(p)
	local nm = p[1]
	local v  = p[2]
	tags[nm](e, v)
end
----------------------------------------
-- メインループ／text表示
function scriptMainloopText()
--	chgmsg_adv()
--	message_adv(scr.text)
--	scr.text = nil
end
----------------------------------------
-- メインループ／加算
function scriptMainAdd()
	local b = scr.ip.block			-- block
	local c = scr.ip.count or 1		-- block count
	local m = table.maxn(ast[b])
	c = c + 1
	if c <= m then
		scr.ip.count = c
	else
		stack_eval()		-- 更新があったのでスタックしておく
		set_backlog_next()	-- バックログ格納
		checkAread()		-- 既読
		scr.ip.count = nil	-- カウンタリセット

		-- クリック待ち
		e:tag{"jump", file="system/script.asb", label="click"}
	end
end
----------------------------------------
-- クリック処理
----------------------------------------
-- クリック待ち開始前の処理
function clickPrepare(e, p)
	setCaption()			-- debug情報

	-- 画像処理
	if scr.img.buff then image_loop() end
	flg.qjfgdel = nil		-- quickjump fg flag

	-- exskip
	if flg.exskip then
		-- debug
		if debug_flag and flg.dbskip then
			debugMenuGoNextSkipStop()

		-- 未読停止
		elseif not scr.areadflag and conf.messkip == 0 then
			exskip_stop("cache")
		end
		e:tag{"wait", time="0", input="0"}
	end
end
----------------------------------------
-- クリック待ち開始
function clickStart(e, p)
	if not flg.exskip then
		delay_check()	-- delay
	end
	flg.click = true	-- click flag
end
----------------------------------------
-- delay skip
function delayStop()
	local key = flg.delaykey
	if key then
		delay_skipstop()		-- delayskip終了
		flip()

		local nm = key[1]
		local bt = key[2]

		-- delayfunc
		if nm == "delayfunc" and _G[bt] then
			_G[bt]()

		-- クリック以外のキー
		elseif bt and bt ~= "CLICK" then
			setexclick(nm)

		-- ボタンがクリックされた
		elseif nm == 1 and key[3] then
			flg.btnclick = 1
			setexclick(1)
		end
		flg.delaykey = nil
	end
end
----------------------------------------
-- クリック直前
function clickAutomode()
	-- automode
	if flg.automode then
		-- 待機時間
		local as = conf.autostop
		local vo = init.automode_vowait
		if vo then
			local no = scr.vo and as == 1 and vo or getASpeed()
			eqtag{"var", name="s.automodewait", data=(no)}
		end

		-- 音声待ち
		if as == 1 then
			eqtag{"automode", syncse=(sesys_getvoauto())}
		end

	-- skip speed
	elseif flg.skipmode then
		local s = conf.skipspd
		if s then
			local tm = s * 2
			if tm > 0 then
				e:tag{"wait", time=(tm), input="0"}
			end
		end

	-- glyph
	elseif not getSkip() then
		local s = init.anime_glyphstart
		if _G[s] then _G[s]() end
	end
end
----------------------------------------
-- クリック直後の処理
function clickEnd(e, p)
	flg.click = nil
	flg.automodeclick = nil
	flg.cgtweendel = nil	-- CG tween停止の管理フラグ
	scr.ip.textcount = nil	-- text counter
	scr.vo = nil			-- voice del
	mw_facedel()			-- face del
	sm_text()				-- sm del
	adv_clsclick()			-- cls
	flg.act = nil			-- action
	flg.delaykey = nil
	flip()

	-- クリックで音声停止
	if flg.automode then e:tag{"automode", syncse=""} end
	if conf.voiceskip == 1 then sesys_stop("voice") end
	scr.voice.stack = {}	-- voiceバッファクリア

	-- mw timeを戻す
	if flg.mw_timeonce then
		mw_time()
		flg.mw_timeonce = nil
	end

	-- 既読
	setAread()							-- 既読セット

	-- ブロック加算
	local bl = scr.ip.block or "none"
	local nx = ast[bl] and ast[bl].linknext
	if nx then
		scr.ip.block = nx
		autoskip_aread_skip()				-- 自動スキップチェック
		checkAread()						-- 既読アイコンチェック
	else
		tag_dialog({ title="エラー", message=("次のデータがありませんでした") }, "stop")
	end
end
----------------------------------------
-- 既読処理
----------------------------------------
-- 現在の既読情報を確認
function checkAread()
	local ar = getAread()	-- 既読
	if ar ~= scr.areadflag then
		-- 既読マーク
		local a = ar and 255 or 0
		local id = getMWID("read")
		if id then e:tag{"lyprop", id=(id), visible=(a)} end
--		flip()
	end
	scr.areadflag = ar
end
----------------------------------------
-- 現在の既読情報を取得
function getAread()
	local r  = nil
	local s  = scr.ip or {}
	local p  = gscr.aread or {}
	local fl = s.file
	if fl and p[fl] then r = p[fl][s.block] end
	return r
end
----------------------------------------
-- 既読セット
function setAread()
	local p = scr.ip
	if p then
		local fl = p.file
		local bl = p.block
		if not gscr.aread[fl] then gscr.aread[fl] = {} end
		if not gscr.aread[fl][bl] then gscr.aread[fl][bl] = true end
	end
end
----------------------------------------
-- 
----------------------------------------
function tagLinknext(flag)
	local bl = scr.ip.block or "none"
	local nm = flag and "linkback" or "linknext"
	local r  = ast[bl] and ast[bl][nm]
	return r
end
----------------------------------------
-- シーン処理
----------------------------------------
-- 
function tag_scene(p)
	local md = p.mode or "end"
	local sw = {

	----------------------------------------
	-- シーン開始
	start = function()
		message("通知", "シーン開始")
		scr.scenearea = true			-- scene area start
	end,

	----------------------------------------
	-- シーンフラグ削除
	del = function()
		message("通知", "シーン禁止")
		scr.scenearea = nil				-- scene area end
	end,

	----------------------------------------
	-- シーン終了
	["end"] = function()
		scr.scenearea = nil				-- scene area end
		local set = p["0"] or p.file

		-- タイトル画面に戻す
		if getExtra() then
			notification_clear()	-- 通知を消す
			eqtag{"jump", file="system/ui.asb", label="exscene_jumpend"}

		-- 登録
		elseif set then
			if gscr.scene[set] then
				message("通知", "シーン終了", set)
			else
				message("通知", set, "をシーン登録しました")
				gscr.scene[set] = true
				asyssave()	-- save
			end
		end
	end,
	}
	if sw[md] then sw[md]() end
end
----------------------------------------
