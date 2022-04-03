----------------------------------------
-- セーブ／ロード
----------------------------------------
-- セーブ
function save_init()
	message("通知", "セーブ画面を開きました")
	sysvo("save_open") 

	-- ボタンワーク初期化
	flg.save = {
		page	= (sys.saveslot.page or 1),	-- load時セーブしないようにコピーしておく
	}
	scr.savecom = "save"
	flg.saveqload = nil

	-- 画面を作る
	save_readcsv()
	saveload_init()
	uiopenanime("save")
end
----------------------------------------
-- ロード
function load_init()
	message("通知", "ロード画面を開きました")
	sysvo("load_open")

	-- ボタンワーク初期化
	flg.save = {
		page	= (sys.saveslot.page or 1),	-- load時セーブしないようにコピーしておく
	}
	scr.savecom = "load"

	-- セーブデータがない場合はautosaveかqsaveのページを開く
--	if sys.saveslot.last == 0 and sys.saveslot.cont then
--		flg.save.page = math.ceil(sys.saveslot.cont / init.save_column)
--	end

	-- 画面を作る
	if flg.saveqload then qload_readcsv()
	else				  load_readcsv() end

	saveload_init()
	uiopenanime("save")
end
----------------------------------------
function save_readcsv()
	csvbtn3("save", "500", lang.ui_save)
--	setBtnStat('bt_save', 'c')
end
----------------------------------------
function load_readcsv()
	csvbtn3("load", "500", lang.ui_load)
--	setBtnStat('bt_load', 'c')
end
----------------------------------------
function qload_readcsv()
	csvbtn3("load", "500", lang.ui_qload)
--	lyc2{ id="500.99", file=(get_uipath().."loadq")}
--	setBtnStat('bt_qload', 'c')
end
----------------------------------------
-- 
----------------------------------------
-- 状態クリア
function save_reset()
--	if not p.flag then se_cancel() end

	-- メッセージ消去
	ui_message("500.z.pageno")
	for i=1, init.save_column do
		local no = string.format("%02d", i)
		ui_message(getBtnID("bt_save"..no)..'.20')
		ui_message(getBtnID("bt_save"..no)..'.21')
		ui_message(getBtnID("bt_save"..no)..'.22')
		ui_message(getBtnID("bt_save"..no)..'.23')
	end
	save_delthumb_l()		-- 大サムネイル

	del_uihelp()			-- ui help
	delbtn(scr.savecom)		-- 削除
	flg.save = nil			-- ボタン用ワークを削除
	flg.favo = nil			-- お気に入りボイス用記録データ
	flg.saveqload = nil
	flg.saveanime = nil
	sys.save = nil
	sys.load = nil
end
----------------------------------------
-- save画面から抜ける
function save_close()
	message("通知", "セーブ画面を閉じました")

--	se_cancel()
	uicloseanime("save")
end
----------------------------------------
-- 画面を作る
----------------------------------------
-- ボタン再描画
function saveload_init()
	local nb = flg.save.page				-- ページ番号
	local pg = (nb-1) * init.save_column	-- ページ先頭を計算
	local fp = e:var("s.savepath").."/"		-- セーブフォルダ
	local hd = scr.savecom					-- フォントの先頭
	local mx = init.save_message_max		-- セーブ文字数
	local ad = init.save_addname == "on"	-- テキストに名前を結合する
	local ln = get_language(true)			-- 言語
	local sl = get_langsystem("select")		-- 選択肢

	-- qload page
	local qs = nil
	if flg.saveqload then
		pg = game.qsavehead
		qs = true
--		tag{"lyprop", id="500.up", visible="0"}		-- qsaveはページなし
	end

	-- font color
	local ft = lang.font
	local fc = qs and "qload" or scr.savecom
	local t0 = ft[fc.."no"]	  and fc.."no"	 or ft.saveno	and "saveno"
	local t1 = ft[fc.."date"] and fc.."date" or ft.savedate and "savedate"
	local t2 = ft[fc.."titl"] and fc.."titl" or ft.savetitl and "savetitl"
	local t3 = ft[fc.."text"] and fc.."text" or ft.savetext and "savetext"
	local tp = ft[fc.."page"] and fc.."page" or ft.savepage and "savepage"

	-- ページ番号書き換え
	if tp then
