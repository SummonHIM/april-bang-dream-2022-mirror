----------------------------------------
-- onEnterFrame制御
----------------------------------------
function tags.repeatedly(e, p) repeatedly() return 1 end
function repeatedly() flg.repeatedly = e:now() end
----------------------------------------
-- vsync / 常に走らせるもの
function vsync()
	flg.alt = e:isDown(18)	-- alt保存
	if e:isDown(1) then flg.m = e:getMousePoint() end	-- クリック位置を記録

	----------------------------------------
	-- debug
	if debug_flag then
		if debug_vscode then debuggee.poll() end	-- debugger
		vsync_debug()
	end

	----------------------------------------
	vsync_function()				-- 特殊function実行

	----------------------------------------
	local md = getGameMode()		-- ゲームモード adv/ui/dlg
	local mx = getGameMode("all")	-- ゲームモード adv/ui/dlg/wait/trans
	local gs = game.os				-- OS名を入れておく

	----------------------------------------
	-- PS ○×入れ替え
	if game.ps and get_psswap() then
		local fl = e:isDownEdge(27)		-- ×ボタンの状態を保存しておく

		-- 13 ○反転
		if e:isDown(13) or e:isDownEdge(13) or e:isUpEdge(13) then
			local s = e:isDownEdge(13)
			e:overrideKey{ key=(13), status=0 }
			if s then e:overrideKey{ key=(27), status=32 } end

		-- 27 ×反転
		elseif e:isDown(27) or e:isDownEdge(27) or e:isUpEdge(27) then
			e:overrideKey{ key=(27), status=0 }
			if fl then e:overrideKey{ key=(13), status=32 } end
		end

		----------------------------------------
		-- trans中であればclick実行
		local no = e:getScriptStatus()
		if fl and no == 2 then
			e:overrideKey{ status=0 }
			e:overrideKey{ key=(getexclick()), status=32 }
		end
	end

	----------------------------------------
	-- ゲーム終了
	if gameexitflag then
		if not gameexitflagex and e:isDownEdge(1) then
			gameexitflagex = true
			tag{"skip", allow="1"}
			tag{"exec", command="skip", mode="1"}
		end
		return		-- 以下実行する必要はないので抜けてしまう
	end

	----------------------------------------
	-- cahce / image
	----------------------------------------

	----------------------------------------
	-- async cache
	if flg.imageCacheStart and not e:isLoadingSurface(nil) then
		flg.imageCacheStart = nil	-- ローディング待機フラグ削除
		e:setScriptStatus(0)		-- RUNステータスに遷移
	end

	----------------------------------------
	-- wasmsync cache
	if flg.wasmsync then cache_wasmvsync() end

	----------------------------------------
	-- lip sync
	if emote then emote.vsync() end

	----------------------------------------
	-- staffroll
	local s = stf
	if s then
		-- すべての入力を封じる
		local ar = s.input
		if ar == 0 or not s.key then
			e:overrideKey{ status=0 }

		-- trans中に飛ばされた
		elseif s.trans then
			e:overrideKey{ key=(2), status=32 }
			stf.input = 0

		-- 停止キー処理
		elseif ar < 2 then
			local c = true
			for k, v in pairs(s.key) do
				if e:isDownEdge(k) then
					-- trans中
					if flg.trans then
						e:tag{"skip", allow="1"}
						e:tag{"exec", command="skip", mode="1"}
						flg.transcom = "staffroll_click"
					else
