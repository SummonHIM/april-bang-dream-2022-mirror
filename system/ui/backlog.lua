----------------------------------------
-- ■ バックログ
----------------------------------------
-- バックログバッファをリセット
function reset_backlog()
	log = {			-- log data
		p = 1,
		count = 1,
		stack = {}
	}
	flg.blog = nil	-- blog work
	scr.blj  = {}	-- quickjump
	backlog_mode(1, "init")
end
----------------------------------------
-- 初期化
function blog_init()
	message("通知", "バックログを開きました")
--	se_ok()
--	sysvo("open_blog")
--	voice_stopallex(0)		-- 一旦全停止
	backlog_mode(1, "init")	-- テキスト消去

	-- バッファの初期化
	local pgmx = init.backlog_page
	local max  = table.maxn(log.stack)
	local max2 = max < pgmx and max or pgmx
	local file = scr.ip.file
	flg.blog = { max=(max), pgmx=(max2), file=(file), cache={} }

	-- ページ算出
	local page = max - pgmx
	if page < 1 then page = 1 end
	flg.blog.page = 0

	-- ダミー作成
	sys.blog = { buff = 100 }

	-- text cache
	blog_cache()

	-- uiの初期化
	csvbtn3("blog", "500", lang.ui_backlog)
	local page = init.backlog_page
	if max <= page then
		-- slider
		e:tag{"lyprop", id="500.z.sl", visible="0"}
--		local v = getBtnInfo("slbg")
--		e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)}

		-- 未使用ボタン
		for i=max+1, page do
			e:tag{"lyprop", id=("500.z.bt."..i), visible="0"}
			e:tag{"lyprop", id=("500.z.bx."..i), visible="0"}
		end
	else
		flg.blog.page   = max - page
		flg.blog.slider = true
	end

	-- drag
	local id = "500.0"
	local wd = game.width
	local he = game.height
	lyc2{ id=(id..".drag"), width=(wd), height=(he), color="00000000", draggable="1", dragarea="0,-720,0,720"}
	lyevent{ id=(id..".drag"), dragin="blog_draginit", drag="blog_drag", dragout="blog_dragout"}

	view_backlog()			-- 最新データを読み込み

	-- 表示
	uiopenanime("blog")
end
----------------------------------------
-- 状態クリア
function blog_reset()
--	voice_stopallex() 		-- 音声全停止
	backlog_mode(1, true)	-- テキスト消去
	delbtn('blog')			-- 削除
	sys.blog = nil			-- ダミークリア
	flg.blog = nil			-- バッファクリア
end
----------------------------------------
-- バックログを抜ける
function blog_close()
	message("通知", "バックログを閉じました")
--	se_cancel()

--	if flg.blog.file ~= scr.ip.file then readScriptFile(scr.ip.file) end
	local s = flg.blog.file
	if s then readScriptFile(s, true) end

	-- 消去アニメ
	backlog_mode(1, true)	-- テキスト消去
	uicloseanime("blog")
end
----------------------------------------
-- active
function log_active()
	if game.os ~= "android" then
		btn_active("btn0"..flg.blog.pgmx)
	end