--		local mx = save_getmaxpage()
--		local px = qs and "QuickLoad" or string.format("%03d / %03d", nb, mx)
		local px = qs and "" or string.format("%02d/%02d", nb, init.save_page)
		ui_message('500.z.pageno', { tp, text=(px) })
	end
	set_uihelp("500.help", "uihelp")

	-- lock
	if not sys.saveslot.lock then sys.saveslot.lock = {} end
	local lk = sys.saveslot.lock

	-- newマーク
	local news = conf.savenew == 1
	local newt = checkBtnExist('new') and getBtnInfo('new')
	local last = sys.saveslot.last
	local ss   = csv.mw.savethumb			-- サムネイル位置
	local btid = "."..ss.id
	local path = e:var("s.savepath")..'/'	-- savepath
--	local base = get_uipath().."save/btn_text"
	local win  = game.os == "windows"
	local hev  = init.game_evmask == "on"

	-- mask / none
	local mspx = get_uipath()..'save/'
	local none = isFile(mspx.."none"..fc..".png") and mspx.."none"..fc or isFile(mspx.."none.png") and mspx.."none"
	local mask = isFile(mspx.."mask"..fc..".png") and mspx.."mask"..fc or isFile(mspx.."mask.png") and mspx.."mask"

	-- 本文生成
	for i=1, init.save_column do
		local no = pg + i
		local nx = string.format("%02d", i)
		local v  = getBtnInfo('bt_save'..string.format("%02d", i))
		local t  = isSaveFile(no)			-- セーブデータ確認
		local id = v.idx
		local thid = id..btid				-- サムネイルid
		local ed = 1
		lydel2(thid)

		-- no
--		set_saveno(no, id)
		local sn = qs and "Quick."..nx or string.format("No.%02d-", nb)..nx
--		if no > game.asavehead then sn = "auto "..string.format("%03d", no - game.asavehead) end
		if t0 then ui_message((id..'.20'), { t0, text=(sn)}) end	-- セーブNo
		if t1 then ui_message((id..'.21'), { t1 }) end				-- セーブ日付／ゲーム内
		if t2 then ui_message((id..'.22'), { t2 }) end				-- セーブタイトル
		if t3 then ui_message((id..'.23'), { t3 }) end				-- セーブテキスト

		-- 追加画像
--		lyc2{ id=(id..'.10'), file=(base)}
--		local delid  = getBtnID("del0"..i)
--		local lockid = getBtnID("lock0"..i)

		-- セーブデータがある
		if t then
			local tx   = t.text
			local time = get_osdate("%Y/%m/%d %H:%M", t.date)
			local tttl = sv.changesavetitle(t.title or {})
			local tttx = tx[ln] or tx.text or ""
				if t.com		  then tttx = t.com
			elseif tx.select	  then tttx = sl
			elseif ad and tx.name then tttx = (tx.name[ln] or tx.name.name or "")..tttx end
			tttx = mb_substr(tttx, 1, mx)

			-- thumb
			local lc = true

			-- HEVマスク
			local evm = t.evmask
			if hev and evm then
				local pppx = ":evmask/"..evm
				lyc2{ id=(thid..".0"), file=(pppx), x=(ss.x), y=(ss.y), mask=(mask)}
			else
				local th = path..t.file
				lyc2{ id=(thid..".0"), file=(th), x=(ss.x), y=(ss.y), mask=(mask)}
			end
			if t1 then ui_message((id..'.21'), time) end		-- セーブ日付／ゲーム内
			if t2 then ui_message((id..'.22'), tttl) end		-- セーブタイトル
			if t3 then ui_message((id..'.23'), tttx) end		-- セーブテキスト

			-- 当たり判定
			if win and v.flag and tn(v.flag) < 0 then
				tag{"lyprop", id=(id..'.0'), clickablethreshold="255"}
			end

			-- newマークを付ける
			if newt and news and no == last then
				e:tag{"lyprop", id=(newt.idx), visible="1", left=(v.x + newt.x), top=(v.y + newt.y)}
				news = -1
			end

		-- ない
		else
			-- 当たり判定
			if win and v.flag and tn(v.flag) < 0 then
				tag{"lyprop", id=(id..'.0'), clickablethreshold="0"}
			end

			-- 消去
			if t1 then ui_message(id..'.20') end		-- No.
			if t2 then ui_message(id..'.21') end		-- セーブ日付／ゲーム内
			if t3 then ui_message(id..'.22') end		-- セーブテキスト
			if t4 then ui_message(id..'.23') end		-- セーブタイトル

			-- no data
			if none then
				lyc2{ id=(thid..".0"), file=(none), x=(ss.x), y=(ss.y), mask=(mask)}
			end
			ed = 0
		end

		-- edit
		local vs = (qs or flg.save.move) and 0 or ed
		if checkBtnExist("bt_edit"..nx) then tag{"lyprop", id=(getBtnID("bt_edit"..nx)), visible=(vs)} end
		if checkBtnExist("bt_move"..nx) then tag{"lyprop", id=(getBtnID("bt_move"..nx)), visible=(vs)} end
		if checkBtnExist("bt_del" ..nx) then tag{"lyprop", id=(getBtnID("bt_del" ..nx)), visible=(vs)} end
	end

	-- newマークがなかった
	if newt and news ~= -1 then
		e:tag{"lyprop", id=(newt.idx), visible="0"}
	end

	-- ページボタン
	if not qs and checkBtnExist("bt_page01") then
		local pn = flg.save.page
		for i=1, init.save_page do
			local nm = "bt_page"..string.format("%02d", i)
			if i == pn then	setBtnStat(nm, 'c')
			else			setBtnStat(nm, nil) end
		end
	end

	-- active
	local bt = btn.cursor
	if bt and game.cs then btn_active2(bt) end

	-- タイトル画面
	if getTitle() then
		if checkBtnExist('bt_title') then setBtnStat('bt_title', 'c') end
		if checkBtnExist('bt_save')  then setBtnStat('bt_save' , 'd') end
