----------------------------------------
-- ADVメッセージ
----------------------------------------
local ex = {
	ln = "lastname",	-- 名字
	fn = "firstname",	-- 名前
}
----------------------------------------
-- メッセージレイヤー／テキスト描画
function mw_text(v)
	if flg.exskip then return end

	autoskip_keystop()

	-- user
	local nm = "user_checktext"
	if _G[nm] then _G[nm]() end

	local p = getTextBlock()	-- text block取得
	if type(p.linemode) == "table" then
		mw_line(v)

	-- hide処理
	elseif p.hide then
		estag("init")
		estag{"msgoff"}
		estag{"mw_voice", p}
		estag()

	-- text処理
	else
		local i = scr.ip.textcount or 0
		i = i + 1
		scr.ip.textcount = i

		-- mw timeを設定
		local tm = p.time
		if tm then
			mw_time(tm)
			flg.mw_timeonce = true
		end

		-- text
		if i == 1 then
			estag("init")
			estag{"msgon"}				-- 念の為mw表示
			estag{"mw_voice", p}		-- ボイス設置
			estag{"sm_text", p}			-- float
			estag{"mw_name", p}			-- 名前表示
			estag{"mw_advtext", p}		-- 本文表示
			estag()
		end
	end
end
----------------------------------------
-- 音声
function mw_voice(p)
	faceview(p)
	if p.vo then
		sesys_vostack(p.vo)
		sesys_voloop()
	end
end
----------------------------------------
-- 文字速度
function mw_time(time)
	local tm = time
	if tm then	if tm < 0 then tm = 0 elseif tm > 100 then tm = 100 end
	else		tm = getMSpeed() end

	-- main
	tag{"chgmsg", id=(mw_getmsgid("adv"))}
	set_message_speed_tween(tm)
	tag{"/chgmsg"}

	-- sub
	if init.game_sublangview == "on" then
		tag{"chgmsg", id=(mw_getmsgid("sub"))}
		set_message_speed_tween(tm)
		tag{"/chgmsg"}
	end
	scr.mstime = time
end
----------------------------------------
-- 
----------------------------------------
-- 文字色取得
function getMWColor(nm)
	local r = nil
	local m = getGameMode()
	if m == "adv" and init.text_mwcolor == "on" or m == "ui" and init.text_logcolor == "on" then
		local v = csv.voice.name[nm]
		if v then
			r = {"font", color=(v.color), shadowcolor=(v.shadowcolor), outlinecolor=(v.outlinecolor)}
		end
	end
	return r
end
----------------------------------------
-- name
----------------------------------------
-- 名前設置
function mw_name(p)
	local v = getTextBlockFloat(p)
	local n = v and v.name
	if n then
		local nm = getNameChar(p, true)

		-- 文字色
		local cl = getMWColor(nm)
		scr.mwcolor = cl

		-- name
		message_name(nm, cl)
	end
end
----------------------------------------
-- メッセージレイヤー／名前
function message_name(text, cl)
	local textdraw = function(text)
		local cx = init.mwnameframe		-- 名前【】
		if cx and type(cx) == 'table' then text = cx[1]..text..cx[2] end
		tag{"print", data=(text)}
	end

	----------------------------------------
	-- novel
	local nv = getNovelData()
	if nv then
		if text then
			local nm = init.game_novelname
			if nm then
				local ar = getAread()
				local ma = conf.mw_aread or 0
				local cl = ar and ma == 1 and init.novelaread_color	-- novelは既読色がある
				if cl then tag{"font", color=("0"..cl)} end
				textdraw(text)
				if cl then tag{"/font"} end
				if nm == "rt" then tag{"rt"} end
			end
		end

	----------------------------------------
	-- 画像のみ
	elseif init.mw_namemode == "img" then
		local id = getMWID("name")
		local ex = init.mwnameimage
		if ex and _G[ex] then
			_G[ex](text)
		elseif text then
			local t  = csv.mw.name
			local px = string.lower(get_uipath()..t.file..text)
			local id = game.mwid.."."..t.id
			lyc2{ id=(id), file=(px), x=(t.x), y=(t.y)}
		else
			lydel2(id)
		end

	----------------------------------------
	-- normal
	else
		local id = getMWID("name")
		tag{"chgmsg", id=(mw_getmsgid("name"))}
		tag{"rp"}
		if text then
			-- 名前画像
			if id then
				local nm = init.mwnameimage
				if nm and _G[nm] then _G[nm](id, text) end
				tag{"lyprop", id=(id), visible="1"}
			end
			if cl then tag(cl) end
			textdraw(text)
			if cl then tag{"/font"} end
		else
			if id then tag{"lyprop", id=(id), visible="0"} end
		end
		tag{"/chgmsg"}
	end
