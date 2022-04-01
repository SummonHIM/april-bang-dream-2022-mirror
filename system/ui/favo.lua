----------------------------------------
-- お気に入りボイス
----------------------------------------
-- お気に入りボイス
function favo_init()
	message("通知", "お気に入りボイスを開きました")
--	se_ok()

	local s = scr.savecom

	-- ボタンワーク初期化
	if not sys.favo then sys.favo = {} end
	flg.save = {
		page	= (sys.favo.page or 1),	-- load時セーブしないようにコピーしておく
	}
	scr.savecom = "favo"
	flg.saveqload = nil

	-- 画面を作る
	favo_readcsv()
	favopage_init()
	if s ~= "favo" then
		uitrans()
	else
		uiopenanime("favo")
--		uitrans()
	end
end
----------------------------------------
function favo_readcsv()
	csvbtn3("favo", "500", lang.ui_favo)
--	setBtnStat('bt_favo', 'c')
end
----------------------------------------
-- 画面を作る
----------------------------------------
-- ボタン再描画
function favopage_init()
	local nb = flg.save.page				-- ページ番号
	local pg = (nb-1) * init.save_column	-- ページ先頭を計算
	local mt = init.favo_message_max		-- セーブ文字数
	local ad = init.favo_addname == "on"	-- テキストに名前を結合する
	local ln = get_language(true)			-- 言語

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
		local mx = favo_getmaxpage()
		local px = qs and "" or string.format("%02d/%02d", nb, init.save_page)
		ui_message('500.z.pageno', { tp, text=(px) })
	end
	set_uihelp("500.help", "uihelp")

	-- newマーク
	local news = conf.savenew == 1
	local newt = checkBtnExist('new') and getBtnInfo('new')
	local last = sys.favo.last				-- 最新データ
	local ss   = csv.mw.savethumb			-- サムネイル位置
	local fv   = csv.mw.favoface			-- お気に入りボイスface位置
	local btid = "."..ss.id
	local win  = game.os == "windows"

	-- mask / nodata
	local mspx = get_uipath()..'save/'
	local face = mspx.."maskface"
	local none = isFile(mspx.."none"..scr.savecom..".png") and mspx.."none"..scr.savecom or isFile(mspx.."none.png") and mspx.."none"
	local mask = isFile(mspx.."mask"..scr.savecom..".png") and mspx.."mask"..scr.savecom or isFile(mspx.."mask.png") and mspx.."mask"

--	local base = get_uipath().."save/char"
--	e:include(base..".ipt")

	-- 本文生成
	for i=1, init.favo_column do
		local no = pg + i
		local nx = string.format("%02d", i)
		local v  = getBtnInfo('bt_save'..string.format("%02d", i))
--		local vv = getBtnInfo('obj'..string.format("%02d", i))
		local t  = sys.favo[no]		-- セーブデータ確認
		local id = v.idx
		local thid = id..btid		-- サムネイルid
		local ed = 1
		lydel2(thid)

		-- no
		local sn = string.format("No.%02d-", nb)..nx
		if t0 then ui_message((id..'.20'), { t0, text=(sn)}) end	-- セーブNo
		if t1 then ui_message((id..'.21'), { t1 }) end				-- セーブ日付／ゲーム内
		if t2 then ui_message((id..'.22'), { t2 }) end				-- セーブタイトル
		if t3 then ui_message((id..'.23'), { t3 }) end				-- セーブテキスト

		-- セーブデータがある
		if t then
			local tx   = t.text
			local time = get_osdate("%Y/%m/%d %H:%M", t.date)
			local tttl = sv.changesavetitle(t.title or {})
			local tttx = tx[ln] or tx.text or ""
				if t.com		  then tttx = t.com
			elseif tx.select	  then tttx = sl
			elseif ad and tx.name then tttx = (tx.name[ln] or tx.name.name or "")..tttx end
			tttx = mb_substr(tttx, 1, mt)

			-- thumb
			local lc = true
			local fa = t.face
			if fa and fa[1] == "none" then
				local s = nil	--ipt[fa.text] or ipt[fa.name]
				if s then
					lyc2{ id=(thid..".1"), file=(base), x=(ss.x), y=(ss.y), clip=(s), mask=(mask)}
				end
			elseif fa then
				setMWFaceFile(fa, "favoface", thid..".1")
				tag{"lyprop", id=(thid), intermediate_render="1", intermediate_render_mask=(face)}
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
		for i=1, init.favo_page do
			local nm = "bt_page"..string.format("%02d", i)
			if i == pn then	setBtnStat(nm, 'c')
			else			setBtnStat(nm, nil) end
		end
	end

	-- active
	local bt = btn.cursor
	if bt and game.cs then btn_active2(bt) end

	-- おまけ画面
	if getExtra() then
		setBtnStat('bt_save', 'd')	tag{"lyprop", id=(getBtnID("bt_save" )), visible="0"}
		setBtnStat('bt_load', 'd')	tag{"lyprop", id=(getBtnID("bt_load" )), visible="0"}
		setBtnStat('bt_qload', 'd')	tag{"lyprop", id=(getBtnID("bt_qload")), visible="0"}

	-- タイトル画面
	elseif getTitle() then
		if checkBtnExist('bt_title') then setBtnStat('bt_title', 'c') end
		if checkBtnExist('bt_save')  then setBtnStat('bt_save' , 'd') end
