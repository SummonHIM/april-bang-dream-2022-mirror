----------------------------------------
-- おまけ／共通化
----------------------------------------
exf = {}
----------------------------------------
exf.table = {
	cgmd = { ui="ui_cgmode" , init="cginit", view="cgpage", vo=true, flag="ev"   , reset="cgreset" },		-- CG鑑賞
	scen = { ui="ui_scene"  , init="scinit", view="scpage", vo=true, flag="scene", reset="screset" },		-- シーン鑑賞
	bgmd = { ui="ui_bgmmode", init="bginit", view="bgpage", vo=true, flag="bgm"  , reset="bgmreset" },		-- 音楽鑑賞
	movi = { ui="ui_movie"  , init="mvinit", view="mvpage", vo=true, flag="movie", reset="mvreset" },		-- 動画鑑賞
	exfg = { ui="ui_fgmode" , init="fginit", view="fgpage", vo=true, flag="exfg"  },						-- 立ち絵鑑賞
}
----------------------------------------
function extra_cgmode()	extra_init("cgmd") end
function extra_scene()	extra_init("scen") end
function extra_bgmmd()	extra_init("bgmd") end
function extra_movie()	extra_init("movi") end
----------------------------------------
-- 呼び出し初期化
function extra_init(name, flag)
	local p = exf.table[name]
	message("通知", name, "を開きました")

--	flg.titleextra = true

	-- sysvo
	if not flag and p.vo then sysvo(name) end

--	bgm_play{ file=(init.title_bgm) }

	-- 念のため入れておく
	flg.ui = {}
	setonpush_ui()

	-- テーブルがなければ作成
	if not appex then appex = {} end
	if not appex[name] then appex[name] = {} end
	if not gscr[name] then gscr[name] = {} end
	if not sys.extr then sys.extr = { music=100, play=1, vol=(conf.bgm), buff=0 } end

	-- 開かれていたら閉じる
	local nm = appex.name
	local rs = nm and exf.table[nm].reset
	if rs and exf[rs] then exf[rs]() elseif rs and _G[rs] then _G[rs]() end
	appex.name = name
	if init.extra_pagesave == "on" then gscr.extraname = name end

	-- ボタン描画
	csvbtn3("extr", "500", lang[p.ui])
	set_uihelp("500.help", "uihelp")

	-- ページ数
	local cxt = lang[p.ui]
	if cxt[2] then
		appex[name].pagemax = cxt[2]	-- ページ内のボタン数
		appex[name].lx = cxt[3]			-- サムネイルx数
		appex[name].ly = cxt[4]			-- サムネイルy数
		appex[name].tx = cxt[5]			-- サムネイルx補正
		appex[name].ty = cxt[6]			-- サムネイルy補正
		appex[name].md = cxt[7]			-- mode option
		appex[name].p1 = cxt[8]			-- param
		appex[name].p2 = cxt[9]			-- 
		appex[name].p3 = cxt[10]		-- 
		appex[name].p4 = cxt[11]		-- 

		-- slider mode
		if cxt[7] == "slider" then
			local z = { w=cxt[3], h=cxt[4] }
			appex[name].slider = z

			-- ダミークリア
			sys.extr.buff = 0
		end
	end

	-- データを作っておく
	if p.init and exf[p.init] then exf[p.init]() end

	-- 表示
	extra_page()

	-- アニメーション
	if flag == "title" then
		uiopenanime("extra")
	else
		uitrans()
	end
end
----------------------------------------
-- ページ処理
function extra_page()
	local p, page, char = exf.getTable()
	local nm = p.name

	-- キャラボタン
--	setBtnStat("page0"..char, 'c')		-- 

	-- 各ページへ
	local s = p.t.view	-- exf.table[name].page
	if s and exf[s] then exf[s]() end
--	exf.mvpage()

	-- フラグで開放
--	local p3 = tn(get_eval("g.allclear"))
--	if p3 == 0 then setBtnStat("bt_bgm", 'd') end

	-- 保存
	if nm == "bgmd" then exf.musicpage() end
	gscr[nm][char].page = page

	-- cs btn
	local bt = btn.cursor
	if game.cs and bt then
		local md = btn.name
		local t  = btn[md]
		if t.p[bt] and not t.dis[bt] then
			btn_active2(bt)
		else
			btn.cursor = nil
		end
	end
