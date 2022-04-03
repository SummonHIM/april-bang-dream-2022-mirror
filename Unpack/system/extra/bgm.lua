----------------------------------------
-- おまけ／BGM
----------------------------------------
-- 初期化
function exf.bginit()
	local file = getplaybgmfile()
	bgm_stop{}

	if not appex.bgmd then appex.bgmd = {} end

	-- 曲名取得 / 番号順に並べる
	local z    = lang.bgmname or {}
	local tbl  = {}
	local flag = init.extrabgm_flag == "all" and 1
	local text = nil
	for i, v in pairs(csv.extra_bgm) do
		local no = tn(v[1])
		if no and no > 0 then
			local f = flag or gscr.bgm[i]
			local t = z[i]
			if t then text = true end
			appex.bgmd[no] = { file=(i), no=(no), text=(t), flag=(f), time=(v.time) }
		end
	end
	appex.bgmd.text = text

	-- 開放確認
	appex.bgmd.open = {}
	local c  = 1
	for i, v in ipairs(appex.bgmd) do
		if v.flag then
			table.insert(appex.bgmd.open, v)
			appex.bgmd[i].count = c
			c = c + 1
		end
	end

	-- 現在のページ位置
	local p = appex.bgmd
	local max = appex.bgmd.pagemax or #p
	appex.bgmd.pg  = 0
	appex.bgmd.max = max	-- 曲数

	-- 曲名座標を読み込む
	local px = get_uipath().."extra/title.ipt"
	if p.p1 == "ipt" and isFile(px) then
		e:include(px)
		appex.bgmd.ipt  = tcopy(ipt)
	end

	exf.musicpage()

	-- noを再生中の曲に合わせる
	local file = getplaybgmfile()
	local no = max
	for i, v in ipairs(p) do
		if file == v.file then
			no = i
			appex.bgmd.play = scr.bgm.file and true
			break
		end
	end
	appex.bgmd.no = no
	appex.bgmd.play = scr.bgm.file and true

	-- repeat
--	local re = gscr.bgmd.rep or 0
--	exf.bgmrepeat(re)

	-- 再生中ならフラグを立てておく
--	local fl = getplaybgmfile()
--	if fl then exf.bgmplay(fl) end
--	exf.musictitle()
	exvolume_slider()
end
----------------------------------------
-- reset
function exf.bgmreset()
	if appex.bgmd.fadeout then appex.bgmd.play = nil end	-- fadeout中は再生フラグを倒す
	flg.callfunc = nil			-- 関数呼び出し無効化
--	flg.timercount = nil		-- 秒表示無効化

	-- text消去
	if appex.bgmd.text then
		local p, page, char = exf.getTable()
		local v = p.p
		local m = v.max
		for i=1, m do
			local nm = "bgm"..string.format("%02d", i)
			ui_message(getBtnID(nm)..".20")
		end
	else
		ui_message('500.tx.20')
		ui_message('500.tx.21')
	end
end
----------------------------------------
-- ページ切り替え
function exf.bgpage()
	exf.bgmreset()		-- text消去
	exf.musicpage()		-- 再描画
end
----------------------------------------
-- 現在のページ
function exf.musicpage()
	local p, page, char = exf.getTable()
	local v  = p.p
	local m  = v.max
	local fl = appex.bgmd.text
	local pg = 0
	if fl then
		local s = appex[appex.name].slider
		pg = (s.no or 0) * s.w
	end
	for i=1, m do
		local t  = v[i]
		local nm = "bgm"..string.format("%02d", i)

		-- text
		if fl then
			t = v[pg + i]
			local id = getBtnID(nm)..".20"
			local tx = t.flag and t.text or ""
			ui_message(id, { "exbgm", text=(tx) })
			setBtnStat(nm, nil)

		-- 画像
		else
			local c = not t.flag and 'd'
--			tag{"lyprop", id=(getBtnID(nm)), visible=(c)}
			setBtnStat(nm, c)
		end
	end
--	setBtnStat("bt_bgm", 'c')

	exf.musictitle()
end
----------------------------------------
-- 再生停止
function exf.musicreset()
	local p  = appex.bgmd
	local no = p.no
	if no and p[no] and p[no].flag then
		local nm = "bgm"..string.format("%02d", no)
		setBtnStat(nm, nil)
	end
	exf.bgmreset()
end
----------------------------------------
-- 曲名
function exf.musictitle()
	local fl = getplaybgmfile()
	local p  = appex.bgmd
	local s  = appex.bgmd.slider
	local mx = p.max
	local no = exf.getSliderMatrix(p.no)
	if fl then
		-- 再生中ボタン
		if no > 0 and no <= mx then
			local nm = "bgm"..string.format("%02d", no)
			local v  = getBtnInfo(nm)
			tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)}