--		tag{"lyprop", id=(getBtnID("bt_save")), visible="0"}
	end
end
----------------------------------------
-- 動作
----------------------------------------
-- セーブクリック
function favo_click(e, p)
	local bt = p.bt or btn.cursor
	if p.ui == 'EXIT' or bt == 'bt_ret' then
		save_clickret()

	elseif bt then
--		message("通知", bt, "が選択されました")

		local pg = flg.save.page

		local v = getBtnInfo(bt)
		local p1 = v.p1
		local p2 = v.p2

		local sw = {
			title = function() adv_title() end,
			exit  = function() adv_exit()  end,

			-- ページ変更
			page    = function() se_ok() favo_pagechange(tn(p2)) end,
			pageadd = function() se_ok() favo_pageadd(p2) end,
			change  = function() se_ok() saveload_change(p2) end,

			-- config呼び出し
			conf = function()
				se_ok()
				gscr.conf.page = tn(p2)
				adv_config()
			end,

			-- お気に入りボイス
			favo = function()
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
						favomove(m)
					end

				else
					-- 番号情報を作る
					local pg = flg.save.page
					local no = (pg-1) * init.save_column + p2
					local fv = flg.favo
					flg.save.no = no
					flg.save.p1 = tn(p2)

					-- 上書き
					if fv and sys.favo[no] then
						se_ok()
						dialog('favo2')

					-- 新規
					elseif fv then
						se_ok()
						dialog('favo')

					-- 再生
					else
						favoplay(no)
					end
				end
			end,

			-- 削除
			del = function()
				-- 番号情報を作る
				local pg = flg.save.page
				local no = (pg-1) * init.save_column + p2
				flg.save.no = no
				flg.save.p1 = tn(p2)

				se_ok()
				dialog('fdel')
			end,

			-- コメント
			edit = function()
				-- 番号情報を作る
				local pg = flg.save.page
				local no = (pg-1) * init.save_column + p2
				flg.save.no = no
				flg.save.p1 = tn(p2)

				se_ok()
				save_comment("favo")
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
		if sw[p1] then sw[p1]() end
	end
end
----------------------------------------
-- お気に入りボイス再生
function favoplay(no)
	local p = sys.favo[no]
	if p and p.text then
		message("通知", no, "を再生します")
		sesys_voreplay(p.text.vo)
	end
end
----------------------------------------
-- お気に入りボイスクリック
function favoclick()
	local no = flg.save.no
	local p  = flg.favo
	local th = p.face
	local vo = {}
	sys.favo.page = flg.save.page
	sysvo("favook")

	----------------------------------------
	-- 情報をスロットに保存する
	sys.favo[no] = {
		text  = p,					-- お気に入りボイスのテキスト
		title = sv.getsavetitle(),	-- セーブタイトル
		date  = get_unixtime(),		-- 現在時刻(unixtime)
		face  = th,					-- サムネイル
	}
	sys.favo.last = no				-- 最新データ
	flg.favo = nil
	wasm_favolock()					-- wasmsync

	----------------------------------------
	-- 再描画
	estag("init")
	estag{"asyssave"}
	estag{"saveload_reload"}
	estag()
end
----------------------------------------
-- 削除
function favodelete()
	local no = flg.save.no
	local v  = sys.favo
	if v[no] then
		wasm_favodelete(sys.favo[no])	-- wasmsync
		sys.favo[no] = nil
		wasm_favolock()					-- lock修正
		estag("init")
		estag{"asyssave"}
		estag{"saveload_reload"}
		estag()
	end
end
----------------------------------------
-- 移動
function favomove(m)
	local no = flg.save.no
	local v  = sys.favo
	local s  = tcopy(v[m])

	message("通知", m, "→", no)

	-- 入れ替え
	if v[no] then
		local z  = tcopy(v[no])
		sys.favo[m]  = z
		sys.favo[no] = s

	-- 移動
	else
		sys.favo[no] = s
		sys.favo[m] = nil
	end

	flg.save.move = nil
	estag("init")
	estag{"asyssave"}
	estag{"saveload_reload"}
	estag()
end
----------------------------------------
-- 
----------------------------------------
-- ページ切り替え
function favo_pagechange(p)
	flg.save.page = p
	favopage_init()
	flip()
end
----------------------------------------
-- ページ切り替え/加算
function favo_pageadd(add)
	local p = (flg.save.page or 1) + add
	local m = favo_getmaxpage()
	if p < 1 then p = m elseif p > m then p = 1 end
	favo_pagechange(p)
end
----------------------------------------
function favo_f1del()
	local no = flg.save.btnno
	if no then
		local bt = "bt_del"..string.format("%02d", no)
		favo_click(e, {bt=(bt)})
	end
end
----------------------------------------
function favo_f2move()
	local no = flg.save.btnno
	if no then
		local bt = "bt_move"..string.format("%02d", no)
		favo_click(e, {bt=(bt)})
	end
end
----------------------------------------
-- max page
function favo_getmaxpage()
	return init.favo_page
end
----------------------------------------
--
----------------------------------------
-- wasmsync用
function wasm_favolock()
	local s = sys.favo
	if s and checkWasmsync() then
		local w  = ""
		local z1 = init.system
		local z2 = init.mpath
		local vc = csv.voice
		local px01 = z1.image_path..z2.image.fa..'/'
		local px02 = z1.sound_path..z2.sound.vo..'/'
		local ex01 = game.fgext
		local ex02 = game.soundext

		----------------------------------------
		local savefavo = function(px)
			message("lock", px)
			if w == "" then w = px
			else			w = w..","..px end
			tag{"file", command="wasm_sync_add_persistent", target=(px)}
		end

		-- loop
		for i, v in pairs(s) do
			if tn(i) then
				local r = wasm_favoread(v)
				for i2, px in pairs(r) do
					savefavo(px)
				end
			end
		end

		-- save
		gscr.wasmfave = w
	end
end
----------------------------------------
-- リストから削除
function wasm_favodelete(p)
	if p and checkWasmsync() then
		local s = gscr.wasmfave
		local r = wasm_favoread(p)
		for i, px in pairs(r) do
			tag{"file", command="wasm_sync_delete_persistent", target=(px)}
			s = s:gsub(px, "")
		end
		gscr.wasmfave = s:gsub(",,", ",")
	end
end
----------------------------------------
function wasm_favoread(v)
	local r  = {}
	local p  = v.text
	local vc = csv.voice
	local z1 = init.system
	local z2 = init.mpath
	local vc = csv.voice
	local px01 = z1.image_path..z2.image.fa..'/'
	local px02 = z1.sound_path..z2.sound.vo..'/'
	local ex01 = game.fgext
	local ex02 = game.soundext

	-- voice
	for i2, t in pairs(p.vo) do
		local ch = t.ch
		local vo = vc[ch]
		local px = vo.path:gsub(":vo/", px02)..t.file..ex02
		table.insert( r, "./"..px )
	end

	-- face
	local z = p.face
	if z and z.path then
		local px  = z.path:gsub(":fa/", px01)
		local tbl = { "file", "face", "ex01", "ex02", "ex03", "ex04" }
		for i2, nm in ipairs(tbl) do
			if z[nm] then
				table.insert( r, "./"..px..z[nm].file..ex01 )
			end
		end
	end
	return r
end
----------------------------------------