end
----------------------------------------
-- 
----------------------------------------
-- cache
function blog_cache()
	local file = nil
	local p  = log.stack
	local m  = #p
	local ln = get_language(true)	-- 多言語 / メイン
	local sb = get_sub_lang()		-- 多言語 / サブ
	local ff = init.game_backlogface == "on"	-- backlogに顔絵を表示する
	local fv = init.game_favovoice == "on"		-- お気に入りボイスを使用する
	local ws = checkWasmsync()					-- wasmsync
	local wf = scr.ip.file
	if init.game_sublangblog ~= "on" or sb == 0 then sb = nil end
	for i=1, m do
		local v = log.stack[i]
		local t = { text={}, sub={}, voice={}, face={} }

		-- text
		if v then
			----------------------------------------
			-- script read
			if file ~= v.file then
				file = v.file
				readScriptFile(file, true)
			end
			local bl = v.block

			----------------------------------------
			-- cacheに格納
			if v.select then
				-- 選択肢
				local l = get_langsystem("select") or "選択肢"
				local x = v.select
				local z = ast[bl].select or {}
				if z and z[ln] and z[ln][x] then
					t.name = l
					t.text = {{ z[ln][x] }}		-- 決定済み
				elseif x == -1 then
					t.name = l
					t.text = {{ l }}			-- 決定前
				end
			else
				-- テキスト取得
				local zv = getTextBlock(bl)
				if fv then t.blog = getTextBlockTextRead(zv) end		-- お気に入りボイス用

				local wa = ws and wf ~= v.file and true					-- wasmsyncは非表示
				t.wasm = wa
				t.lock = v.lock		-- quickjump lock

				----------------
				-- face
				local lf = nil
				if not wa and ff and v.face then
					t.face = tcopy(v.face)
					if fv then t.blog.face = v.face end
					lf = true	-- line face flag
				end

				----------------
				-- voice
				if not wa and zv.vo then
					for i, z in pairs(zv.vo) do
						table.insert(t.voice, z)
					end
				end

				----------------
				-- 名前
				t.name = getNameChar(zv, true)

				----------------
				-- 本文
				if zv[ln] then
					t.text = blog_cachetext(t.text, zv[ln], zv)
				end

				----------------
				-- 本文 / サブ言語
				if sb and zv[sb] then
					t.sub = blog_cachetext(t.sub, zv[sb], zv)
				end

				----------------
				-- 本文 / sm
				if smex and not zv.linemode then
					if not t.sm then t.sm = {} end
					t.sm = blog_cachetext(t.sm, zv[ln], zv, "sm")
				end

				----------------
				-- line stamp
				local lm = zv.linemode
				if type(lm) == "table" then
					if lm.stamp then t.line = tcopy(lm) end
					t.lineface = true			-- face非表示フラグ
				end
			end
			flg.blog.cache[i] = t
		end
	end
end
----------------------------------------
-- 格納
function blog_cachetext(r, t, z, mode)
	local ft = z.float or {}	-- float data

	-- lineは最新のもののみ
	if type(z.linemode) == "table" then
		local mx = #t
		table.insert(r, t[mx])

	-- float / sm
	elseif mode then
		for i, v in ipairs(t) do
			if ft[i] and ft[i].mode:sub(1, 5) == "float" then
				table.insert(r, v)
			end
		end

	-- main
	else
		for i, v in ipairs(t) do
			if not ft[i] then
				table.insert(r, v)
			end
		end
	end
	return r
end
----------------------------------------
-- ■ バックログ / 表示
----------------------------------------
function view_backlog()
	local bx   = flg.blog
	local max  = bx.max
	local page = bx.page
	local pg   = init.backlog_page
	local nx   = init.mwnameframe
	local nf   = lang.font.logname
	local st   = csv.mw.blogstamp
	local ngtag= { txkey=1 }
	local win  = game.os == "windows"

	backlog_mode(1, true)	-- 消去

	----------------------------------------
	-- 本文表示
	local textloop = function(tbl)
		for i, tx in ipairs(tbl) do
			for j, t2 in ipairs(tx) do
				local tp = type(t2)
				if tp == "string" then
					tag{"print", data=(t2)}
				elseif tp == "table" then
					local nm = t2[1]
					if not ngtag[nm] then
						if tags[nm] then tags[nm](e, t2) else e:tag(t2) end
					end
				end
			end
		end
	end

	----------------------------------------
	-- 各ページをループで回す
	local file = scr.ip.file
	local mask = get_uipath()..'blog/maskblog'
	for i=1, pg do
		local no = page + i
		local t  = bx.cache[no]		-- cacheから読み出す
		local id = "500.z.bt.tx."..i

		----------------------------------------
		-- 表示
		if t then

			----------------------------------------
			-- 名前
			local bn = "name0"..i
			local nm = t.name
			if nm then
				if nx and type(nx) == 'table' then nm = nx[1]..nm..nx[2] end

				-- 名前の長さ確認
				tag{"chgmsg", id=(id..".0"), layered=(1)}
				local nw = init.lognameimage
				if nw and _G[nw] then _G[nw]("name0"..i, nm) end
				tag{"print", data=(nm)}
				tag{"/chgmsg"}
				if checkBtnExist(bn) then tag{"lyprop", id=(getBtnID(bn)), visible="1"} end
			else
				if checkBtnExist(bn) then tag{"lyprop", id=(getBtnID(bn)), visible="0"} end
			end

			-- 本文
			flg.tximgid = id..".1"
			e:tag{"chgmsg", id=(id..".1"), layered=(1)}
			textloop(t.text)
			if smex and t.sm then smex.blogtext(t.sm) end			-- sm
			if t.sub then
				e:tag{"var", system="get_message_layer_height", name="t.tmp.h"}
				local y = e:var("t.tmp.h")
				e:tag{"/chgmsg"}

				-- sub text
				local ix = id..".2"
				e:tag{"chgmsg", id=(ix), layered=(1)}
				textloop(t.sub)
				e:tag{"lyprop", id=(ix), top=(y)}
			end
			e:tag{"/chgmsg"}
			flg.tximgid = nil

			-- 本文／active