--			setBtnStat(nm, 'c')
		end
	end
--[[
	-- 再生中
	if fl then
		-- 再生中ボタン
		local nm = "bgm"..string.format("%02d", no)
		setBtnStat(nm, 'c')

		-- play btn
		local v = checkBtnExist("bt_play") and getBtnInfo("bt_play")
		if v then tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)} end

		-- 曲名
		if p.p1 == "clip" then
			local v = getBtnInfo("title")
			local c = v.cx..","..(v.ch * (no-1))..","..v.cw..","..v.ch
			tag{"lyprop", id=(v.idx), visible="1", clip=(c)}
		elseif p.p1 == "ipt" and p.ipt then
			tag{"lyprop", id=(getBtnID("title")), clip=(p.ipt[nm])}
		end
]]
--[[
--		アレンジ含め１曲のみの場合はこの部分の項目が非表示（ARRANGE Ver. の文言と①、②、③ボタン非表示）
--		アレンジ含め２曲の場合は①と②ボタンが表示（③ボタンが非表示）
--		アレンジ含め３曲の場合は全てのボタンが表示
		local tx = p[no].text
		local id = "500.z.dw.ar"
		if tx then
			tag{"lyprop", id=(id), visible="1"}
			if tx:find("|") then
				tag{"lyprop", id=(getBtnID("arr03")), visible="1"}
			else
				tag{"lyprop", id=(getBtnID("arr03")), visible="0"}
			end

			-- Shuffle
			local sf = appex.bgmd.sf or 1
			setBtnStat('arr01', nil)
			setBtnStat('arr02', nil)
			setBtnStat('arr03', nil)
			setBtnStat(('arr0'.. sf), 'c')
		else
			tag{"lyprop", id=(id), visible="0"}
		end
]]
--[[
		----------------------------------------
		-- 再生コントロール
		if init.extra_bgmctrl == "on" then
			local t = p[no].time
			local b = scr.bgm
			if t and b and b.now then
				local t1 = t[1]
				local t2 = t[2] or 0
				local t3 = t[3] or init.bgm_fade
				local tm = t1 + t2 + b.now
				local lp = t2 > 0 and t2 or t1
				local px = { func="exbgmctrl_next", time=(tm) }
				appex.bgmd.rep = {
					add  = tm,	-- 経過時間(累計)
					time = lp,	-- ループ時間(加算)
					fade = t3	-- fade time
				}
				flg.callfunc = px
			else
				flg.callfunc = nil
			end
		end

	----------------------------------------
	-- 停止中
	else
		-- 曲名
--		if p.p1 then
--			tag{"lyprop", id=(getBtnID("title")), visible="0"}
--		end

		-- play btn
--		local v = checkBtnExist("bt_play") and getBtnInfo("bt_play")
--		if v then tag{"lyprop", id=(v.idx..".0"), clip=(v.clip)} end
	end
]]
end
----------------------------------------
-- １周経過時にrepeatのボタン状態を見て分岐
function exbgmctrl_next()
	local r  = gscr.bgmd.rep or 0		-- repeat状態
	local p  = appex.bgmd.rep or {}		-- time
	local tm = p.fade

	-- １周で停止
	if r == 0 then
		if tm == 0 then tag{"sstop", time=(tm)} end
		exf.bgmplaystop()

	-- １曲リピート
	elseif r == 1 then
		local ad = p.add + p.time + tm
		local px = { func="exbgmctrl_next", time=(ad) }
		appex.bgmd.rep.add = ad
		flg.callfunc = px

	-- play all / shuffle
	elseif tm == 0 then
		-- 次の曲へ
		appex.bgmd.rep.add = nil
		exbgm_musicnext()
	else
		-- fadeout
		appex.bgmd.fadeout = true
		tag{"sstop", time=(tm)}
		flg.callfunc = { func="exbgmctrl_fade", time=(tm + e:now()) }
	end
end
----------------------------------------
-- fade中にボタンが押されたかチェック
function exbgmctrl_fade()
	local r  = gscr.bgmd.rep or 0
	appex.bgmd.fadeout = nil
	appex.bgmd.rep.add = nil
	if r >= 2 then exbgm_musicnext() end
end
----------------------------------------
-- 
----------------------------------------
-- 次の曲へ
function exbgm_musicnext()
	exf.bgmadd(1)