end
----------------------------------------
-- メッセージレイヤー／呼び出し
function mw_advtext(tbl)
	message_control(tbl, true)
end
----------------------------------------
-- sm
function sm_text(p)
	if smex then
		-- open
		if p then
			if p.float then smex.sm_open(p.float) end

		-- close
		else
			smex.sm_close()
		end
	end
end
----------------------------------------
-- 本文メッセージ制御
----------------------------------------
-- mwid取得
function mw_getmsgid(name)
	local nm = "adv_"..name
	return game.mwid..".mw."..nm
end
----------------------------------------
-- メッセージレイヤー／adv
function chgmsg_adv(flag)
	if flag == "close" then
		e:tag{"/chgmsg"}
	else
		e:tag{"chgmsg", id=(mw_getmsgid("adv"))}
		if not flag then e:tag{"rp"} end
	end
end
----------------------------------------
-- メッセージレイヤー制御
function message_control(tbl, flag)
	estag("init")

	-- 本文 / メイン言語
	local id = mw_getmsgid("adv")
	local ln = get_language(true)
	tag{"chgmsg", id=(id)}
	mw_areadfastcheck()
	mw_textloop{ text=(tbl), lang=(ln) }
	if flag then
		flip()
		estag{"eqwait"}
	end

	-- 縦サイズを返す
	local sb = get_sub_lang()
	local r  = nil
	if init.game_sublangview == "on" and sb and tbl[sb] then
		e:tag{"var", system="get_message_layer_height", name="t.tmp.h"}
		r = e:var("t.tmp.h")
	end
	estag{"/chgmsg"}

	-- 本文 / サブ言語
	if r then
		local id = mw_getmsgid("sub")
		estag{"chgmsg", id=(id)}
		estag{"mw_areadfastcheck"}
		estag{"mw_textloop", { text=(tbl), lang=(sb) }}
		if flag then
			estag{"flip"}
			estag{"eqwait"}
		end
		estag{"/chgmsg"}
		estag{"lyprop", id=(id), top=(r)}
	end
	estag()
	return r
end
----------------------------------------
-- 本文解析
function message_adv(tbl, mode, ln)
	message("通知", "古い描画ルーチン")
end
----------------------------------------
-- 本文表示
function mw_textloop(p, flag)
	local v = getTextBlockFloat(p.text)
	if v then
		----------------------------------------
		-- 既読判定
		local m  = getGameMode()
		local ma = conf.mw_aread or 0
		local ar = getAread()
		local cx = nil
		if not flg.ui and ar and ma == 1 and flag ~= "line" then
			cx = getNovelData() and init.novelaread_color	-- novel
--			or flag == "line" and	init.line_aread_color	-- line
			or						init.textaread_color	-- mw text
		end
		if cx then tag{"font", color=("0"..cx)}
		elseif m == "adv" and scr.mwcolor then tag(scr.mwcolor) cx = true end

		----------------------------------------
		-- テキスト描画
		for i, t in ipairs(v) do
			if type(t) == "table" then
				local s = t[1]
				if mode == "sys" and s == "txkey" then
				elseif tags[s] then tags[s](e, t) else e:tag(t) end		-- [ruby][rt]等の実行
			else
				e:tag{"print", data=(t)}
			end
		end
		if cx then tag{"/font"} end
--	else
--		error_message("テキストが見つかりませんでした")
	end