--		tag{"lyprop", id=(getBtnID("bt_save")), visible="0"}
	end
end
----------------------------------------
-- max page
function save_getmaxpage()
	return game.cs and init.save_pagecs or init.save_page
end
----------------------------------------
-- lock check
function save_lockcheck(no)
	local pg = (flg.save.page-1) * init.save_column
	local lk = sys.saveslot.lock
	return lk[pg+no]
end
----------------------------------------
-- lock
function save_lockout(e, p)
	local bt = p.name
	if bt then
		local lv = getBtnInfo(bt)
		local no = tn(lv.p2)
		if save_lockcheck(no) then
			e:tag{"lyprop", id=(lv.idx..".0"), clip=(lv.clip_c)}
		end
	end
end
----------------------------------------
-- 再描画
function saveload_reload()
	local bt = getbtn_actcursor()		-- 直前のアクティブ情報取得
	local hd = scr.savecom
	local sw = {
		save  = function()  save_readcsv() end,
		load  = function()  load_readcsv() end,
		qload = function() qload_readcsv() end,
		favo  = function()  favo_readcsv() end,
	}
	if sw[hd] then sw[hd]() end
	save_delthumb() flip()
	if hd == "favo" then	favopage_init()
	else					saveload_init() end
	if bt then btn_active2(bt) end		-- アクティブ再設定
	flip()
end
----------------------------------------
function saveload_change(name)
	local nm = name
	if nm:find('|') then
		local a = explode("|", nm)
		nm = getTitle() and a[2] or a[1]
	end
	flg.save.move = nil
	if nm == "qload" then flg.saveqload = true else flg.saveqload = nil end
	local sw = {
		save  = function() sysvo("open_save") save_init() end,
		load  = function() sysvo("open_load") load_init() end,
		qload = function() sysvo("open_load") load_init() end,
		favo  = function() sysvo("open_favo") favo_init() end,
	}
	if sw[nm] then sw[nm]() end
end
----------------------------------------
-- セーブ番号描画
function set_saveno(num, id)
	local p = NumToGrph(num)
	local v = getBtnInfo('num')
	local t = 0
		if p[1] >= 20 then t = 1 p[1] = p[1] - 20
	elseif p[1] >= 10 then t = 1 p[1] = p[1] - 10 end
	table.insert(p, 1, t)

	local x = v.x
	local y = v.y
	local w = v.cw
	local a = ","..v.cy..","..v.cw..","..v.ch
	for i=1, #p do
		local idx  = id..".3"..i
		local clip = (p[i] * w + v.cx)..a
		lyc2{ id=(idx), file=(v.path..v.file), x=(x), y=(y), clip=(clip)}
		x = x + w - 1
	end