end
----------------------------------------
-- volume
function music_volume(e, p)
	local c = conf.bgm
	local s = sys.extr.vol
	if c ~= s then
		conf.bgm = s
		volume_master()
		exvolume_slider()
	end
end
----------------------------------------
function exvolume_slider()
--[[
	local s = sys.extr.vol or 100
	local v = getBtnInfo("volume")
	local p = repercent(345, s) + 5
	local m = v.cy + v.ch*2
	local c = v.cx..","..m..","..p..","..v.ch
	local path = game.path.ui..v.file
	lyc2{ id=(v.idx..".4"), file=(path), clip=(c) }
]]
end
----------------------------------------
-- 
----------------------------------------
-- bgmボタンの属性を変える
function exf.musicbtn(bt, act)
	local fl = getplaybgmfile()
	local v  = getBtnInfo(bt)
	local p2 = tn(v.p2)
	local pg = 0
	local t  = appex.bgmd
	local s  = appex.bgmd.slider
	if s then
		pg = (s.no or 0) * s.w + p2

	end

	-- 再生中
	if fl and fl == t[pg].file then
		local cl = act and "clip_d" or "clip_c"
		tag{"lyprop", id=(v.idx..".0"), clip=(v[cl])}
	end
end
----------------------------------------
function extra_btmbtn_over(e, p) exf.musicbtn(p.name, true) end
function extra_btmbtn_out(e, p)	 exf.musicbtn(p.name) end
----------------------------------------
-- 
----------------------------------------
-- bgmクリック
function exf.clickbgm(num)
	local p  = appex.bgmd
	local s  = p.slider
	local no = num
	if s then
		no = (s.no or 0) * s.w + num
	else
		local max = p.max
		local pg  = p.pg
		no  = pg + num
		if no > max then no = max end
	end

--	message(num, max, pg, no)

	-- play
	if p[no].flag then
		se_ok()
		exf.bgmplay(p[no].file)
		appex.bgmd.no = no
		exf.bgpage()			-- 再描画
		flip()
	end
end
----------------------------------------
-- bgmボタン制御
function exf.clickbgmbtn(nm)
--	message("通知", nm)

	local sw = {
		play = function() se_ok() exf.bgmplaystop(true) end,	-- playボタン
		stop = function() se_ok() exf.bgmstop(true) end,		-- stopボタン
		back = function() se_ok() exf.bgmadd(-1) end,			-- backボタン
		next = function() se_ok() exf.bgmadd( 1) end,			-- nextボタン
	}
	if sw[nm] then sw[nm]() end
end
----------------------------------------
-- 次の曲へ
function exf.bgmadd(add)
	local p = appex.bgmd
	local v = p.open
	local max = #v
	local num = p.no
	if not p[num].count then return end
	exf.musicreset()

	local ct = p[num].count
	local g  = gscr.bgmd.rep or 0
	local sf = nil
	if g == 3 and max > 1 then
		-- Shuffle
		local old = ct
		repeat
			ct = (e:random() % (max-1)) + 1
		until old ~= ct
		sf = true
	else
		-- add
		ct = ct + add
		if ct > max then ct = 1 elseif ct < 1 then ct = max end 
	end

	local no = v[ct].no
	appex.bgmd.no = no		-- 曲番号

--[[
	----------------------------------------
	-- ページ変更確認
	local px, page, char = exf.getTable()
	local no = p.no
	local ax = math.floor( no / 15 ) + 1
	if page ~= ax then
		gscr.bgmd[char].page = ax
		exf.musicpage()
	end
]]
	----------------------------------------
	-- Shuffle
	local file = p[no].file
	if sf then
		local v  = p[no]
		local tx = v and v.text
		if tx then
			local mx = 2
			local zx = { file, tx }
			if tx:find('|') then
				local ax = explode("|", tx)
				zx[2] = ax[1]
				zx[3] = ax[2]
				mx = 3
			end
			sf = (e:random() % mx) + 1
			file = zx[sf]
		end
	end
	appex.bgmd.sf = sf		-- Shuffle flag

	-- play
	exf.bgmplay(file)
	exf.musictitle()
	flip()
end
----------------------------------------
-- 再生
function exf.bgmplay(name)
	appex.bgmd.play = true
	bgm_play{ file=(name) }
