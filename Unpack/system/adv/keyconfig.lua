----------------------------------------
-- キー設定
----------------------------------------
-- フラグ初期化
function key_reset()
	flg = {}
end
----------------------------------------
function setexclick(no)	flg.exclick = no or 124 end
function getexclick()	return init.exclick or 124 end
----------------------------------------
-- key初期化
function setonpush_init()
	-- 使用するキーだけ登録
	for i, v in pairs(csv.advkey.def) do
		e:tag{"delonpush", key=(i)}
		e:tag{"setonpush", key=(i), handler="calllua", ["function"]="setonpush_calllua", adv=(v.adv), ui=(v.ui), btn=(v.btn)}
	end 

	-- click
	e:tag{"keyconfig", role="0",  keys=(getexclick())}		-- dummy click
	e:tag{"keyconfig", role="1",  keys=""}
	flg.rep = nil
end
----------------------------------------
-- キーリストをカンマ区切りで返す
function getKeyString(name)
	local tb = csv.advkey.list[name]
	local st = ""
	if name == "ALL" then tb = csv.advkey.def end
	if tb then
		for i, v in pairs(tb) do
			if st == "" then st = ""..i else st = st..","..i end
		end
	else
		error_message(name.."がキーリストに存在しませんでした")
	end
	return st
end
----------------------------------------
-- ui
function setonpush_ui(flag)
	-- ui
	if flg.ui or flg.dlg then
		delonpush_ui()

		-- キーリピート再設定
		local t = btn and btn[btn.name] and btn[btn.name].key
		if t then
			for nm, v in pairs(t) do
				if v.rep and csv.advkey.list[nm] then
					for i, q in pairs(csv.advkey.list[nm]) do
						e:tag{"delonpush", key=(i)}
						e:tag{"setonpush", key=(i), keyrepeat="1", handler="calllua", ["function"]="setonpush_calllua", adv=(nm), ui=(nm), btn=(nm)}
					end
				end
			end
		end
--		e:tag{"setonpush", key="117", handler="calllua", ["function"]="setonpush_calllua"}
	end

	autoskip_uiinit(flag)
end
----------------------------------------
-- select
function setonpush_select()
	-- 選択肢
	local s = scr.select
	if s then
		local tbl = { "UP", "DW" }
		for i, nm in pairs(tbl) do
			if csv.advkey.list[nm] then
				for i, q in pairs(csv.advkey.list[nm]) do
					e:tag{"delonpush", key=(i)}
					e:tag{"setonpush", key=(i), keyrepeat="1", handler="calllua", ["function"]="setonpush_calllua", adv=(nm), ui=(nm), btn=(nm)}
				end
			end
		end

		-- yesno選択肢のみ
		if s.yesno then
			local tbl = { "LT", "RT" }
			for i, nm in pairs(tbl) do
				if csv.advkey.list[nm] then
					for i, q in pairs(csv.advkey.list[nm]) do
						e:tag{"delonpush", key=(i)}
						e:tag{"setonpush", key=(i), keyrepeat="0", handler="calllua", ["function"]="setonpush_calllua", adv=(nm), ui=(nm), btn=(nm)}
					end
				end
			end
		end
	end
end
----------------------------------------
-- uiから戻った
function delonpush_ui()
	setonpush_init()
	setonpush_select()
end
----------------------------------------
-- 使用するすべてのキーがここを経由する
function setonpush_calllua(e, param)
	local key = tonumber(param.key)
	if key > init.max_keyno or flg.imageCacheStart then return end

	----------------------------------------
	-- 右フリック処理
	if key == 152 and init.game_flickback == "on" and (flg.ui or flg.dlg) then
		local m = flg.m or e:getMousePoint()
		if m.x < game.flickarea then
			key  = 2
			param.ui = "EXIT"
		end
	end

	----------------------------------------
	-- debug key
	if debug_flag and not flg.alt then
			if key == 98  then key = 153		-- num 2 to flick dw
		elseif key == 100 then key = 154		-- num 4 to flick lt
		elseif key == 102 then key = 152		-- num 6 to flick rt
		elseif key == 104 then key = 151		-- num 8 to flick up
		elseif key == 101 then key = 143		-- num 5 to long tap
		elseif key == 96  then key = 139		-- num 0 to double tap
		end

		-- 右フリック
		local m = flg.m or e:getMousePoint()
		if key == 152 and not deb.open and m.x < game.flickarea then
			debugMenuSwitch(e, {})
			return
		end

		-- debug専用キー
		local d  = debug_setting.key or {}
		local db = d[key]
		if db then
			if flg.delay then
				flg.delay = 'skip'
				flg.delaykey = { key, name, btn.cursor }
				e:tag{"exec", command="skip", mode="1"}
			else
				e:tag{"calllua", ["function"]=(db), key=(key)}
			end
			return
		end
	elseif debug_flag and flg.alt then
		local d2 = debug_setting.key2 or {}
		local db = d2[key]
		if db and not flg.delay and _G[db] then
			_G[db]()
			return
		end
	end

	----------------------------------------
	-- keyconfig.init
	if keys and keys[key] then name = keys[key] end

	----------------------------------------
	-- キー関数(local)
	----------------------------------------
	-- ボタン呼び出し
	local callfunc = function(func, key, name, bt)
		if func then e:tag{"calllua", ["function"]=(func), key=(key), name=(name), group=(btn and btn.group), btn=(bt)} end
	end
	----------------------------------------
	-- key変換
	local getKey = function(key, name)
		if conf.keys[key] then name = conf.keys[key] end
		return name
	end
	----------------------------------------

	----------------------------------------
	-- 
	local func = btn and btn.group and btn.cursor and scr.btnfunc and scr.btnfunc[btn.group.."|"..btn.cursor]
	local tdef = csv.advkey.def and csv.advkey.def[key] or {}
	local name = param.adv or tdef.adv

