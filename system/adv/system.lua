----------------------------------------
-- システム
----------------------------------------
-- eval
----------------------------------------
function tags.eval(e, p)
	local flag = true
	if p.cond then
		-- cond計算 / 結果が"0"かnilの時は抜ける
		local cond = cond(p.cond)
		if cond == 0 or not cond then
			message("通知", p.exp, "cond条件を満たしていませんでした")
			flag = nil
		end
	end
	if flag then set_eval(p.exp) end
	return 1
end
----------------------------------------
-- 代入
function set_eval(text)
	local p = get_evalname(text)

	-- 本文に変数名が入っていたら置換
	local data = p.body
	if data ~= 0 and data ~= 1 and data:find("[%+%-%/%*%&%|%!%(%)]") then
		local ax = split(data, "[%+%-%/%*]")
		for i, v in ipairs(ax) do
			if v == "" then v = 0 end

			-- 変数名だけを処理する
			if not tn(v) then
				data = data:gsub(v, get_eval(v), 1)
			end
		end
		e:tag{"var", name="t.tmpex", data=('$'..data)}
		data = tn(e:var("t.tmpex"))
	end

	-- 書き込む
	local hd = p.head
	local nm = p.name
	if hd == 'f' then
		if nm == "_esys" then
			error_message("_esysは使用できない変数名です")
		else
			message("通知", hd, '.', nm, '=', data)
			scr.vari[nm] = data
			flg.eval = true
		end
	elseif hd == 'g' then
		message("通知", hd, '.', nm, '=', data)
		gscr.vari[nm] = data
	else
		error_message(text, 'は不明な記述です')
	end
end
----------------------------------------
-- 変数の内容取得
function get_eval(text)
	local ret = text

	-- 名前とf/g分離
	local pos  = text:find("%.")
	local head = text:sub(1, pos - 1)
	local name = text:sub(pos + 1)

	-- 取得
	if head == 'f' then		if not scr.vari[name]  then scr.vari[name] = 0 end  ret = scr.vari[name]
	elseif head == 'g' then if not gscr.vari[name] then gscr.vari[name] = 0 end ret = gscr.vari[name]
	elseif head == 's' then
		ret = 0
		local os = game.os
		local n5 = name:sub(1, 5)
			if name == "scene" and getExtra() then ret = 1	-- scene中なら 1 を返す
		elseif name == "trial" and getTrial() then ret = 1	-- 体験版なら 1 を返す
		elseif name == "ps" and game.ps then ret = 1		-- PS4/Vitaなら 1 を返す
		elseif name == "cs" and game.cs then ret = 1		-- CS機なら 1 を返す
		elseif name == "sp" and game.sp then ret = 1		-- mobile機なら 1 を返す(android/iOS/wasm)

		-- OS名比較
		elseif name == os then ret = 1

		-- conf取得
		elseif n5 == "conf_" then
			local ax = explode("_", name)
			local nm = ax[2]
			if conf[nm] then ret = conf[nm] else ret = 9999 end
		end
	end
	return ret
end
----------------------------------------
-- 変数分離
function get_evalname(text)
	-- nameとbody分離
	local pos  = text:find("=")
	local buff = text:sub(1, pos - 1)
	local body = text:sub(pos + 1)

	-- 名前とf/sf分離
	local pos  = buff:find("%.")
	local head = buff:sub(1, pos - 1)
	local name = buff:sub(pos + 1)

	return { head=head, name=name, body=body }
end
----------------------------------------
-- condチェック
function cond(cond)
	local ret = 0
	local flag = true
	if cond then
		local data = cond
		local str  = cond:gsub("[\!=<>\&\|]", '#')
		str = str:gsub("##", '#')
		local ax   = split(str, '#')
		for i, v in ipairs(ax) do
			v = v:gsub("%(", '')
			v = v:gsub("%)", '')

			-- true / false
				if v == 'true'  then data = data:gsub(v, 1, 1)
			elseif v == 'false' then data = data:gsub(v, 0, 1)

			-- 変数名だけを処理する
			elseif not tn(v) and v:find("%.") then
				data = data:gsub(v, get_eval(v), 1)
			end
		end

		-- Artemisに投げて計算してもらう
		e:tag{"var", name="t.cond", data=('$'..data)}
		ret = tn(e:var("t.cond"))

--		message("cond", cond, ret)
	end
	return ret
end
----------------------------------------
-- 現在の変数を固めてスタックしておく
function stack_eval()
	if flg.eval then
		local s = pluto.persist({}, scr.vari)
--		if not log.vari then log.vari = {} end
--		table.insert(log.vari, s)
		addVariStack("varistack", s)
		flg.eval = nil
	end