--						e:overrideKey{ key=(2), status=32 }
						staffroll_skip()
					end
					c = nil
					break
				end
			end
			if c then e:overrideKey{ status=0 } end
		end
		return
	end

	----------------------------------------
	-- キー入力関連
	----------------------------------------

	----------------------------------------
	-- 指が離されるまでtap無効化
	if flg.tapclear then
		if e:isDown(1) or e:isUpEdge(1) then
			e:overrideKey{ key=(1), status=0 }
		else
			flg.tapclear = nil
		end
	end

	----------------------------------------
	-- skip停止漏れ対策
	if not flg.autoskipvsync and (flg.skipmode or flg.automode) then
		-- automode / clickで停止しない
		local c = {}
		if flg.automode and conf.autoclick == 1 then c = csv.advkey.list.OK or { [1]=true, [13]=true, [139]=true } end

		-- 停止check
		local v = csv.advkey.list.AUTOSKIP or { 1, 2, 13, 139 }
		for k, z in pairs(v) do
			if not c[k] and e:isDownEdge(k) then
				flg.autoskipvsync = 1
				return
			end
		end
	end

	----------------------------------------
	-- longtap
	local s = flg and (flg.skip or flg.skipstop)
	local b = btn and btn.cursor
	if s or b then
		e:setUseTouchHold(false)
		flg.longtap = true
	elseif flg.longtap and not f and not b then
		e:setUseTouchHold(true)
		flg.longtap = nil
	end

	----------------------------------------
	-- click upedge
	if flg.upedge then
		if e:isUpEdge(1) then
			e:overrideKey{ key=(1), status=32 }
		else
			e:overrideKey{ key=(1), status=0  }
		end
	end

	----------------------------------------
	-- 指定ボタンを押す
	if flg.exclick then
		e:overrideKey{ status=0 }
		e:overrideKey{ key=(flg.exclick), status=32 }
		flg.exclick = nil
	end

	----------------------------------------
	-- すべての入力を停止
	if allkeystopex then
		e:overrideKey{ status=0 }
	end

	----------------------------------------
	-- keyskip / trans中処理
	local v = scr.keyskip
	if mx == "trans" and v and not v.skip then
		for i, n in pairs(v.list) do
			if e:isDownEdge(i) then
				e:tag{"exec", command="skip", mode="1"}
				flg.transcom = "keyskip_trans"
				break
			end
		end
	end

	----------------------------------------
	-- skip時は抜ける
	if flg.skipmode then return end

	----------------------------------------
	-- 連打防止
	if flg.repeatedly then
		if e:isDown(1) or e:isDown(13) then
			flg.repeatedly = e:now()
		elseif flg.repeatedly < e:now() - 200 then
			flg.repeatedly = nil
		end
		e:overrideKey{ status=0 }
	end

	----------------------------------------
	-- transをclickで飛ばす処理
	if flg.trans then
		local no = getexclick()

		-- ui
		if md == "ui" or md == "dlg" then
			for i, v in pairs(csv.advkey.list.OK) do
				if e:isDownEdge(i) then
					e:overrideKey{ status=0 }
					e:overrideKey{ key=(no), status=32 }
					break
				end
			end

		-- game中
		elseif md == "adv" and not allkeystop then
			local f = nil
			local c = conf.autoclick == 0 and flg.automode		-- automode設定
			for i, v in pairs(csv.advkey.def) do
				if v.adv == "CLICK" and e:isDownEdge(i) then
					if c then f = true end
					e:overrideKey{ status=0 }
					e:overrideKey{ key=(no), status=32 }
					break
				end
			end

			-- trans中にオートモード停止(test)
			if f then flg.transcom = "automode_stopevent" end
		end

		-- ホイール上は殺しておく
		if e:isDownEdge(136) then e:overrideKey{ status=0 } end
	end

	----------------------------------------
	-- 一秒ごとに呼び出す
	local s = flg.timercount
	if s then
		local tm = s.count or 1
		local nw = math.floor((e:now() - s[1]) / 1000)
		if tm == nw then
			flg.timercount.count = tm + 1
			_G[s[2]](nw)
		end
	end

	----------------------------------------
	-- ゲームの状態で分岐
	----------------------------------------
	local sw = {

	----------------------------------------
	-- ゲーム画面
	adv = function()
		----------------------------------------
		-- ctrlskip無効化
		local c = conf and conf.ctrlskip == 0
		if c or flg.ctrlstop then
			local s = explode(",", csv.advkey.ctrl)
			for i, v in pairs(s) do
				e:overrideKey{ key=(v), status=0 }
			end
		end

		----------------------------------------
		-- ゲーム画面のdrag処理
		if flg.advdragin or flg.advdragstop then
			flg.advdragstop = nil
			e:overrideKey{ key=1  , status=0 }	-- tap
			e:overrideKey{ key=143, status=0 }	-- long tap
			e:overrideKey{ key=151, status=0 }	-- up flick
			e:overrideKey{ key=152, status=0 }	-- rt flick
			e:overrideKey{ key=153, status=0 }	-- dw flick
			e:overrideKey{ key=154, status=0 }	-- lt flick
		end

		----------------------------------------
		-- windows
		if gs == "windows" then

			-- tablet mode
			if conf.tabletui == 1 then
				if e:isDown(1) then flg.tabletui = true else flg.tabletui = nil end
			end

			----------------------------------------
			-- autoplayはホイール上を塞ぐ
			if flg.autoplay then
				e:overrideKey{ key=136, status=0 }
			end
		end

		----------------------------------------
		-- にゃーんskip / ↓＋×＋L1
		if e:isDown(27) and e:isDown(40) and e:isDown(115) then
			e:overrideKey{ key=27 , status=0 }
			e:overrideKey{ key=40 , status=0 }
			e:overrideKey{ key=115, status=0 }

			-- skip呼び出し
			local v = csv.advkey.def
			local c = nil
			for k, z in pairs(v) do
				if z.adv == "SKIP" then
					e:overrideKey{ key=(k), status=32 }
					break
				end
			end
			flg.ex2skip = true
		end

		----------------------------------------
		-- 目パチ
		if init.game_fganime == "on" then fganime_vsync() end

		----------------------------------------
		-- shader
		if flg.shader then shader_vsync() end

		----------------------------------------
		-- 時限選択肢
		local s = scr.select
		if s and s.vsync then select_timed_vsync() end

		----------------------------------------
		-- ムービー
		if scr.movie then

			----------------------------------------
			-- ムービー再生が３本指タッチですぐ飛ばないようにする
			if not flg.exclick then
				if scr.movie.ctrlskip then
					local t = e:getTouchCount()
					if t == 0 then
						scr.movie.ctrlskip = nil
					else
						e:overrideKey{ status=0 }
					end
				elseif e:isDown(140) then
					scr.movie.ctrlskip = true
					e:overrideKey{ status=0 }

				-- 停止をUpEdgeにする
				elseif e:isDown(1) then		e:overrideKey{ status=0 }
				elseif e:isUpEdge(1) then	e:overrideKey{ key=1, status=32 }
				end
			end
		end
	end,

	----------------------------------------
	-- UI画面
	ui = function()
		----------------------------------------
		-- title anime skip
		local v = flg.title
		if v and v.skip and not v.skipflag then
			for i, n in pairs(csv.advkey.list.OK) do
				if i == 1 and e:isDownEdge(i) or i ~= 1 and e:isUpEdge(i) then
					e:tag{"exec", command="skip", mode="1"}
					flg.title.skipflag = true
					break
				end
			end
--[[
		----------------------------------------
		-- bgmmode
		elseif flg and flg.repflag and flg.bgmrep then
			if flg.bgmrep < e:now() then
				flg.repflag = nil
				extra_bgm_autostop()
			end

		----------------------------------------
		-- title automovie
		elseif flg.titlemovie then
			if flg.titlemovie < e:now() then
				flg.titlemovie = nil
				title_automovie()
			end
]]
		end

		----------------------------------------
		-- 指定時間にfunc実行
		local s = flg.callfunc
		if s then
			local tm = s.time
			local ex = s.func
			if tm <= e:now() then
				flg.callfunc = nil
				_G[ex]()
			end
		end

		----------------------------------------
		-- OSごと
		----------------------------------------
		-- windows
		if gs == "windows" then
			----------------------------------------
			-- config / fullscreen処理
			local v = flg.config or {}
			if v.vsync then
				e:tag{"var", name="t.screen", system="fullscreen"}
				local s = tn(e:var("t.screen"))
				local c = conf.window
				if s ~= c then
					conf.window = s

					-- single
					local nm = init.windows_screen
					if nm then
						local cl = s == 1 and 'clip_c' or 'clip'
						local v  = getBtnInfo(nm)
						tag{"lyprop", id=(v.idx..".0"), clip=(v[cl])}
						flip()

					-- on/off
					else
						local nm = s == 1 and init.windows_screenon or init.windows_screenoff
						toggle_change(nm)
					end
				end
			end

		----------------------------------------
		-- CS
--		elseif game.cs then

		----------------------------------------
		-- android / iOS / wasm
		elseif game.sp then
			-- 画面左端で右フリックをESCにする処理
--			if e:isDownEdge(1) then flg.m = e:getMousePoint() end
			if e:isUpEdge(152) then
				local m = flg.m or {}
				if m.x <= 60 then
					e:overrideKey{ status=0 }
					e:overrideKey{ key=27, status=32 }
				end
			end
		end
	end,
	}
	if sw[md] then sw[md]() end