--	message(key, name, func, param.adv, flg.waitflag)

	----------------------------------------
	-- autoskip処理
	if flg.automode then
		if conf.autoclick == 1 then
			local name = getKey(key, param.ui) or param.adv
			if name == "CLICK" then
				setexclick()		-- dummy click
			end
		end
		return
	elseif flg.skip then return end

	----------------------------------------
	-- click/tapが押されたときにボタンの上にカーソルがあるかどうかを判定する
--	if key == 1 and flg.btnclick then
--		if btn and btn.cursor ~= flg.btnclick then
--			btn_out( e, { key=btn.cursor })
--			btn_over(e, { key=flg.btnclick })
--			btn.cursor = flg.btnclick
--		end
--	end
	if not flg.btnstop and key == 1 and btn and btn.cursor then
		if not flg.btnclick then return end
		flg.btnclick = nil
	end

	----------------------------------------
	-- pad暗転防止test
	if key >= 256 and name == "CLICK" then
		local m = e:getMousePoint()
		if flg.automouse then
			m = flg.automouse
			flg.automouse = nil
		else
			flg.automouse = m
			m.x = m.x + 1
			m.y = m.y + 1
		end
		e:tag{"mouse", left=(m.x), top=(m.y)}
	end

	----------------------------------------
	-- debug
	if     debug_flag and name == 'debug' then	callfunc(tbl.func, key, name, btn.cursor)
	elseif debug_flag and debugstop then

	----------------------------------------
--[[
	-- delay skip
	elseif flg.delay then
		if name == "AUTO" then
			----------------------------------------
			-- 関数を呼び出す
			local func = csv.advkey.tbl[name]
			callfunc(func, key, name, btn and btn.cursor)

		else
			flg.delay = 'skip'
			flg.delaykey = { key, name, btn.cursor }
			e:tag{"exec", command="skip", mode="1"}
		end
]]
	----------------------------------------
	-- [keyskip]
	elseif scr.keyskip then
		local v = scr.keyskip.list
		if v and v[key] then keyskip_jump() end

	----------------------------------------
	-- ボタン追加 / url呼び出し
	elseif flg.addbtn and flg.addbtn.over then
		se_ok()
		tag{"openbrowser", url=(flg.addbtn.url)}

	----------------------------------------
	-- wait中に押されてもいいことないのでclick以外無効化
	elseif flg.waitflag or flg.txclick then
--		if name == 'CLICK' then setexclick() end
		if not flg.ui and  name ~= "AUTO" then setexclick()
		elseif getExtra() then
			local name = getKey(key, param.ui)
			if appex.exfg and (name == 'CLICK' or name == "EXIT") then setexclick() end
		end

	----------------------------------------
	-- mw volume
	elseif flg.mwmute then
		if name == "CLICK" and not func then
			mwdock_muteclose()
		end

	----------------------------------------
	-- click / flg.keycodeで指定されたリストを使用して進む
	elseif flg.keycode then
		-- flg.keylistで指定されたkeyがあった場合lua関数を呼び出す
		if flg.keylist and flg.keylist[key] then
			local lua = flg.keylist[key]
			flg.keylist = nil
			call_lua(param, lua)

		-- keylistはcsvで管理
		elseif csv.advkey.list[flg.keycode] and csv.advkey.list[flg.keycode][key] then
			setexclick()		-- dummy click
			flg.keycode = key
		end

	----------------------------------------
	-- dialog
	elseif flg.dlg then