end
----------------------------------------
-- astからtextのみを抽出する
function get_scriptText(block, file)
	local r = ""
	local v = ast.text[block]
	local l = get_language(true)
	if l and v then v = v[l] end
	if v then
		for i, t in ipairs(v) do
			for j, tx in ipairs(t) do
				if type(tx) == "string" then r = r..tx end
			end
		end
	end	
	return r
end
----------------------------------------
-- text再描画
function mw_redraw(flag)
	local ar = getAread()

	-- 読み込み
	local bl = scr.ip.block
	local t  = getTextBlock(bl)
	local v  = getNovelData()

	-- novel
	if v then
		local mx = v.no
		local bf = {}
		local bx = bl
		estag("init")
		if mx > 0 then
			-- バッファ
			for i=1, mx do
				bx = ast[bx].linkback
				table.insert(bf, bx)
			end

			-- 再描画
			estag{"set_message_speed_tween", 0}		-- 瞬間表示に切り替え
			for i=#bf, 1, -1 do
				local z  = getTextBlock(bf[i])
				estag{"mw_redrawtext", z}
				if not z.join then estag{"rt2"} end
			end
			estag{"set_message_speed"}				-- MW速度を戻す
		end
		estag{"mw_redrawtext", t}					-- 現在の行は普通に表示
		estag()

	-- 選択肢
	elseif scr.select then
		select_message()
		flip()

	-- normal
	elseif not t.linemode then
		-- float
		if smex then smex.redraw() end

		-- main
		local v = getTextBlockFloat(t)
		if v then
			-- 名前
			if v then mw_name(t) end

			-- 本文
			message_control(t, not flag)
		end
	end
end
----------------------------------------
function mw_redrawtext(p) message_control(p, true) end
----------------------------------------
-- 既読テキスト瞬間表示
function mw_areadfastcheck()
	-- autoplay実行時は処理しない
	if init.game_areadfast == "on" and not flg.autoplay then
		if conf.aread_fast == 1 and scr.areadflag then
			set_message_speed_tween(0)
		else
			set_message_speed_tween(getMSpeed())
		end
	end
end
----------------------------------------
-- 取得
----------------------------------------
-- 名前ベース取得
function getNameChar(p, flag)
	local ln = get_language(true)
	local r  = nil
	local z  = p and p[ln] and p[ln][1] and p[ln][1].name
	if z then
		r = flag and (z[2] or z[1])
	end

	-- 名前置換
	if r and init.game_heroname == "on" then
		local df = lang.uihelp.system or {}
		r = r:gsub("{fn}", gscr.firstname or df.firstname)
		r = r:gsub("{ln}", gscr.lastname  or df.lastname)
	end
	return r
end
----------------------------------------
-- 名前取得 / 多言語 / サブ
function getNameSubtext(p)
	local v = p.name
	local r = nil
	if v then
		local ln = get_sub_lang()
		r = v[ln]
	end
	return r
end
----------------------------------------
-- noもしくは現在のtext blockを取得
function getTextBlock(name)
	local r  = nil
	local lb = ast.label or {}
	local bl = name or scr.ip.block or lb.top.block
	if ast[bl] then
		r = ast[bl].text or {}
	else
		tag_dialog({ title="エラー", message=("データが読み込めませんでした") }, "stop")
	end
	return r
end
----------------------------------------
-- テキストのみを返す
function getTextBlockText(no)
	local r = getTextBlock(no)
	return getTextBlockTextRead(r)
end
----------------------------------------
-- テキストのみを返す
function getTextBlockTextRead(r)
	if r then
		-- lang
		local l = { text=1 }
		local s = init.lang
		if s then
			for k, v in pairs(s) do
				l[k] = 1
			end
		end

		-- 抽出
		local z = {}
		for nm, v in pairs(r) do
			if nm == "vo" then
				z.vo = v

			-- 名前はそのままコピー
			elseif nm == "name" then
				z.name = v

			-- 選択肢
			elseif nm == "select" then
				z.select = v

			-- text
			elseif l[nm] then
				local s = ""
				for i, v2 in pairs(v) do
					for i2, tx in pairs(v2) do
						if type(tx) == 'string' then
							s = s..tx
						elseif i2 == "name" then
							z.name = tx
						end
					end
				end
				z[nm] = s
			end
		end
		r = z
	end
	return r