--			e:tag{"chgmsg", id=(id..".3"), layered=(1)}
--			textloop(t.text)
--			e:tag{"/chgmsg"}

			-- line
			local is = id..".-1"
			if st and t.line then
				local z = nil
				local y = 0
				local h = mulpos(t.line.h)
				if st.h < h then
					z = percent(st.h, h)			-- zoom計算
				elseif st.h > h then
					y = math.floor((st.h - h) / 2)	-- 中央寄せ
				end
				lyc2{ id=(is), file=(t.line.stamp), x=(st.x), y=(st.y + y), zoom=(z), anchorx="0", anchory="0" }
			else
				lydel2(is)
			end

			-- 座標
			local b = getBtnInfo("btn0"..i)
			e:tag{"lyprop", id=(id), top=(b.y)}

			-- 当たり判定
			if win and b.flag and tn(b.flag) < 0 then
				tag{"lyprop", id=(b.idx..'.0'), clickablethreshold="255"}
			end

			-- face
			local v = t.face
			if v and v.file and not t.lineface then
				local c = checkBtnExist(b.p3) and getBtnInfo(b.p3) or b		-- btbgをp3に割り当ててあればそちらから読み出す
				setMWFaceFile(v, "blogface", id..".7.0")
				tag{"lyprop", id=(id..".7"), left=(c.x), top=(c.y - b.y), intermediate_render="1", intermediate_render_mask=(mask)}
