----------------------------------------
-- おまけ／シーン
----------------------------------------
-- シーン初期化
function exf.scinit()

	if not appex.scen then appex.scen = {} end

	-- シーン取得
	local stm = 0
	local stc = 0
	for set, v in pairs(csv.extra_scene) do
		local p = v[1]
		local n = v[2]
		local m = table.maxn(v) - 2

		-- 保存
		local fl = v[3]
		local fx = gscr.scene[set]
		if not appex.scen[p]	then appex.scen[p] = {} end
		if not appex.scen[p][n] then appex.scen[p][n] = { file=(fl), label=(v[4]), thumb=(v[5]), flag=(fx) } end
		if fx then stc = stc + 1 end
		stm = stm + 1
	end

	-- パーセント
--	local px = stc == stm and 100 or percent(stc, stm)
--	exf.percent("500.nm", px, "num01")

	-- 各ページのボタン数
	local mx = appex.scen.pagemax
	for i, v in ipairs(appex.scen) do
		appex.scen[i].bmax = #v
		appex.scen[i].pmax = math.ceil(#v / mx)
	end
end
----------------------------------------
-- ページ生成
function exf.scpage()
	local p, page, char = exf.getTable()
	local px = p.p

	-- thumb / mask
	local mspx = get_uipath()..'extra/'
	local none = isFile(mspx.."nonescen.png") and mspx.."nonescen" or isFile(mspx.."none.png") and mspx.."none"
	local mask = isFile(mspx.."maskscen.png") and mspx.."maskscen" or isFile(mspx.."mask.png") and mspx.."mask"
	local thid = px.p1 or 5		-- thumb id

	-- ページ本体
	local max = px.pagemax
	if max then
		-- page
		local hd = p.head or 0
		local s  = appex.scen.slider
		if s and s.no then hd = s.no * s.w end

		-- loop
		for i=1, max do
			local mv = px[char][hd + i]
			local nm = "cg"..string.format("%02d", i)
			local id = getBtnID(nm)

			-- ボタン
			if not mv then
				tag{"lyprop", id=(id), visible="0"}
				setBtnStat(nm, 'c')
			else
				tag{"lyprop", id=(id), visible="1"}
				local idt = id.."."..thid
				if mv.flag then 
					lyc2{ id=(idt), file=(":thumb/"..mv.thumb), x=(px.tx), y=(px.ty), mask=(mask)}
					setBtnStat(nm, nil)
				elseif none then
					lyc2{ id=(idt), file=(none), x=(px.tx), y=(px.ty), mask=(mask)}
					setBtnStat(nm, nil)
				else
					lydel2(idt)
					setBtnStat(nm, 'c')
				end
			end
		end

		----------------------------------------
		-- ボタン切り替え
		local md = appex.scen.md or "none"

		-- ページ番号切り替え
		if md:find("page") then
--			exf.pageno("no01", page)
--			exf.pageno("no02", px[char].pmax)
			for i=1, px[char].pmax do
				local nm = "page"..string.format("%02d", i)
				local c  = i == page and 'c'
				setBtnStat(nm, c)
			end
		end

		-- キャラ切り替え
		if md:find("char") then
			for i=1, #px do
				local nm = "char"..string.format("%02d", i)
				local c  = i == char and 'c'
				setBtnStat(nm, c)
			end
		end

		-- slider pos
		if md == "slider" then
			exf.sliderpos()
		end
	end
end
----------------------------------------
--
----------------------------------------
-- 呼び出し
function exf.sceneview(no)
	local p, page, char = exf.getTable()
	local z = appex.scen.pagemax
	local n = (page-1) * z + no + exf.getSliderPosition()
	local v = p.p[char][n]
	if v.flag then
		local file = v.file

		message("通知", file, ":", v.label, "を呼び出します")

		-- 動画再生
		if file == "movie" then
			exf.movieplay(v.label)

		-- シーン再生
		else
			-- 再生中のbgmを保存しておく
			local b = getplaybgmfile()
			appex.playbgm = b

			-- シーンを閉じる
			e:tag{"lydel", id="400"}
			e:tag{"lydel", id="500"}
			e:tag{"lydel", id="600"}
--			extra_scene_reset()

			flg.scene = v
			e:tag{"jump", file="system/ui.asb", label="exscene_jump"}
		end
	end
end
----------------------------------------
-- 実行
function extra_scene_jump2()
	ResetStack()		-- スタックリセット
	local v = flg.scene

	-- 念のためリセット
	reset_backlog()
	key_reset()
	adv_flagreset()

	-- 呼び出し
	ast = nil
	scr.ip = nil
	readScriptStart(v.file, v.label)
end
----------------------------------------
-- シーン選択再表示
function extra_goscene()

	-- bgm再生
	local fl = getplaybgmfile(appex.playbgm)
	if fl then
		bgm_play{ file=(fl), sys=true }
		appex.playbgm = nil
	else
		title_bgm()
	end
	scr.ip = nil

	-- scene
	extra_init("scen", true)
	uitrans()
end
----------------------------------------
-- 
----------------------------------------
-- シーンから戻る
function extra_scene_return()
	e:tag{"jump", file="system/ui.asb", label="exscene_jump_return"}
end
----------------------------------------
function extra_goscene_exit()
	-- シーンに戻る
	flg.title = { page=true }
	flg.ui = {}
--	e:tag{"return"}
	if scr.eventflag or sys.extra and sys.extra.event then
		exev.delete()
		exev_init()
	else
		extra_scene_init()
	end
	stop2()
end
----------------------------------------
