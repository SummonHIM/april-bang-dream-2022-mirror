----------------------------------------
-- システムSE
----------------------------------------
local ex = {}
----------------------------------------
ex.user_sysvo = "user_func_sysvo"	-- sysvo拡張関数(関数が存在すれば呼び出す)
----------------------------------------
-- system se再生
function sysse(name, flag)
	local v  = csv.sysse[name]
	if v then
		local fl = v and v[1] or name
		local id = v.id
		local p  = { id=(id) }
		if flag then p.nosave = true end

		-- 停止
		if name ~= "active" then sesys_stop("sysse") end

		debmessage("sysse", name, fl)

		-- 再生
		local path = ":sysse/"..fl..game.soundext
		sesys_play("sysse", path, p)
	end
end
----------------------------------------
-- 完了待機
function sysvowait(p, nm)
	local wa = p["0"] or p.wait
	if wa then
		eqwait{ se=(flg.sysvoid) }
	else
		sysvo(nm)
	end
end
----------------------------------------
-- 短縮関数
----------------------------------------
-- ok
function se_ok()
	if not flg.stopsysse then
		sysse("ok")
	end
	flg.stopsysse = nil
end
----------------------------------------
-- ok
function se_ok2()
	if not flg.closecom then
		sysse("ok")
	end
end
----------------------------------------
 -- アクティブ
function se_active()
	local file = flg.tsysse or "active"
	local func = "user_se_active"
	if _G[func] then
		_G[func](file)
	elseif not flg.nonactive then
		sysse(file, true)
	end
end
----------------------------------------
function se_cancel()  sysse("cancel") end		-- キャンセル
function se_caution() sysse("caution") end		-- ダイアログ
function se_yes()	  sysse("yes") end			-- dialog yes
function se_no()	  sysse("no") end			-- dialog no
function se_decide()  sysse("decide") end		-- 決定
function se_select()  sysse("select") end		-- 選択肢決定
function se_none()	  sysse("none") end			-- 無効
function se_menu()	  sysse("menu") end			-- menu
function se_logo()	  sysse("logo") end			-- logo
function se_qsave()   sysse("qsave") end		-- qsave
function se_qload()   sysse("qload") end		-- qload
function se_start()	  sysse("title") end		-- title start
function se_default() sysse("default") end		-- config default
----------------------------------------
-- SystemVoice
----------------------------------------
-- system voice
function sysvo_func(p)
	if tn(p.stop) ~= 1 then
		local file = p.file or p["0"]
		sysvo(file, p)
	else
		local time = p.time or 0
		sesys_stop{ mode="sysvo", time=(time), sync=(p.sync) }
	end
end
----------------------------------------
function sysvo(name, com)
	local s = ex.user_sysvo
	local z = csv.sysse.sysvo
	local p = com		-- param
	local c = com		-- char
	if type(p) == "string" then
		p = {}
	else
		c = nil
	end

	-- 停止
	sesys_stop("sysvo")

	-- 音量確認
	local v1 = conf.sysvo or conf.sysse
	local v2 = conf.fl_sysvo or conf.fl_sysse
	if v1 ==0 or v2 and v2 == 0 then
--		message("通知", "音量が 0 でした", name)

	-- エラー
	elseif not name then
		message("通知", "不明なsysvoです")

	-- パス指定があればvoiceを呼び出す
	elseif name:find("sysvo/") then
		debmessage("通知", name, "を再生します")
		local path = name..game.soundext
		sesys_playtag("sysvo", path, { id=1 }, p)

	-- 専用ルーチンを呼び出す
	elseif s and _G[s] then
		_G[s](name, p)

	-- キャラ決め打ち
	elseif c then
		local v = z[name][c] or {}
		local m = #v
		if m > 0 then
			-- 再生
			local r = e:random() % m + 1
			local path = ":sysvo/"..v[r]..game.soundext
			sesys_playtag("sysvo", path, { id=1 }, p)
		end

	-- 汎用ルーチン
	elseif z[name] and z.charlist then
		-- キャラ取得
		local c = {}
		local v = z[name]
		for n, i in pairs(v) do
			if conf["svo_"..n] == 1 then table.insert(c, n) end
		end
		local m = #c
		if m == 0 then
--			message("通知", "sysvo全キャラ無効化")
			return
		end

		-- キャラを選ぶ
		local r = e:random() % m + 1
		local n = c[r]

		-- ボイスを選ぶ
		local r = e:random() % #v[n] + 1
		local f = v[n][r]

		-- 再生
		local sv   = csv.sysse.sysvo.sysvowait or {}
		local exok = sv[name] and "exitok"
		local path = ":sysvo/"..f..game.soundext
		sesys_playtag("sysvo", path, { id=1, nosave=(exok) }, p)
	end
end
----------------------------------------