end
----------------------------------------
-- 固めた変数を解凍
function get_stack_eval(no)
--	local t = log.vari
	local t = loadVariStack("varistack")
	if t and #t > 0 then

		-- 変数を戻す
		if no > 0 then
			local s = pluto.unpersist({}, t[no])
			scr.vari = s

			-- 後ろを削除 / noとmが同値なら削除しない
			local m = #t
			if no < m then for i=m, no+1, -1 do table.remove(t, i) end end
			saveVariStack("varistack", t)
		else
			scr.vari = {}
			initVariStack("varistack")
		end
	else
		scr.vari = {}
		initVariStack("varistack")
	end
end
----------------------------------------
-- 変数スタックのポインタを取得
function getEvalPoint()
--	return log.vari and #log.vari
	return getVariStack("varistack")
end
----------------------------------------
-- ■ 値のスタック
----------------------------------------
-- 初期化
function initVariStack(name)
	if sv.getsavemode() then
		scr.varistack = {}
	else
		tag{"var", system="delete", name=(name)}
	end
end
----------------------------------------
-- ロード
function loadVariStack(name)
	local r = {}
	if sv.getsavemode() then
		if not scr.varistack then scr.varistack = {} end
		r = scr.varistack[name] or {}
	else
		r = fload_pluto(name) or {}
	end
	return r
end
----------------------------------------
-- セーブ
function saveVariStack(name, p)
	if sv.getsavemode() then
		if not scr.varistack then scr.varistack = {} end
		scr.varistack[name] = p
	else
		fsave_pluto(name, p)
	end
end
----------------------------------------
-- 追記セーブ
function addVariStack(name, p)
	local v = loadVariStack(name)
	table.insert(v, p)
	saveVariStack(name, v)
end
----------------------------------------
-- ポインタ読み込み
function getVariStack(name)
	local v = loadVariStack(name) or {}
	return #v
end
----------------------------------------
-- ■ タグ登録
----------------------------------------
-- タイトルに戻る
tags["タイトル"] = function(e, p)
	systemreset = true
	if p["0"] == 'quick' then
		title_cachedelete()		-- cache delete / title
		delImageStack()			-- cache delete
		e:tag{"reset"}
	else
		e:tag{"call", file="system/ui.asb", label="go_title"}
	end
	return 1
end
----------------------------------------
function tags.gotitle(e, p)
	systemreset = true
	e:tag{"call", file="system/ui.asb", label="go_title"}
	return 1
end
----------------------------------------
-- キー入力関連
----------------------------------------
function tags.exkey(e, param)	exkeyin(param) return 1 end	-- 拡張キー入力待ち
----------------------------------------
function allkeyon()	 allkeystop=nil  end
function allkeyoff() allkeystop=true end
function tags.allkeyon(e, param)  allkeyon()  return 1 end	-- キー入力許可
function tags.allkeyoff(e, param) allkeyoff() return 1 end	-- キー入力禁止(なるべく使わない)
----------------------------------------
function menuon()	scr.adv.menu = nil  end
function menuoff()	scr.adv.menu = true end
function tags.menuon(e, param)	menuon()  return 1 end		-- メニュー許可
function tags.menuoff(e, param)	menuoff() return 1 end		-- メニュー禁止
----------------------------------------
function tags.menu_check(e, param)	if menu_check() then se_none() e:enqueueTag{"jump", label="last"} end return 1 end	-- メニューチェック
function menu_check() return not scr.adv.menu and not scr.adv.selecthide end
----------------------------------------
-- 
----------------------------------------
-- 通知
----------------------------------------
-- 通知
function tags.notify(e, param)	notify((param["0"] or param.text), param["1"]) return 1 end
function notify(name , flag)
	if conf.notify == 1 then
		set_textfont('notify', 'znotify')
		e:tag{"chgmsg", id='znotify', layered="1"}
		e:tag{"rp"}
		local v  = getLangHelp("notify")
		local tx = v and v[name]
		if tx then e:tag{"print", data=(tx)} end
		e:tag{"/chgmsg"}
		e:tag{"lyprop", id="znotify", alpha="255"}
		if flag ~= true then flip() end

		-- アニメーション
		if tx then
			tween{ id='znotify', x='-400,0', time='400', ease='out', handler='calllua', ["function"]='notify_wait', sys=true}
			flip()
			eqwait(flag)
		else
			e:tag{"lytweendel", id='znotify'}
			e:tag{"lydel", id='znotify'}
		end
	end
end
function notify_wait(e)
	tween{ id='znotify', alpha='255,0', time='2000', delay='3000', handler='calllua', ["function"]='tags.notify', sys=true}
end
----------------------------------------
-- 
----------------------------------------
-- lua呼び出し
function call_lua(p, com)
	p[1] = "calllua"
	p["function"] = com
	tag(p)