--				tag{"lyprop", id=(id..".7"), grayscale="1", colormultiply="88fff0"}
			end
		end

		----------------------------------------
		-- voice / favo
		local vo = t and t.voice or {}
		local vn = "voice"..i
		local fn = "favo"..i
		local vs = #vo == 0 and "c" or nil
		if checkBtnExist(vn) then setBtnStat(vn, vs) end
		if checkBtnExist(fn) then setBtnStat(fn, vs) end

		-- jump
		local jn = "jump0"..i
		local vs = (t and t.lock or no >= #bx.cache) and "c"
		if checkBtnExist(jn) then setBtnStat(jn, vs) end
	end
end
----------------------------------------
-- 消去とレイヤーモード変更
function backlog_mode(mode, del)
	local sub = init.game_sublangblog == "on"

	-- 各ページをループで回す
	for i=1, init.backlog_page do
		-- 名前
		local id = "500.z.bt.tx."..i..".0"
		if del == 'init' then set_textfont("logname", (id), true) end
		e:tag{"chgmsg", id=(id), layered=(mode)}
		if del then e:tag{"rp"} end
		e:tag{"/chgmsg"}

		-- 本文
		local id = "500.z.bt.tx."..i..".1"
		if del == 'init' then set_textfont("backlog", (id), true) end
		e:tag{"chgmsg", id=(id), layered=(mode)}
		if del then e:tag{"rp"} end
		e:tag{"/chgmsg"}
		e:tag{"lyprop", id=(id), alpha="255"}

		-- 本文／サブ
		if sub then
			local id = "500.z.bt.tx."..i..".2"
			if del == 'init' then set_textfont("blogsub", (id), true) end
			e:tag{"chgmsg", id=(id), layered=(mode)}
			if del then e:tag{"rp"} end
			e:tag{"/chgmsg"}
			e:tag{"lyprop", id=(id), alpha="255"}
		end

		-- 本文／アクティブ色
--		local id = "500.z.bt.tx."..i..".3"
--		if del == 'init' then set_textfont("backlog_a", (id)) end
--		e:tag{"chgmsg", id=(id), layered=(mode)}
--		if del then e:tag{"rp"} end
--		e:tag{"/chgmsg"}
--		e:tag{"lyprop", id=(id), alpha="0"}
	end

	-- delete
	if del then
		e:tag{"lydel", id="500.z.bt.tx"}
	end
end
----------------------------------------
-- drag
----------------------------------------
-- 
function blog_draginit(e, p)
	local bx = flg.blog
	local mx = bx.max - bx.pgmx
	if mx > 0 then
		local bt = btn.cursor
		if not bt and not flg.dlg then flg.blog.drag = 0 end
	end
end
----------------------------------------
-- 
function blog_drag(e, p)
	local bx = flg.blog
	local r  = true
	local tm = bx.dragtime
	if not tm or e:now() > tm + 120 then
		flg.blog.dragtime = e:now()
	else
		r = nil
	end

	local dr = bx.drag
	if r and dr then
		e:tag{"var", name="t.ly", system="get_layer_info", id="500.0.drag"}
		local dy = tn(e:var("t.ly.top"))
		local y  = math.floor((dr - dy) / 70) + 1
		if dr ~= dy then
			log_addpage(y)
		end
	end
end
----------------------------------------
-- 
function blog_dragout(e, p)
	local id = "500.0"
	tag{"lyprop", id=(id..".drag"), top="0"}
	flip()
	flg.blog.drag = nil
	flg.blog.dragtime = nil
end
----------------------------------------
-- バックログボタンまわり
----------------------------------------
-- クリックされた
function log_click(e, p)
	local nm = p.bt or p.btn or p.key
	local v  = getBtnInfo(nm) or {}
	local p1 = v.p1
	local p2 = v.p2

	local sw = {

		----------------------------------------
		-- scroll
		scroll = function()
			if nm ~= "HUP" and nm ~= "HDW" then se_ok() end
			local add = tn(p2)
			if add then log_addpage(add, nm) end
		end,

		----------------------------------------
		-- cursor
		cursor = function()
			se_active()
			log_addcursor(p2)
		end,

		----------------------------------------
		-- voice
		voice = function()
			local no = flg.blog.page + p2

			-- 音声再生
			local tbl = flg.blog.cache[no].voice
			if tbl then sesys_voreplay(tbl) end
		end,

		----------------------------------------
		-- お気に入り
		favo = function()
			local no = flg.blog.page + p2
			local v  = flg.blog.cache[no]
			local vo = v.voice or {}
			if v and vo[1] then
				se_ok()
				flg.favo = v.blog
				open_ui('favo')
			end
		end,

		----------------------------------------
		-- sback
		jump = function()
			local no = flg.blog.page + p2
			local mx = #log.stack
			if no < mx then goBacklogJump(no) end
		end,

		----------------------------------------
		-- system
		title = function() adv_title() end,
		exit  = function() adv_exit()  end,
	}
	if sw[p1] then sw[p1]() end
end
----------------------------------------
-- カーソル移動
function log_addcursor(add)
	local bx = flg.blog
	local mx = bx.pgmx

	-- 移動
	local ct = bx.cursor
	if not ct then
		ct = add == -1 and 1 or mx
	else
		ct = ct + add
		if ct > mx then
			log_addpage(1, "DW")
			ct = mx
		elseif ct < 1 then
			log_addpage(-1, "UP")
			ct = 1
		end
	end
	flg.blog.cursor = ct
	local nm = "btn0"..ct
	btn_active2(nm)
	flip()
end
----------------------------------------
-- ページ移動
function log_addpage(add, nm)
	local bx = flg.blog
	local mx = bx.max - bx.pgmx
	local pg = bx.page
	if mx > 0 then
		local p = pg + add
		if add == 1 and mx == p-1 then
			if nm == "DW" then close_ui() end	-- 抜ける
		else
			if p > mx then p = mx
			elseif p < 0 then p = 0 end
			flg.blog.page = p
			view_backlog()
			log_sliderpos()
			flip()
		end
	elseif nm == "DW" then
		close_ui()			-- 抜ける
	end
end
----------------------------------------
-- ボタンup
function log_btnup(e, p)
	local ct = flg.blog.act or flg.blog.pgmx
	if ct <= 1 then
		se_active()
		log_addpage(-1)
	else
		ct = ct - 1
		btn_out( e, { key=(btn.cursor) })
		btn_over(e, { key=("btn0"..ct) })
	end
end
----------------------------------------
-- ボタンdown
function log_btndw(e, p)
	local mx = flg.blog.max		-- 全体数
	local pm = flg.blog.pgmx	-- ボタン数
	local pg = flg.blog.page	-- ページ管理
	local ct = flg.blog.act		-- ページ内のカーソル位置
	if ct == pm then
		if ct + pg >= mx then
			close_ui()			-- 抜ける
		else
			se_active()
			log_addpage(1)		-- 加算
		end
	else
		ct = ct + 1
		btn_out( e, { key=btn.cursor })
		btn_over(e, { key=("btn0"..ct) })
	end
end
----------------------------------------
-- スライダーpos制御
function log_sliderpos()
	if flg.blog.slider then
		local max = flg.blog.max - init.backlog_page
		local y   = percent(flg.blog.page, max)

		-- btn
		local name = btn.name
		local tbl  = btn[name].p.slider
		local pos  = repercent(y, tbl.h - tbl.p2)

		-- 移動
		local id = btn[name].id..tbl.id..".10"
		e:tag{"lyprop", id=(id), top=(pos)}
	end
end
----------------------------------------
-- スライダー制御
function backlog_slider(e, p)
	local max = flg.blog.max - init.backlog_page
	local p   = tn(p.p)
	local no  = repercent(p, max)
	if no ~= flg.blog.page then
		flg.blog.page = no
		view_backlog()
		flip()
	end
end
----------------------------------------
-- 
----------------------------------------
function blog_slover(e, p)
	local v = getBtnInfo("slbg")
	e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_a)}