end
----------------------------------------
-- デバッグ専用処理
function vsync_debug()
	----------------------------------------
	-- loading time
	if debugcachetime and not e:isLoadingSurface(nil) then
		local s = e:now() - debugcachetime
		message("通知", "★Loading", s, "ms")
		debugcachetime = nil
	end

	----------------------------------------
	-- tab keyがない機種用
	if (e:isDown(116) or e:isDown(260)) and (e:isDownEdge(117) or e:isDownEdge(261)) then
		e:overrideKey{ status=0 }
		e:overrideKey{ key=9, status=32 }
	-- L1ボタンはupEdgeで反応／無効化
	elseif e:isDown(116) or e:isDown(260) then
		e:overrideKey{ status=0 }
	-- L1ボタンはupEdgeで反応／push
	elseif e:isUpEdge(116) or e:isUpEdge(260) then
		e:overrideKey{ key=116, status=32 }
	end
--[[
	for i=1, init.max_keyno do
		if e:isDownEdge(i) then
			message("key", i)
		end
	end
]]
end
----------------------------------------
-- 関数を呼び出す
function vsync_function()
	local s = flg.vsyncfunc
	if s then
		for i, v in ipairs(s) do
			if _G[v[1]] then _G[v[1]](v[2]) end
		end
		flg.vsyncfunc = nil
	end

	-- autoskip処理
	local f = flg.autoskipvsync or 0
	if f >= 2 then
		flg.autoskipvsync = nil
		if flg.skipmode then	 skipmode_stopevent()
		elseif flg.automode then automode_stopevent()
		end
	elseif f == 1 then
		flg.autoskipvsync = 2
	end