--		local name = getKey(key, param.ui)
		local name = init.ui_keyconf == "on" and getKey(key, param.ui) or param.ui

		-- key repeat
		local n = btn and btn.name
		if n and btn[n] and btn[n].key[name] then
			local p = btn[n].key[name]
			if p.rep then
				if btn.rep and btn.rep + init.ui_repeat > e:now() then return end
				btn.rep = e:now()
			end
		end

		-- 呼び出し
		local tbl = { CLICK="yesno_click", EXIT="yesno_esc", F2="yesno_checkbox", LT="btn_left", RT="btn_right", UP="btn_up", DW="btn_down" }
		if tbl[name] then callfunc(tbl[name], key, name, btn.cursor) end

	----------------------------------------
	-- 拡張呼び出し
	elseif param.mode == "ex" then
		local nm = param.lua
		if nm and _G[nm] then _G[nm](param) end

	----------------------------------------
	-- ui
	elseif flg.ui then
--		local name = getKey(key, param.ui)
		local name = init.ui_keyconf == "on" and getKey(key, param.ui) or param.ui
		local n = btn and btn.name

		-- ボタン
		if name == "CLICK" and func then
			callfunc(func, key, name, btn.cursor)

		-- 登録されているキーのみ処理する
		elseif n and btn[n] and btn[n].key[name] then
			local p = btn[n].key[name]

			-- key repeat
			if p.rep then
				local rp = flg.repeattime or init.ui_repeat
				if btn.rep and btn.rep + rp > e:now() then return end
				btn.rep = e:now()
			end

			-- csvにkeyが指定されていたらボタン名追加
			local bt = btn.cursor
			local nm = p.name
			local v  = nm and getBtnInfo(nm)
			if v and (key == tn(v.key) or name == v.key) then param.bt = nm end

			-- 呼び出し
			local tbl = { LT="btn_left", UP="btn_up", RT="btn_right", DW="btn_down" }
			if p.exec then					 call_lua(param, p.exec)						-- p.execがあったら呼び出す
			elseif tbl[name] then			 callfunc(tbl[name], key, name, bt)				-- カーソルキーが登録されていたら専用関数を呼ぶ
			elseif csv.advkey.tbl[name] then callfunc(csv.advkey.tbl[name], key, name, bt)	-- advkey / uiに登録されている動作を見る
			else							 callfunc(func, key, name, bt)					-- 必要？念のため
			end

		-- キー処理
		elseif flg.ui.key and flg.ui.key[name] then
			callfunc(flg.ui.key[name], key, name)
		end

	----------------------------------------
	-- ゲーム画面
	elseif scr.mw.msg and flg.click or scr.select then
		name = getKey(key, name)

		-- key repeat
		if param.keyrepeat == "1" then
			if flg.rep and flg.rep + init.ui_repeat > e:now() then return end
			flg.rep = e:now()
		end

		-- CLICK判定 / ホイールは除外する
		local advclick = function()
			local r = nil
			if name == "CLICK" and key ~= 137 then
				r = true
			end
			return r
		end

		-- 選択肢判定
		local s = scr.select
		local tbl = { UP=1, DW=1 }
		if s and s.yesno then
			tbl.LT = 1
			tbl.RT = 1
		end

		----------------------------------------
		-- ボタン実行
		if advclick() and func then
			callfunc(func, key, name, btn.cursor)

		----------------------------------------
		-- 選択肢
		elseif s and (advclick() or tbl[name]) then
			local sw = {
				-- click
				CLICK = function() select_click() end,

				-- key up
				UP = function(nm)
					if select_extendCheck(nm) then select_extend("up", {})	-- 拡張選択肢
					else select_keyup() end
				end,

				-- key down
				DW = function(nm)
					if select_extendCheck(nm) then select_extend("dw", {})	-- 拡張選択肢
					else select_keydw() end
				end,

				LT = function() select_yesnobtn("lt") end,
				RT = function() select_yesnobtn("rt") end,
			}
			if sw[name] then
				local s  = scr.select
				local nm = s.func
				sw[name](nm)
				return
			end

		----------------------------------------
		-- キー実行
		elseif csv.advkey.tbl[name] then
			local func = csv.advkey.tbl[name]

			-- tablet mode
			if conf.tablet == 1 and conf.dock == 0 and flg.mwsplock then
				flg.mwsplock = nil
				mwarea_close()
				return

			-- ボタン名に動作名が割り当てられていたらfuncを書き換える
			elseif btn and btn.name then
				local nm = btn.name
				local ky = btn[nm].key
				if ky[name] then
					func = ky[name].exec or func
				end
			end

			----------------------------------------
			-- 関数を呼び出す
			callfunc(func, key, name, btn and btn.cursor)
		end

	----------------------------------------
	-- 何押されてもクリック
	elseif flg.click then
		setexclick()		-- dummy click
	elseif flg.clickwait then
		setexclick()		-- dummy click
		flg.clickwait = nil
	end