--[[
	local x = v.x + v.w - 1
	local y1 = v.h * p[1] + v.cy
	local y2 = v.h * p[2] + v.cy
	local c1 = v.cx..","
	local c2 = ","..v.cw..","..v.ch
	lyc2{ id=(id..".30"), file=(v.path..v.file), x=(v.x), y=(v.y), clip=(c1..y1..c2)}
	lyc2{ id=(id..".31"), file=(v.path..v.file), x=(x  ), y=(v.y), clip=(c1..y2..c2)}
]]
end
----------------------------------------
-- 
----------------------------------------
-- 大サムネイル
function save_thover(e, p)
	local name = p.name
	local v  = getBtnInfo(name)
	local th = csv.mw.savethumb_l
	if v and th then
		local p2 = v.p2
		local pg = (flg.save.page-1) * init.save_column + p2

		if flg.saveqload then pg = game.qsavehead + p2 end

		local fp = e:var("s.savepath").."/"
		local tb = sys.saveslot[pg]
		if tb and isSaveFile(pg) then
			local hev  = init.game_evmask == "on"
			local evm  = tb.evmask
			local file = fp..tb.file.."_l"
			if hev and evm then file = ":evmask/z/"..evm end
			lyc2{ id=("500."..th.id), file=(file), x=(th.x), y=(th.y)}

			-- text
			local id = "500.big."
			local dt = get_osdate("%Y/%m/%d  %H:%M", tb.date)
			local hd = flg.saveqload and "qload" or scr.savecom
			local ft = lang.font
			local t0 = ft[hd.."no_l"]	and hd.."no_l"	 or ft.saveno_l	  and "saveno_l"
			local t1 = ft[hd.."date_l"] and hd.."date_l" or ft.savedate_l and "savedate_l"
			local t2 = ft[hd.."titl_l"] and hd.."titl_l" or ft.savetitl_l and "savetitl_l"
			local t3 = ft[hd.."text_l"] and hd.."text_l" or ft.savetext_l and "savetext_l"
			if t0 then ui_message(id..'nums', {t0, text=(no)}) end			-- no
			if t1 then ui_message(id..'date', {t1, text=(dt)}) end			-- date
			if t2 then ui_message(id..'titl', {t2, text=(tb.title)}) end	-- save title
			if t3 then ui_message(id..'text', {t3,	text=(tb.text)}) end	-- save text

			-- new
			local news = init.save_newicon == "on" and conf.savenew == 1
			if news and checkBtnExist("new_l") then
				local idid = getBtnID("new_l")
				local last = sys.saveslot.last
				if pg == last then tag{"lyprop", id=(idid), visible="1"}
				else			   tag{"lyprop", id=(idid), visible="0"} end
			end
		else
			save_delthumb_l()
		end
	end
end
----------------------------------------
-- 大サムネイル戻し
function save_thout(e, p)
	if game.os == "windows" then
		save_delthumb_l()
	end
end
----------------------------------------
-- 大サムネイルを消去
function save_delthumb_l()
	local th = csv.mw.savethumb_l
	if th then
		lydel2("500."..th.id)

		local id = "500.big."
		ui_message(id..'nums')
		ui_message(id..'date')
		ui_message(id..'titl')
		ui_message(id..'text')
		local news = init.save_newicon == "on" and conf.savenew == 1 and checkBtnExist("new_l")
		if news then tag{"lyprop", id=(getBtnID("new_l")), visible="0"} end
	end
end
----------------------------------------
-- サムネイルを消去
function save_delthumb()
--[[
	for i=1, init.save_column do
		local no = string.format("%02d", i)
		local id = getBtnID('bt_save'..no)
		lydel2(id..'.10')
	end
]]
end
----------------------------------------
-- 動作
----------------------------------------
-- セーブクリック
function save_click(e, p)
	local bt = p.bt or btn.cursor
	if p.ui == 'EXIT' or bt == 'bt_ret' then
		save_clickret()

	elseif bt then
--		message("通知", bt, "が選択されました")

		local pg = flg.save.page
		local v  = getBtnInfo(bt)
		local p1 = v.p1
		local p2 = v.p2