end
----------------------------------------
-- 関数をスタック
function stackVsyncFunc(nm, p)
	if not flg.vsyncfunc then flg.vsyncfunc = {} end
	table.insert(flg.vsyncfunc, { nm, p })
end
----------------------------------------
-- 
----------------------------------------
-- キー入力待ち開始のとき自動的に呼ばれる
function keyClickStart(e, param)
	-- wait中にsetonpushが実行できないようにする / ただしCLICKは有効
	flg.waitflag = getWaitStatus()
end
----------------------------------------
-- キー入力待ち終了のとき自動的に呼ばれる
function keyClickEnd()
	if getWaitStatus() then flg.waitflag = nil end
	flg.waitparam = nil
end
----------------------------------------
function getWaitStatus()
	local p = e:getScriptWaitReason()
	flg.waitparam = p
	return getWaitStatusCheck(p, true)
end
----------------------------------------
function getWaitStatusCheck(p, f)
	local r = nil
	local c = f and 2 or 1
	local tbl = {
		{ "time", "textTween", "textClearTween", "sound", "video" },
		{ "time", "textClearTween", "sound", "video" },
	}
	if p then
		for k, v in ipairs(tbl[c]) do
			if p[v] then
				r = { v, p[v], e:now() }
				break
			end
		end
	end
	return r
end
----------------------------------------