end
----------------------------------------
-- textblockを返す / float判定付き
function getTextBlockFloat(p, mode)
	local r  = nil
	local z  = p.float or {}
	local ln = get_language(true)
	for i, v in ipairs(p[ln] or p.ja) do
		if not mode and not z[i] or z[i] and z[i].mode == mode then
			r = v
			break
		end
	end
	return r
end
----------------------------------------
-- その他制御
----------------------------------------
-- クリック消去
function adv_clsclick()
	----------------------------------------
	-- novel mode
	local s = getNovelData()
	if s then
		local v = getTextBlock()

		-- novel行加算
		scr.novel.no = s.no + 1

		-- 改頁
		if v.pagebreak then
			scr.novel.no = 0
			tag{"rp"}		-- 消去

		-- join
		elseif v.join then

		-- 改行
		else
			rt2()			-- 改行
		end

	----------------------------------------
	-- txnc
	elseif scr.txnc then
		scr.txnc = nil

	----------------------------------------
	-- normal mode
	else
		adv_cls4()
	end
end
----------------------------------------
-- 名前／本文消去
function adv_cls4(flag)
	chgmsg_adv("close")

	-- テキストのみ消す
	if flag then
		tag{"chgmsg", id=(mw_getmsgid("name"))}
		tag{"rp"}
		tag{"/chgmsg"}

	-- ADV全消去
	else
		message_name()
		scr.mwcolor = nil		-- text color
	end
	chgmsg_adv()	-- advに変更
	tag{"rp"}		-- 本文消去

	-- sub text
	if init.game_sublangview == "on" then
		local id = mw_getmsgid("sub")
		tag{"chgmsg", id=(id)}
		tag{"rp"}
		tag{"/chgmsg"}
	end

	-- float
	if smex then smex.sm_cls4() end
end
----------------------------------------
-- text tag
----------------------------------------
-- 主人公名前 / 本文
function heroname(p, flag)
	local nm = nil
	local md = p.mode
	local z  = init.game_heroname == "on"
	if z and md then
		local hd = ex[md]
		local df = lang.uihelp.system[hd]
		nm = gscr[hd] or df
		if nm and not flag then tag{"print", data=(nm)} end
	end
	return nm
end
----------------------------------------
-- 改行
function rt2()
	tag{"rt", omitblankline="1"}
end
----------------------------------------
-- ノベル改行
function nrt()
	if not flg.ui and scr.novel then
		tag{"rt", omitblankline="1"}
		tag{"rt"}
	end
end
----------------------------------------
-- クリックで文字を消さない
function txnc()
	if not flg.ui then scr.txnc = true end
end
----------------------------------------
-- 次のブロックへ
function txnb()
--	if not flg.ui then scr.txnb = true end
end
----------------------------------------
-- キー待ち
function txkey()
	if not flg.ui then
		flg.txclick = true
		estag("init")
		estag{"eqwait", { scenario="1" }}
		estag{"txkey_click"}
		estag{"txkey_exit"}
		estag()
	end
end
----------------------------------------
function txkey_click()
	tag{"@"}
end
----------------------------------------
function txkey_exit()
	ResetStack()
	flg.txclick = nil
	mw_text()
end
----------------------------------------
-- 外字
function gaiji(p)
	local tx = p.text
	local s  = init.gaijisize
	if init.gaiji and s then
		local fo = conf.font or 1
		local no = p.size or 3
		local sz = s[no]

		-- font
		local ft = {"font", face=(get_fontface("gaiji")), size=(sz)}

		-- 影と縁を削除
		local z  = init.emojicheck
		if z then
			for i, tz in ipairs(z) do
				if tx == tz then
					ft["shadow"]  = "0"
					ft["outline"] = "0"
					break
				end
			end
		end

		-- メッセージレイヤーから処理を割り振り
		local id = e:var("s.current_message_layer")
		local r  = {}
		tag{"var", name="t.ly", system="delete"}
		tag{"var", name="t.ly", system="get_message_tags", id=(id), allfont="1"}
		for i=0, 20 do
			local a = e:var("t.ly."..i)
			if a == "0" then break
			elseif a:sub(1, 5) == "font," then
				local ax = explode(",", a)
				for i=2, #ax, 2 do r[ax[i]] = ax[i+1] end	-- もとの[font]をコピー
			end
		end

		-- spacebottomによる調整
		local h  = r.size - sz
		local a  = explode("%.", id)
		local hd = a[3] or "mw"
		if hd == "mw" or hd == "sm" then
			local s = "gaijifont_adv"..string.format("%02d", fo)
			local z = init[s]
			if z and z[no] then h = h + z[no] end
		else
			local z = init["gaijifont_"..hd]
			if z then h = h + z end
		end
		ft.spacebottom = r.spacebottom + h

		-- 表示
		tag(ft)
		tag{"print", data=(tx)}
		tag{"/font"}
	else
		tag{"print", data=(tx)}
	end