end
----------------------------------------
-- transフック
function tags.trans(e, param)
	local ret = 0
	if param["0"] or param.fade or param.coma then
--		message("通知", "transをフックしました")
		param.fade = param.fade or param["0"]
		trans(param)
		ret = 1
	elseif not param.type then
		if param.time then	param.type = 1
		else				param.type = 0 end
		param[1] = "trans"
		e:tag(param)
		ret = 1
	end
	return ret
end
----------------------------------------
function tags.uitrans(e, p)	uitrans(p) return 1 end	-- [uitrans]
----------------------------------------
-- 高速スキップ
----------------------------------------
-- 停止コマンド発行
function exskip_stop(nm)
	if nm then flg.exskipcache = true end
	tag{"call", file="system/ui.asb", label="exskip_stop"}
end
----------------------------------------
-- 高速スキップ停止時に呼ばれる
function exskip_end(e, p)
	if flg.exskip == 2 then
		ResetStack()	-- スタックリセット
		message("通知", "高速スキップを停止しました")
		e:setScriptStatus(0)

		-- 未読停止
		if flg.exskipcache then
			flg.exskipcache = nil
		else
			set_backlog_next()		-- バックログ格納
			checkAread()			-- 既読
		end
		allkeyon()					-- 全キー有効
		autoskip_ctrl(true)			-- ctrl有効
		flg.exskip = nil

		-- exskip強制停止
		if flg.exskipstop then
			flg.exskipstop = nil
			uimask_off()
			flip()

		-- quickjumpで再開
		else
			local no = #log.stack
			quickjump(no, "exskip")
		end
	end
end
----------------------------------------
-- [stop]フック
function tags.stop(e, p)
	local rt = 0

	-- 高速スキップを停止する
	local nm = p["0"]
	if nm == "exskip" then
		if flg.exskip then flg.exskip = 2 else rt = 1 end
	end
	return rt
end
----------------------------------------
function stop2() e:enqueueTag{"stop"} end
function stop3(ret)
	local r = tonumber(ret)
	if ret ~= 1 then stop2() end
end
----------------------------------------
tags["@"] = function()
	if flg.automode then flg.automodeclick = true end
	return 0
end
----------------------------------------
-- 仮フック
----------------------------------------
-- [jump]フック
function tags.jump(e, param)
	local ret = 0
	if param.cond then
		-- cond計算 / 結果が"0"かnilの時は抜ける
		local cond = cond(param.cond)
		if cond == 0 or not cond then ret = 1 end
	end
	return ret
end
----------------------------------------
-- [call]フック
function tags.call(e, param)
	local ret = 0
	if param.cond then
		-- cond計算 / 結果が"0"かnilの時は抜ける
		local cond = cond(param.cond)
		if cond == 0 or not cond then ret = 1 end
	end
	return ret
end
----------------------------------------
-- 代替タグ
----------------------------------------
-- lytween簡略版
function tags.tween(e, param) tween(param) return 1 end
--function tags.tweendel(e, param) tweendel() return 1 end
----------------------------------------
-- call / return
----------------------------------------
-- excall / exjump
function excall(p)
	local call = tn(p.call or 0)
	local flag = true

	-- cond
	if p.cond and cond(p.cond) == 0 then return end

	-- call / 保存
	if call == 1 then pushGSS(true) end

	-- jump
	gotoScript(p)
end
----------------------------------------
-- exreturn
function exreturn()
	local r = checkexreturn()
	if r then
		ResetStack()			-- スタックリセット / Vitaではなぜかスタックが積まれていくので明示的に開放
		readScript(r.file)		-- スクリプト読み込み
		scr.ip.block = r.block	-- 復帰
		scr.ip.count = r.count	-- 
		autocache(true)			-- 自動キャッシュ
		scriptMainAdd()			-- 次の行へ
		tag{"jump", file="system/script.asb", label="main"}

	-- シーン終了
	elseif getExtra(true) then
		extra_goscene()

	-- debug
	elseif debug_flag then
		tag{"call", file="system/script.asb", label="fileend"}

	-- タイトルに戻しておく
	else
		error_message("return出来ませんでした")
		tags.gotitle(e)
	end
end
----------------------------------------
-- gamescript stack
----------------------------------------
-- 
function pushGSS(flag)
	if init.game_stack == 'on' then
		if not scr.gss then scr.gss = {} end
		local f = scr.ip.file
		local b = scr.ip.block
		local c = scr.ip.count or 1
		local m = #scr.gss
		if flag or m == 0 then	table.insert(scr.gss, { f, b, c })
		else scr.gss[m] = { f, b, c } end
	end