end
----------------------------------------
-- 閉じる
function extra_exit()
	ReturnStack()	-- 空のスタックを削除
	se_cancel()

	-- 個別exitがあれば呼ぶ
	local p = exf.getTable()
	local ex = p.t and p.t.exit or p.t.reset
	if ex and exf[ex] then exf[ex]() elseif ex and _G[ex] then _G[ex]() end

	-- 削除
	appex = nil
	sys.extr = nil
	del_uihelp()				-- ui help

	-- アニメーション
	sysvo("return")
	local tm = init.ui_fade
	estag("init")
	estag{"delbtn", 'extr'}		-- 削除
	estag{"title_init"}			-- titleへ
	estag()
end
----------------------------------------
-- 
----------------------------------------
-- 変数まとめて取得
function exf.getTable()
	local name = appex.name
	local px   = appex[name]
	local char = px.char or 1
	local tbl  = exf.table[name]

	if not gscr[name][char] then gscr[name][char] = {} end
	local page = gscr[name][char].page or 1
	local head = (page - 1) * px.pagemax

	local r = {
		name = name,
		char = char,
		page = page,
		head = head,
		p    = px,
		t    = tbl,
	}
	return r, page, char
end
----------------------------------------
-- ページ番号処理
function exf.pageno(name, no)
	local v = getBtnInfo(name)
	if v.dir == "width" then
		local z = no * v.cw + v.cx
		local c = z..","..v.cy..","..v.cw..","..v.ch
		tag{"lyprop", id=(v.idx), clip=(c)}

--	dump(v)

	end
end
----------------------------------------
-- パーセント処理
function exf.percent(id, num, name, flag)
	local a = NumToGrph3(num)
	local v = getBtnInfo(name)
	local w = v.w
	local h = v.h
	local z = ",0,"..w..","..h

	-- 100
	if a[1] == 1 then tag{"lyprop", id=(id..".1"), clip=(w..z)}
	elseif flag then  tag{"lyprop", id=(id..".1"), clip=((11 * w)..z)}
	else			  tag{"lyprop", id=(id..".1"), clip=("0,"..z)} end

	-- 10 / 1
	tag{"lyprop", id=(id..".2"), clip=((a[2] * w)..z)}
	tag{"lyprop", id=(id..".3"), clip=((a[3] * w)..z)}
end
----------------------------------------
-- 
----------------------------------------
-- クリック共通
function extra_click(e, p)	 extra_clickex(btn.cursor) end
function extra_clickui(e, p) extra_clickex(p.bt) end
function extra_clickex(bt)
	if bt then
		local v = getBtnInfo(bt)
		local c = v.p1
		local n = tn(v.p2)

--		message("通知", bt.."が選択されました", c, n)

		local sw = {
			bt_exit = function() se_ok() adv_exit() end,

			extra	= function() exf.clickextra(v.p2) end,
			click	= function() exf.clickcheck(n) end,
			box		= function() exf.clickbox(n) end,
			char	= function() exf.charchange(n) end,
			page	= function() exf.pagechange(n) end,
			charadd = function() exf.addchar(n) end,
			pageadd = function() exf.addpage(n) end,
			sladd	= function() exf.extra_addslider(n) end,

			bgm		= function() exf.clickbgm(n) end,		-- bgm直接再生
			play	= function() exf.clickbgmbtn(v.p2) end,	-- bgmプレイヤーボタン
		}
		local nm = c or bt
		if sw[nm] then sw[nm](n) end

--[[
		-- cg view
		if n then extra_cg_view(n)

		-- page
		elseif c then extra_cg_pagech(c)
		elseif bt == "bt_bgm"	then extra_cg_exit(e, "extra_bgm_init")
		elseif bt == "bt_scene" then extra_cg_exit(e, "extra_scene_init")
		elseif bt == "bt_cat"   then extra_cg_exit(e, "extra_cat_init")

		elseif bt == "bt_exit" then adv_exit()
		end
]]
	end
end
----------------------------------------
-- おまけ移動
function exf.clickextra(nm)
	if exf.table[nm] then
		se_ok()
		extra_init(nm)
	end
