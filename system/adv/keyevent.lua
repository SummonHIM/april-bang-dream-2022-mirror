----------------------------------------
-- keyevent / 全てのイベント管理
----------------------------------------
-- ※lyc/lydel/flip/trans等レイヤーツリーが変化するタグを実行するとクラッシュする
----------------------------------------
-- イベント割り振り
function eventFilter(e, nm, p)
	local r = 0
--	0 = 従来どおりエンジンがディスパッチ
--	1 = ディスパッチ成功したことにしてなにもしない（＝スクリプトで自前ディスパッチ）
--	2 = ディスパッチ失敗したことにしてなにもしない（1と基本は変わらないが、イベントによって後続の挙動が変わる。
--		setonpush由来のイベントで、そのキーの本来の処理が実行される、など
	local sw = {
		-- このファイル内で処理する
		setonpush	= function(p) return event_setonpush(p) end,
		lyevent		= function(p) return event_lyevent(p) end,

		-- 外部のファイルに飛ばして処理する

		-- ctrlskipはエンジンに返さない
		setoncontrolskipin	= function(p) event_ctrlinit("on" , p) return 1 end,
		setoncontrolskipout	= function(p) event_ctrlinit("off", p) return 1 end,

		-- 何もしない
		lytween				= function() return 0 end,
		setonwindowbutton	= function() return 0 end,
	}
	if sw[nm] then
		r = sw[nm](p)
		if nm == "setonpush" or nm == "lyevent" then flg.keyevent = nm end		-- 画面外判定用フラグ
--	else
--		message("event", nm)
	end
	return r
end
----------------------------------------
-- ctrlキー処理
function event_ctrlinit(nm, p)
	local m = getGameMode()
	if m == "adv" and nm == "on" then flg.skip = true
	else							  flg.skip = nil end
end
----------------------------------------
-- 
----------------------------------------
-- キー入力
function event_setonpush(p, f)
	local r = f or 0
	local k = tn(p.key)				-- key no
	local v = csv.advkey.def		-- key list
	local m = getGameMode("all")	-- game mode

	----------------------------------------
	if flg.advdragin and k == 1 then	r = 1	-- drag
	elseif flg.alt and k == 13 then		r = 1	-- ALT + Enter
	elseif allkeystop then				r = 1	-- 全キー停止
	elseif stf then								-- staffroll
	----------------------------------------
	else
		local name = v[k] and v[k].adv

		-- skip
		if flg.skipmode then
			flg.autoskipvsync = nil
			skipmode_stopevent()
			r = 1

		-- auto
		elseif flg.automode then
			-- オートモード時クリック動作 0:停止 1:停止せず次のblockへ
			if conf.autoclick == 1 and name == "CLICK" then
				r = 0
			else
				flg.autoskipvsync = nil
				automode_stopevent()
				r = 1
			end

		-- delay
		elseif flg.delay then
			flg.delay = "skip"
			flg.delaykey = { k, name, btn and btn.cursor }
			e:tag{"exec", command="skip", mode="1"}

		-- wait
		elseif m == "wait" then
			local f = true
			local w = flg.waitflag
			if w then
				local a = w[2] or 0
				local b = w[3] or 0
				if w[1] == "sound" and not flg.delay then	-- delay以外のse待機は通過させる
				elseif a - b <= 0 then f = nil end			-- wait=0のときはclickしない
			end

			-- wait skip
			if f then setexclick() end		-- dummy click
			r = 1

		-- 特殊click待ち / キー名
		elseif flg.waitexec then
			local w = flg.waitexec
			local n = nil
			local u = v[k] and v[k].ui
			if w[u] then
				n = w[u]
				flg.waitexec = nil
			end
			setexclick(n)
			r = 1

		-- 特殊click待ち / 番号
		elseif flg.waitnums then
			local w = flg.waitnums
			if w[k] then
				flg.waitnums = nil
				setexclick(w[k])
			end
			r = 1
		end
	end
	return r
end
----------------------------------------
-- ボタン入力
function event_lyevent(p)
	local r = 0
	local b = btn
	local x = tn(p.exec)

	----------------------------------------
	if x == 1 then						-- 強制実行
	elseif allkeystop then	r = 1		-- 全キー停止

	----------------------------------------
	-- btnあり制御
	elseif b then
		local gr = p.name == "select" and "adv" or p.name
		local nm = p.key		-- ボタン名
		local bn = b.name
		if gr == "tablet" then						-- tablet ui
		elseif flg.cgmode then						-- extra
		elseif not bn then							-- btn.nameが空の場合はADV扱い
			if gr ~= "adv" then				r = 1 end
		elseif bn ~= gr then				r = 1	-- ボタングループが異なる場合は実行しない
		elseif nm and getBtnStat(nm) then	r = 1	-- 無効化されたボタンは何もしない
		else

		end
	end
	return r
end
----------------------------------------