end
----------------------------------------
--	setonpush{ key=(p.key), lua=(p.lua), adv=(p.name), ui=(p.name), btn=(p.btn), debug=(p.debug) }
function setonpush(p)
	local name = p.name
	e:tag{"delonpush", key=(p.key)}
	p[1] = "setonpush"
	p["handler"]  = "calllua"
	p["function"] = "setonpush_calllua"
	p.adv = p.adv or name
	p.ui  = p.ui  or name
	e:tag(p)
end
----------------------------------------
-- 
----------------------------------------
-- game modeを返す
function get_gamemode(f, name, flag)
	local ret = flg.waitflag or flg.btnstop		-- wait中 or ボタン停止中
	local nm  = btn and btn.name
	local fx  = btn and btn[nm] and btn[nm].p[name]
	local m   = e:getMousePoint()

	----------------------------------------
	-- ディレイ中
	if flg.delay then
		ret = flg.btnstop

	----------------------------------------
	-- 画面外では反応しないようにする
	elseif game.os == "windows" and flg.keyevent == "lyevent" and (m.x < 0 or m.y < 0 or m.x > game.width or m.y > game.height) then
		if not flag then ret = true end

	----------------------------------------
	-- txkey中
	elseif flg.txclick then
		ret = true

	----------------------------------------
	-- adv画面は確実にキー入力待ちである必要がある
	elseif f == 'adv' then
		if flg.ui or flg.dlg or flg.dlg2 then	-- ゲーム画面以外
			ret = true
		end

	----------------------------------------
	-- ui画面 / disに登録されているボタンは無視
	elseif nm and btn[nm] and btn[nm].dis[name] then
		ret = true

	----------------------------------------
	-- ui画面 / dlgが開いているときは下のuiは無視
--	elseif f == 'ui2' and flg.dlg and not fx then
	-- btn tableにボタンが無ければ無効
	elseif not fx then
		ret = true

	----------------------------------------
	-- 不明な状態では何も押せない
	else
--		ret = true
	end
	return not ret
end
----------------------------------------
-- キー入力／ボタン制御
----------------------------------------
function lyevent(param)
	param[1]	  = 'lyevent'
	param.handler = 'calllua'
	param.mode	  = param.mode or "init"

	-- click
	if param.click then
		if not scr.btnfunc then scr.btnfunc = {} end
		scr.btnfunc[param.name.."|"..param.key] = param.click
		local p = tcopy(param)
		p["function"] = "btn_clickex"	-- p.click
		p.type = 'click'
		e:tag(p)
	end

	-- over
	if param.over then
		local p = tcopy(param)
		p["function"] = p.over
		p.type = 'rollover'
		e:tag(p)
	end

	-- out
	if param.out then
		local p = tcopy(param)
		p["function"] = p.out
		p.type = 'rollout'
		e:tag(p)
	end

	-- dragin
	if param.dragin then
		local p = tcopy(param)
		p["function"] = p.dragin
		p.type = 'dragin'
		e:tag(p)
	end

	-- drag
	if param.drag then
		local p = tcopy(param)
		p["function"] = p.drag
		p.type = 'drag'
		e:tag(p)
	end

	-- dragout
	if param.dragout then
		local p = tcopy(param)
		p["function"] = p.dragout
		p.type = 'dragout'
		e:tag(p)
	end
end
----------------------------------------
-- 
----------------------------------------
-- 任意のキーを押したらジャンプ
function keyskip(p)
	local file	= p.file or scr.ip.file
	local label	= p.label
	local key	= p.key
	local v = csv.advkey.list
	if key and v[key] then
		scr.keyskip = { file=(file), label=(label), list=(v[key]) }
	else
		scr.keyskip = nil
	end
end
----------------------------------------
--
function keyskip_jump()
	local v = scr.keyskip
	scr.keyskip = nil
	if v then
		ReturnStack()	-- 空のスタックを削除
		gotoScript(v)
	end
end
----------------------------------------
function keyskip_trans()
	e:tag{"exec", command="skip", mode="0"}
	keyskip_jump()
end
----------------------------------------
-- 本編以外でのキー入力待ち
function exkeyin(p)
	local label = p["0"] or p.label
	flg.keycode = p["1"] or p.btn or 'OK'
	e:enqueueTag{"chgmsg", id="dummy"}
	e:enqueueTag{"@"}
	e:enqueueTag{"/chgmsg"}
	e:enqueueTag{"calllua", ["function"]='exkeyin_exit', label=(label)}
end
----------------------------------------
function exkeyin_exit(e, p)
	-- cancelに登録されていた場合labelに移動する
	if p.label and flg.keycode and csv.advkey.list.CANCEL and csv.advkey.list.CANCEL[flg.keycode] then
		e:enqueueTag{"jump", label=(p.label)}
	end
	flg.keycode = nil
end
----------------------------------------