end
----------------------------------------
-- 本体クリック
function exf.clickcheck(no)
	local p, pg, ch = exf.getTable()
	local s = (pg-1) * (p.p.pagemax or 0) + no + exf.getSliderPosition()
	if p.p[ch][s].flag then
		se_ok()
		local sw = {
			cgmd = function() exf.cgview(no) end,
			scen = function() exf.sceneview(no) end,
			movi = function() exf.playmovie(no) end,
		}
		if sw[p.name] then sw[p.name]() end
	end
end
----------------------------------------
-- キャラ変更
function exf.charchange(no)
	local p = exf.getTable()
	local nm = p.name

	-- cg/scene
	if nm == "cgmd" or nm == "scen" then
		se_ok()
		setBtnStat("page0"..p.char, nil)	-- キャラボタン有効化
		appex[p.name].char = no				-- char保存
		extra_page()
		flip()

	-- movie/box
	elseif nm == "movi" or nm == "ebox" then
		se_ok()
		if appex.cgmd then appex.cgmd.char = no	end		-- char保存
		extra_cgmode()
	end
end
----------------------------------------
-- ページ変更
function exf.pagechange(no)
	local p, pg, ch = exf.getTable()
	local nm = p.name
--	if nm == "cgmd" or nm == "scen" then
		se_ok()
		local px = p.p[ch]
		local mx = px.pmax
--		pg = pg + no
--		if pg < 1 then pg = mx elseif pg > mx then pg = 1 end
		gscr[nm][ch].page = no
		extra_page()
		flip()
--	end
end
----------------------------------------
-- キャラ変更／加算
function exf.addchar(no)
	local p, pg, ch = exf.getTable()
	local nm = p.name
	if nm == "cgmd" or nm == "scen" then
		se_ok()
		local mx = #p.p
		ch = ch + no
		if ch < 1 then ch = mx elseif ch > mx then ch = 1 end
		appex[nm].char = ch				-- char保存
		extra_page()
		flip()
	end
end
----------------------------------------
-- ページ変更／加算
function exf.addpage(no)
	local p, pg, ch = exf.getTable()
	local nm = p.name
	if nm == "cgmd" or nm == "scen" then
		se_ok()
		local px = p.p[ch]
		local mx = px.pmax
		pg = pg + no
		if pg < 1 then pg = mx elseif pg > mx then pg = 1 end
		gscr[nm][ch].page = pg
		extra_page()
		flip()
	end
end
----------------------------------------
-- slider
----------------------------------------
-- slider処理(csvから呼び出し)
function extra_slider()
	local nm = appex.name
	local s  = appex[nm].slider
	if s then
		local v, pg, ch = exf.getTable()
		local no = sys.extr.buff					-- カーソル位置(no/100)
		local px = v.p
		local bm = nm == "bgmd" and #px or px[ch].bmax
		local mx = math.ceil(bm / s.w) - s.h		-- 縦方向の数を計算(ボタン数)
		local n1 = math.ceil(mx * no / 100)			-- 計算
		appex[nm].slider.no = n1

		-- 各ページへ
		local n = v.t.view
		if s and exf[n] then exf[n]() end
	end