end
----------------------------------------
-- 再生ボタン
function exf.bgmplaystop(flag)
	local fl = getplaybgmfile()
	local v  = flag and getBtnInfo("bt_play")
	if fl then
		bgm_stop{}
		exf.musicreset()
		appex.bgmd.play = nil
		exf.musictitle()

		if flag then tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_a)} end
		flip()
	else
		local p  = appex.bgmd
		local no = p.no
		if appex.bgmd.text then
			local s = appex[appex.name].slider
			no = (s.no or 0) * s.w + no		
		end

		if p[no].flag then
			exf.bgmplay(p[no].file)
			exf.musictitle()

			if flag then tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_d)} end
			flip()
		end
	end
end
----------------------------------------
-- 停止ボタン
function exf.bgmstop(flag)
	local fl = getplaybgmfile()
	if fl then
		bgm_stop{}
		appex.bgmd.play = nil
		exf.musicreset()
		exf.musictitle()
		flip()
	end
end
----------------------------------------
-- bgm再開
function exf.bgmrestart()
	local p = appex.bgmd
	if p.play then
		exf.bgmplay(p[p.no].file)
	end
end
----------------------------------------
--
----------------------------------------
function ex_bgmrepeat(e, p)
	local nm = p.btn
	local v  = getBtnInfo(nm)
	local p1 = tn(v.p1)
	local p2 = v.p2
	local g  = gscr.bgmd.rep
	if g == p1 then p1 = 0 end
	gscr.bgmd.rep = p1

	-- 書き換え
	se_ok()
	exf.bgmrepeat(p1)
	local clip = p1 == 0 and "clip_a" or "clip_d"
	tag{"lyprop", id=(v.idx..".0"), clip=(v[clip])}
	flip()
end
----------------------------------------
function exf.bgmrepeat(no)
	local v1 = getBtnInfo("rep01")
	local v2 = getBtnInfo("rep02")
	local v3 = getBtnInfo("rep03")
	if no == 1 then
		tag{"lyprop", id=(v1.idx..".0"), clip=(v1.clip_c)}
		tag{"lyprop", id=(v2.idx..".0"), clip=(v2.clip)}
		tag{"lyprop", id=(v3.idx..".0"), clip=(v3.clip)}
	elseif no == 2 then
		tag{"lyprop", id=(v1.idx..".0"), clip=(v1.clip)}
		tag{"lyprop", id=(v2.idx..".0"), clip=(v2.clip_c)}
		tag{"lyprop", id=(v3.idx..".0"), clip=(v3.clip)}
	elseif no == 3 then
		tag{"lyprop", id=(v1.idx..".0"), clip=(v1.clip)}
		tag{"lyprop", id=(v2.idx..".0"), clip=(v2.clip)}
		tag{"lyprop", id=(v3.idx..".0"), clip=(v3.clip_c)}
	else
		tag{"lyprop", id=(v1.idx..".0"), clip=(v1.clip)}
		tag{"lyprop", id=(v2.idx..".0"), clip=(v2.clip)}
		tag{"lyprop", id=(v3.idx..".0"), clip=(v3.clip)}
	end
end
----------------------------------------
function exbgm_repover(e, p)
	local nm = p.name
	if nm == "bt_play" then
		local f = appex.bgmd.play
		if f then
			local v = getBtnInfo(nm)
			tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_d)}
		end
	else
		local g  = gscr.bgmd.rep
		local v  = getBtnInfo(nm)
		if g == tn(v.p1) then
			tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_d)}
		end
	end
end
----------------------------------------
function exbgm_repout(e, p)
	local nm = p.name
	if nm == "bt_play" then
		local f = appex.bgmd.play
		if f then
			local v = getBtnInfo(nm)
			tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)}
		end
	else
		local g  = gscr.bgmd.rep
		local v  = getBtnInfo(nm)
		if g == tn(v.p1) then
			tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)}
		end
	end
end
----------------------------------------
-- アレンジ版選択
function bgm_extraarrange(e, p)
	local bt = p.btn
	local v  = getBtnInfo(bt)
	if v then
		local p  = appex.bgmd
		local no = p.no
		local z  = p[no]
		local a  = explode("|", z.text);
		local p1 = tn(v.p1)
		local sw = {
			function()
				setBtnStat('arr01', 'c')
				setBtnStat('arr02', nil)
				setBtnStat('arr03', nil)
				exf.bgmplay(z.file)
			end,

			function()
				setBtnStat('arr01', nil)
				setBtnStat('arr02', 'c')
				setBtnStat('arr03', nil)
				exf.bgmplay(a[1])
			end,

			function()
				setBtnStat('arr01', nil)
				setBtnStat('arr02', nil)
				setBtnStat('arr03', 'c')
				exf.bgmplay(a[2])
			end,
		}
		if sw[p1] then se_ok() sw[p1]() flip() end
	end
end
----------------------------------------