--[[
		if p1 == "del" then
			p1 = p2
			local no = (pg-1) * init.save_column + p2
			local lk = sys.saveslot.lock[no]
			if not lk then flg.save.delete = true end
		end
]]
		local sw = {
			title = function() adv_title() end,
			exit  = function() adv_exit()  end,

			-- ページ変更
			page    = function() se_ok() save_pagechange(tn(p2)) end,
			pageadd = function() se_ok() save_pageadd(p2) end,
			change  = function() se_ok() saveload_change(p2) end,

			-- config呼び出し
			conf = function()
				se_ok()
				if not gscr.conf then gscr.conf = {} end
				gscr.conf.page = tn(p2)
				adv_config()
			end,

			-- lock
			lock = function()
				local no = (pg-1) * init.save_column + p2
				local lk = sys.saveslot.lock[no]
				if lk then se_cancel()	sys.saveslot.lock[no] = nil
				else	   se_ok()		sys.saveslot.lock[no] = true end
				saveload_reload()
			end,

			-- 移動モード
			move = function()
				se_ok()
				local pg = flg.save.page
				local no = (pg-1) * init.save_column + p2
				flg.save.move = no
				saveload_reload()
			end,
		}
		if sw[p1] then sw[p1]()

		-- save / load
		elseif p1 == "save" or p1 == "del" or p1 == "edit" then
			-- 移動
			local m = flg.save.move
			if m then
				local pg = flg.save.page
				local no = (pg-1) * init.save_column + p2
				if m == no then
					se_cancel()
					flg.save.move = nil
					saveload_reload()
				else
					se_yes()
					flg.save.no = no
					saveload_move(m)
				end

			else

			-- 番号情報を作る
			local pg = flg.save.page
			local no = (pg-1) * init.save_column + p2
			local lk = save_lockcheck(p2)	-- lock情報

			-- qload page
			if flg.saveqload then no = game.qsavehead + p2 end

			local t = isSaveFile(no)			-- セーブデータ確認
			flg.save.no = no
			flg.save.p1 = tn(p2)

			-- コメント編集	
			if p1 == "edit" then
				if not lk and t then
					se_ok()
					save_comment("save")
				end

			-- delete
			elseif flg.save.delete or p1 == "del" then
				if not lk and t then
					se_ok()
					sv.delparam = no
					dialog('del')
					flg.save.delete = nil
				end

			-- save
			elseif scr.savecom == "save" then
				if lk then
					se_none()
				else
					se_ok()

					-- 上書き
					if t then
						dialog('save2')
	
					-- 新規
					else
						dialog('save')
					end
				end

			-- load
			elseif t then
					se_ok()
					sv.loadfile = t.file
					dialog('load')
			end
			end
		end
	end
end
----------------------------------------
-- returnボタン
function save_clickret()
	if flg.save.move then
		se_cancel()
		sysvo("dlgno")
		flg.save.move = nil
		saveload_reload()
	elseif flg.save.delete then
		se_cancel()
		flg.save.delete = nil
		saveload_reload()
	else
		close_ui()
	end
end
----------------------------------------
-- deleteボタン
function save_clickdel()
	if not flg.save.delete then
		se_ok()
		flg.save.delete = true

		lyc2{ id="500.z", file=(get_uipath().."delmask")}

		setBtnStat('bt_del', 'c')

		setBtnStat('bt_title', 'c')
		setBtnStat('bt_exit' , 'c')
		setBtnStat('bt_save' , 'd')
		setBtnStat('bt_load' , 'd')
		setBtnStat('bt_qload', 'd')

		local pg = flg.save.page
		for i=1, 10 do
			if i ~= pg then
				local nm = "bt_page"..string.format("%02d", i)
				setBtnStat(nm, 'd')
			end
		end
		flip()
	end
end
----------------------------------------
-- 移動
function saveload_move(m)
	local no = flg.save.no
	local v  = sys.saveslot
	local s  = tcopy(v[m])

	message("通知", m, "→", no)

	-- 入れ替え
	if v[no] then
		local z  = tcopy(v[no])
		sys.saveslot[m]  = z
		sys.saveslot[no] = s

	-- 移動
	else
		sys.saveslot[no] = s
		sys.saveslot[m] = nil
	end

	-- 最新ファイルの確認
	sv.checknewfile()

	flg.save.move = nil
	estag("init")
	estag{"asyssave"}
	estag{"saveload_reload"}
	estag()
end
----------------------------------------
-- コメント書き換え
function save_comment(nm)
	local no = flg.save.no
	local s  = nm == "save" and sys.saveslot or nm == "favo" and sys.favo
	if no and s[no] then
		local v  = s[no]
		local tx = v.text
		local ln = get_language(true)
		local sn = v.com or tx[ln]

		-- dialog text
		local v  = getLangHelp("dlgmes")
		local tl = v and (nm == "favo" and v.favocomment or v.savecomment) or "comment"
		tag_dialog({ title=(tl), varname="t.yn", textfield="t.tx", textfieldsize="100", message=(sn) }, "save_commentsave", nm)
	end