end
----------------------------------------
-- slider加算(ボタン処理)
function exf.extra_addslider(add)
	local p, page, char = exf.getTable()
	local nm = appex.name
	local s  = appex[nm].slider or {}
	local no = (s.no or 0) + add
	local mx = nm == "bgmd" and math.ceil(#appex[nm] / s.w) - s.h or math.ceil(#appex[nm][char] / s.w) - s.h
	if no >= 0 and no <= mx then
		local bt = btn.cursor
		appex[nm].slider.no = no

		exf.sliderpos()

		-- 各ページへ
		local nx = p.t.view
		if exf[nx] then exf[nx]() end
		if bt and game.cs then btn_active2(bt) end
		flip()
	end
end
----------------------------------------
-- slider位置調整
function exf.sliderpos()
	local nm = appex.name
	local s  = appex[nm].slider
	if s then
		local p, pg, ch = exf.getTable()
		local px = p.p
		local bm = nm == "bgmd" and #appex[nm] or px[ch].bmax
		local mx = s.mx or math.ceil(bm / s.w) - s.h	-- 縦方向の数を計算(ボタン数)
		local hd = s.no or 0
		appex[nm].slider.mx = mx

		-- 計算
		local v  = getBtnInfo("slider")
		local wh = v.h - v.p2			-- 縦座標(px)
		local n1 = percent(hd, mx)		-- page/maxから%を出す
		local n2 = repercent(n1, wh)	-- page/maxから%を出す

		-- 移動
		local id = v.idx..".10"
		tag{"lyprop", id=(id), top =(n2)}
	end
end
----------------------------------------
-- sliderボタン番号取得
function exf.getSliderMatrix(no)
	local s = appex[appex.name].slider
	if s and no then
		no = no - (s.no or 0) * s.w
	end
	return no
end
----------------------------------------
-- slider positionの取得
function exf.getSliderPosition()
	local s = appex[appex.name].slider or {}
	return s.no and s.no * s.w or 0
end
----------------------------------------
-- slider最大値取得
function exf.getSlidermax(mv, v)
	local p, page, char = exf.getTable()
	local r  = nil
	local no = tn(v.p2)
	local nm = appex.name
	local s  = appex[nm].slider or {}
	if s then
		local w  = s.w
		local pg = (s.no or 0) * w
		local bx = appex[nm].pagemax		-- ボタン数
		local mx = #appex[nm][char]			-- 全ボタン数
		if nm == "bgmd" then
--			bx = appex[nm].max				-- ボタン数
			mx = #appex[nm]					-- 全ボタン数
		end

		-- 上
		if mv == "up" and no <= w and pg + no > w then
			r = true

		-- 下
		elseif mv == "dw" then
			-- 上側
			if no > bx - w and pg <= mx - s.h then
				r = true
			end

			-- lock確認
			local dw = v.dw
			local xx = mx - (math.ceil(mx / w) * w - bx)
			if dw and btn[btn.name].dis[dw] then
				r = true

			-- ボタン位置を調整
			elseif nm ~= "bgmd" and not dw and pg + no > mx - w and no >= xx then
				btn.cursor = string.format("cg%02d", no - w)
			end
		end
	end
	return r
end
----------------------------------------
-- slider / 上移動
function extra_slider_addup(e, p)
	local bt = btn.cursor
	local t  = getBtnInfo(p.bt)
	if not bt then
		btn_up(e, t)
	else
		local v = getBtnInfo(bt)
		if exf.getSlidermax("up", v) then
			exf.extra_addslider(-1)
		else
			btn_up(e, t)
		end
	end
end
----------------------------------------
-- slider / 下移動
function extra_slider_adddw(e, p)
	local bt = btn.cursor
	local t  = getBtnInfo(p.bt)
	if not bt then
		btn_down(e, t)
	else
		local v = getBtnInfo(bt)
		if exf.getSlidermax("dw", v) then
			exf.extra_addslider(1)
		else
			btn_down(e, t)
		end
	end
end
----------------------------------------
-- movie
----------------------------------------
-- 
function exf.movieplay(file)
	local time = 1500
--	allkeyoff()

	-- 再生中のbgmを保存しておく
	local b = getplaybgmfile()
	flg.extra_playbgm = b

	bgm_stop{ time=(time) }

	-- 停止キー
	local ky = getKeyString("CANCEL")
	tag{"keyconfig", role="1", keys=(ky)}

	-- path
	local fx   = movie_getfilename(file)	-- ファイル名読み替え
	local path = game.path.movie..fx..game.movieext

	lyc2{ id="900", file=(init.black) }
	estag("init")
	estag{"uitrans", (time)}
--	estag{"video", file=(path), skip="2"}
	estag{"movie_playfile", path}
	estag{"keyconfig", role="1", keys=""}
	estag{"lydel", id="900"}
	estag{"lydel", id="600"}
	estag{"uitrans", (time)}
	estag{"extra_movieend"}
--	estag{"button_autoactive"}
	estag()
end
----------------------------------------
function extra_movieend()
	extra_cg_viewerexit()	-- cgviewを抜ける
	tag{"return"}
	tag{"return"}
	flg.keycode = nil

	-- bgm再開
	local fl = getplaybgmfile(flg.extra_playbgm)
	if fl then
		bgm_play{ file=(fl), sys=true }
		flg.extra_playbgm = nil
	else
		title_bgm()
	end
end
----------------------------------------