end
----------------------------------------
-- text image
function tximg(p)
	local z  = csv.mw.mwimg
	local fl = p.file
	if not fl or not z then return end

	local px = get_uipath()..(z.file or "mw/img/")..fl

	-- blog
	local nm = btn.name
	if nm == "blog" then
		local id = flg.tximgid
		if id then
			local b = lang.font.backlog
			local x = b.left
			local y = b.top
			lyc2{ id=(id), file=(px), x=(x), y=(y)}
		end

	-- mw
	else
		local id = getMWID("mwimg")
		local x  = z.x + (p.x or 0)
		local y  = z.y + (p.y or 0)
		lyc2{ id=(id), file=(px), x=(x), y=(y)}
	end
end
----------------------------------------
-- font
function exfont(p)
	local st = p.style
	local sz = p.size
	local co = p.color
	local it = init.italic or {}	-- italic
	local fo = init[it[1]]			-- italic font

	-- 閉じる
	if not sz and not co and not st then
		tag{"/font"}
		scr.fsize = getFontSize()

	-- italic
	elseif fo and st == "italic" then
		local z = {"font", face=(string.lower(fo))}
		if #it > 1 then
			for i=2, #it do
				local a = explode(":", it[i])
				if a[1] == "size" then
					z.size = getFontSize() + a[2]
				else
					z[a[1]] = a[2]
				end
			end
		end
		tag(z)

	-- style
	elseif st then
		tag{"font", style=(st)}

	-- size / color
	else
		local n = tn(sz)
		local s = sz and sz:sub(1, 1) == 'f' and tn(sz:sub(2))

		-- 短縮表記を計算
		if s then
			sz = math.floor(getFontSize() * init.fontsize[s] / 100)

		-- 画面サイズ倍率を掛ける
		elseif n then
			local z = game.scale or 1
			if z ~= 1 then sz = math.floor(n * z) end
		end
		tag{"font", size=(sz), color=(co)}
		if sz then scr.fsize = sz end
	end
end
----------------------------------------
--
----------------------------------------
-- font size取得
function getFontSize(name)
	local tbl= { blog="backlog" }
	local bt = btn and btn.name
	local nm = name or bt and tbl[bt] or 'adv01'
	local z  = lang and lang.font or {}

	-- mode check
	if nm:find("^[a-z]+[0-9][0-9]$") then
		local hd = nm:gsub("([a-z]+).*", "%1")
		local mw = scr.mwno or 1	-- mw no
		local ls = "fontlist_"..hd..string.format("_%02d", mw)
		local t  = init[ls]
		if init["game_font"..hd] == "list" and t then
			local cf = conf.font or 1	-- font config
			nm = t[cf] or nm
		end
	end

	-- advならMW判定
	if nm == "adv" and not z[nm] then
		local no = scr and scr.mwno or 1
		nm = nm..string.format("%02d", no)
	end

	-- sizeを取り出す
	local ln = get_language(true)
	local v  = z[nm] or {}
	local sz = conf.fontsize or v[ln] and v[ln].size or v.size or 20
	return sz
end
----------------------------------------
-- floatと本文の切り分け
function getFloatFlag()
	local r = nil
	if smex then
		local bl = scr.ip.block
		local p  = ast[bl].text
		if p and p.float and p.float[1] then r = true end
	end
	return r
end
----------------------------------------