end
----------------------------------------
function save_commentsave(nm)
	local no = flg.save.no
	local s  = nm == "save" and sys.saveslot or nm == "favo" and sys.favo
	local yn = tn(e:var("t.yn"))
	local tx = e:var("t.tx")
	if yn == 1 then
		se_yes()
		sysvo("dlgyes")

		-- 念の為文字数を制限
		local mx = init.save_message_max
		if tx == "" then tx = nil else tx = mb_substr(tx:gsub("\n", ""), 1, mx) end

		-- 保存
		s[no].com = tx
		estag("init")
		estag{"asyssave"}
		estag{"saveload_reload"}
		estag()
	else
		se_no()
		sysvo("dlgno")
	end
end
----------------------------------------
-- ボタン番号を保存しておく
function save_btnover(e, p)
	local bt = p.name
	if bt then
		local v = getBtnInfo(bt)
		local p2 = v.p2
		flg.save.btnno = p2
	end
end
----------------------------------------
function save_btnout(e, p)
	local bt = p.name
	if bt then
		local v  = getBtnInfo(bt)
		local p2 = v.p2
		local no = flg.save.btnno
		if p2 == no then
			flg.save.btnno = nil
		end
	end
end
----------------------------------------
function save_f1del()
	local no = flg.save.btnno
	if no then
		local bt = "bt_del"..string.format("%02d", no)
		save_click(e, {bt=(bt)})
	end
end
----------------------------------------
function save_f2move()
	local no = flg.save.btnno
	if no then
		local bt = "bt_move"..string.format("%02d", no)
		save_click(e, {bt=(bt)})
	end
end
----------------------------------------
-- 
----------------------------------------
-- ページ切り替え
function save_pagechange(p)
	flg.save.page = p
	saveload_init()
	flip()
end
----------------------------------------
-- ページ切り替え/加算
function save_pageadd(add)
	local p = (flg.save.page or 1) + add
	local m = save_getmaxpage()
	if p < 1 then p = m elseif p > m then p = 1 end
	save_pagechange(p)
end
----------------------------------------
-- L1キー処理
function save_l1(e, p)
--	se_page()
	local no = flg.save.page
	local mx = init.save_page
	if scr.savecom == "load" then mx = mx + 1 end
	no = no - 1
	if no < 1 then no = mx end
	save_pagechange(no)
end
----------------------------------------
-- R1キー処理
function save_r1(e, p)
--	se_page()
	local no = flg.save.page
	local mx = init.save_page
	if scr.savecom == "load" then mx = mx + 1 end
	no = no + 1
	if no > mx then no = 1 end
	save_pagechange(no)
end
----------------------------------------
function save_helpover(e, p)
	local nm = p.name
	if nm then
		local lv = getBtnInfo(nm)
		local no = tn(lv.p3)
		local v  = getBtnInfo("message")
		local cl = v.cx..","..(v.cy+v.ch*no)..","..v.cw..","..v.ch
		e:tag{"lyprop", id=(getBtnID("help")), visible="1"}
		e:tag{"lyprop", id=(getBtnID("message")), visible="1", clip=(cl)}
		flg.help = nm
	end
end
----------------------------------------
function save_helpout(e, p)
	local nm = p.name
	local sp = flg.help
	if nm and nm == sp and game.os ~= "android" then
		e:tag{"lyprop", id=(getBtnID("help")), visible="0"}
		e:tag{"lyprop", id=(getBtnID("message")), visible="0"}
		flg.help = nil
	end
end
----------------------------------------
-- 
----------------------------------------
-- 
function save_delete()
	local bt = btn.cursor
	if bt then
		local v  = getBtnInfo(bt)
		if v.p1 then
			local no = (flg.save.page-1) * init.save_column + v.p1
			local t  = isSaveFile(no)			-- セーブデータ確認
			if t then
				sv.delparam = no
				dialog("del")
			end
		end
	end
end
----------------------------------------
-- 
----------------------------------------
-- quickロードファイルチェック
function quickloadCheck()
	return isSaveFile(sys.saveslot.quick, "quick")
end
----------------------------------------