end
----------------------------------------
-- 
function popGSS()
	local r = nil
	if init.game_stack == 'on' then
		if not scr.gss then scr.gss = {} end
		local m = #scr.gss
		if m > 0 then
			local p = table.remove(scr.gss)
			local f = p[1]
			local b = p[2] or 1
			local c = p[3] or 1
			r = { file=(f), block=(b), count=(c) }
		end
	end
	return r
end
----------------------------------------
-- [exreturn]タグをチェックする
function checkexreturn()
	local r = nil
	if init.game_stack == 'on' then r = popGSS() end
	return r
end
----------------------------------------
-- tag stack
----------------------------------------
-- タグをスタックしておく
function pushTag(p)
	if not scr.tagstack then scr.tagstack = {} end
	table.insert(scr.tagstack, p)
end
----------------------------------------
function popTag()
	local p = scr.tagstack or {}
	local c = table.maxn(p)
	if c > 0 then
		local label = string.format("poptag%02d", c)
		e:tag{"jump", file="system/script.asb", label=(label)}
	else
		error_message("タグスタックが空でした")
	end
end
----------------------------------------
function poptagsfunc()
	local p = table.remove(scr.tagstack, 1)
	local s = type(p[1])
	if s == 'function' then
		p[1](p[2])
	elseif s == 'string' then
		tag(p)
	end
end
----------------------------------------
-- function stack
----------------------------------------
fn = {}
function fn.push(name, p)
	if not flg.funcstack then flg.funcstack = {} end
	if not flg.funcstack[name] then flg.funcstack[name] = {} end
	flg.funcstack[name] = p
	fn.name = name
	fn.param= nil

	-- 実行
	local c = table.maxn(p)
	if c > 0 then
		local label = string.format("popfunc%02d", c)
		e:tag{"jump", file="system/script.asb", label=(label)}
	else
		flg.funcstack[name] = nil
		error_message("関数スタックが空でした")
	end
end
----------------------------------------
function fn.pop()
	local n = fn.name
	local v = n and flg.funcstack and flg.funcstack[n]
	if v then
		local p = table.remove(flg.funcstack[fn.name], 1)
		if type(p[1]) == 'function' then fn.param = p[1](p[2])
		else							 fn.param = _G[p[1]](p[2]) end

		-- 空ならクリア
		if #flg.funcstack[n] == 0 then
			local c = flg.funcstack[n]
			if c.stop == true then tag{"return", eq=1} end
			if c.stop then stop2() end						-- stopがあるときは停止
			flg.funcstack[n] = nil
		end
	end
end
----------------------------------------
function fn.set(p) fn.param = p end
function fn.get(p) return fn.param end
----------------------------------------
-- estag / eqtag代替
----------------------------------------
function estag(p)
	if not scr.est then scr.est = {} end
	local s = type(p)
	local m = #scr.est
	local sw = {
		reset = function() scr.est = nil end,
		init = function()  table.insert(scr.est, {}) end,

		start = function(n, f)
			local c = #scr.est[m]
			if c > 0 and c <= 20 then
				scr.est[m].count = 1
				scr.est[m].now	 = e:now()
				if n == "stop" then scr.est[m].stop = true end

				-- tag name
				local tagnm = f and "jump" or "call"
				local label = "estag"..string.format("%02d", c)
				e:tag{tagnm, file="system/script.asb", label=(label)}
			else
				message("通知", "estagオーバーフロー", c)
			end
		end,

		stop = function() end,
	}

	-- 実行
	if m > 0 and not p then
		sw.start()
	elseif s == "string" and sw[p] then
		local tbl = { stop="call", ["return"]="jump" }
		local com = tbl[p]
		if com then	sw.start(p, com == "jump")	-- jumpで呼び出す
		else		sw[p]()						-- callで呼び出す
		end
	elseif m > 0 and s == "table" then
		table.insert(scr.est[m], p)
	else
		message("通知", "estagが初期化されていません")
	end
end
----------------------------------------
function estag_call()
	local s = scr.est
	local m = #s
	if s and m > 0 then
		local p = s[m]
		local c = p.count
		local v = p[c]
		local x = nil
		c = c + 1
		scr.est[m].count = c

		-- 最後を取り除く
		if c > #p then
			table.remove(scr.est, m)
			if p.stop then x = true end
		end

		-- 実行
		local ng = { jump=1, call=1, trans=1, lydel=1, wait=1 }
		local tg = v[1]
		if ng[tg] and not v[2] then e:tag(v)
		elseif _G[tg]	then _G[tg](v[2])
		elseif tags[tg] then tags[tg](e, v[2])
		elseif appex and exf[tg] then exf[tg](v[2])
		else e:tag(v)	end

		-- wait
--		local n = e:now()
--		if n = p.now then eqwait() end

		-- stop
		if x then tag{"stop"} end
	else
		message("通知", "estagが初期化されていません")
	end
end
----------------------------------------
