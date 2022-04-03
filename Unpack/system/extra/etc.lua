----------------------------------------
-- おまけ／動画
----------------------------------------
-- 動画初期化
function exf.mvinit()

	if not appex.movi then appex.movi = {} end
	if not appex.movi[1] then appex.movi[1] = {} end

	-- 動画取得
	local tbl = {}
	for i, v in pairs(csv.extra_movie) do
		local no = tn(v[2])
		if no and no > 0 then tbl[no] = { file=(v[4]), id=(i), no=(no), name=(v[3]) } end
	end

	-- 開放確認
	for i, v in pairs(tbl) do
		local fl = v.file
		local id = v.id
		table.insert(appex.movi[1], { file=(fl), name=(v.name), id=(id), flag=(gscr.movie[id]) })
	end
end
----------------------------------------
-- ページ生成
function exf.mvpage()
	local p, page, char = exf.getTable()
	local px = p.p

	-- thumb / mask
	local mspx = get_uipath()..'extra/'
	local none = isFile(mspx.."nonemovi.png") and mspx.."nonemovi" or isFile(mspx.."none.png") and mspx.."none"
	local mask = isFile(mspx.."maskmovi.png") and mspx.."maskmovi" or isFile(mspx.."mask.png") and mspx.."mask"
	local thid = px.p1 or 5		-- thumb id

	-- ページ本体
	if px.pagemax then
--		local mask = getBtnInfo("cg01")
		local path = game.path.ui
		for i=1, px.pagemax do
			local mv = px[char][i]
			local nm = "cg"..string.format("%02d", i)
			local id = getBtnID(nm)

			if not mv then
				tag{"lyprop", id=(id), visible="0"}
				setBtnStat(nm, 'c')
			else
				tag{"lyprop", id=(id), visible="1"}
				local idt = id.."."..thid
				if mv.flag then
					lyc2{ file=(":thumb/"..mv.file), id=(idt), x=(px.tx), y=(px.ty), mask=(mask)}
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
	end

	-- steam全年齢
	if steam and init.allages == "on" then
		tag{"lyprop", id=(getBtnID("bt_scene")), visible="0"}
		tag{"lyprop", id=(getBtnID("bt_cg"   )), left="533"}
		tag{"lyprop", id=(getBtnID("bt_movie")), left="846"}
		tag{"lyprop", id=(getBtnID("bt_bgm"  )), left="1118"}
	end
end
----------------------------------------
-- 
----------------------------------------
-- 動画再生
--[[
function exf.playmovie(no)
	-- cursor out
	local bt = btn.cursor
	if bt then
		btn_out(e, { key=(bt) })
		exf.cgcursor = bt
	end

	-- ムービー再生
	flg.btnstop = true
	local p, pg, ch = exf.getTable()
	local z = p.p[ch][no]
	if z.name == "mv" then
		local id   = z.id
		local v    = init.movie[id] or {}		-- movie設定
		local file = v.file	or id				-- 仮想ファイル
		local path = game.path.movie
		local exp  = game.movieext

		-- 停止キー
		local key = "1"
		for k, v in pairs(csv.advkey.list.MWCLICK) do
			key = key..','..k
		end
		e:tag{"keyconfig", role="0", keys=(key)}

		-- 多言語
		if v.lang then
			local ln = get_language(true)
			local s  = init.langadd[ln]
			if s then file = file..s end
		end

		-- 再生
		local time = init.normal
		allsound_stop{ time=(time) }
		lyc2{ id="600", file=(init.black)}
		estag("init")
		estag{"uitrans", time}
--		estag{"video", file=(path..file..exp), skip=(1)}
		estag{"movie_playfile", { file=(path..file..exp), skip=(1) }}
		estag{"keyconfig", role="0", keys=(getexclick())}		-- key戻し
		estag{"extra_movieend"}
		estag{"button_autoactive"}		-- windows / cursor check
		estag()
	else
		local id   = z.id
		local time = init.normal
		allsound_stop{ time=(time) }
		lyc2{ id="600", file=(init.black)}
		estag("init")
		estag{"uitrans", time}
		estag{"staffroll2", { ch=(id), extra=true }}
		estag{"extra_movieend"}
		estag{"button_autoactive"}		-- windows / cursor check
		estag()
	end
end
----------------------------------------
function extra_movieend()
	-- カーソル復帰
	local bt = exf.cgcursor
	if bt and game.cs then btn_active2(bt) end
	exf.cgcursor = nil

	-- delete
	title_bgm()
	lydel2("600")
	uitrans()
	flg.btnstop = nil
end
----------------------------------------
-- staffroll
function movie_staffroll()
	staffroll{}
end
----------------------------------------
-- staffroll exit
function movie_staffroll_exit()
	flg.btnstop = nil
	exf.bgmrestart()	-- bgm再開
	setonpush_ui()		-- 念のためキー設定
end
]]
----------------------------------------