end
----------------------------------------
function blog_slout(e, p)
	local v = getBtnInfo("slbg")
	e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip)}
end
----------------------------------------
-- ボタン番号を保存しておく
function log_btnover(e, p)
	local bt = p.name
	if bt then
		local v = getBtnInfo(bt)
		local p2 = v.p2
		flg.blog.btnno = p2
	end
end
----------------------------------------
function log_btnout(e, p)
	local bt = p.name
	if bt then
		local v  = getBtnInfo(bt)
		local p2 = v.p2
		local no = flg.blog.btnno
		if p2 == no then
			flg.blog.btnno = nil
		end
	end
end
----------------------------------------
-- quickjump
function log_btnjump(e, p)
	local no = flg.blog.btnno
	if no then log_click(e, { bt=("jump0"..no) }) end
end
----------------------------------------
-- お気に入りボイス
function log_btnfavo(e, p)
	local no = flg.blog.btnno
	if no then log_click(e, { bt=("favo"..no) }) end
end
----------------------------------------
-- ボイス再生
function log_btnvoice(e, p)
	local no = flg.blog.btnno
	if no then log_click(e, { bt=("voice"..no) }) end
end
----------------------------------------
-- ■ バックログ記録
----------------------------------------
-- メッセージウィンドウ１画面分を書き込み終えた時の処理
function set_backlog_next()
	local qj = getQJumpStack()			-- BackLogJump管理テーブル
	local va = getEvalPoint()			-- 変数ポインタ
	local fa = getBlogFace()			-- 立ち絵表情
	local bs = getBselPoint()			-- 前の選択肢に戻るポインタ
	local nv = tcopy2(getNovelData())	-- novel mode
	local li = getLineData()			-- line mode
	local ss = tcopy2(scr.gss)			-- GameScriptStack(call)管理テーブル
	local sn = scr.ip.file				-- script name
	local sb = scr.ip.block				-- script block
	local lk = flg.autoplay				-- quickjumpボタンlock

	-- テーブルを分解して格納する(ポインタ回避)
	table.insert(log.stack, { file=(sn), block=(sb), blj=(qj), gss=(ss), eval=(va), face=(fa), bsel=(bs), novel=(nv), line=(li), lock=(lk) })

	-- 最大数を超えていたら先頭を削除
	if table.maxn(log.stack) >= init.backlog_max then
		table.remove(log.stack, 1)
	end
end
----------------------------------------
-- ■ バックログジャンプ
----------------------------------------
-- バックログジャンプ実行確認
function goBacklogJump(no)
	flg.blogno = no
	se_ok()
	dialog("jump")
end
----------------------------------------
function goBacklogJumpTo()
	local no = flg.blogno
	flg.blogno = nil
	quickjumpui(no, "blog")
end
----------------------------------------
