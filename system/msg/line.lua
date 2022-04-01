----------------------------------------
-- LINE
----------------------------------------
local ex = {}
ex.max = 40		-- 最大管理数
----------------------------------------
-- メッセージレイヤー／テキスト描画
function mw_line(p)
	local mode = p and p.mode

	----------------------------------------
	-- quickjump用
	if mode == "del" then		scr.ip.line = nil
	elseif p[1] ~= "text" then	scr.ip.line = {} end

	-- exskip
	if flg.exskip then return end

	----------------------------------------
	-- 削除
	if mode == "del" then
		local sync = p and tn(p.sync) ~= 0
		estag("init")
		estag{"msgoff"}
		if sync then estag{"mwline_close", p}
		else		 estag{"mwline_store", p} end
		estag()

	-- テキストのみ
	elseif p[1] == "text" then
		if not ex.getdraw() then
			estag("init")
			estag{"msgon", { mode="sys" }}
			estag{"mwline_main"}
			estag()
		end

	-- [line]表示
	else
		estag("init")
		if not scr.line then
			estag{"msgoff"}
			estag{"mwline_open", p}
		end
		estag{"msgon", { mode="sys" }}
		estag()
	end
end
----------------------------------------
-- image stack
function mwline_store(p)
	image_store('mwline_close', p)
end
----------------------------------------
-- 表示
function mwline_open(p, flag)
	if not scr.line then
		-- 初期化
		scr.line = {}
		scr.line.mode  = p.mode or "line"
		scr.line.count = 1
		scr.line.buff  = {}
		scr.line.tags  = tcopy(p)

		mwline_del()

		-- 持ち主データ
		local ch = p.ch
		local zz = ex.getcsvdata(ch) or {}
		local no = zz[1] or 1
		local nx = string.format("%02d", no);
		scr.line.nx = nx	-- 枠名
		scr.line.ch = ch	-- キャラ名

		----------------------------------------
		-- 背景
		local id = ex.getid("base")
		local b1 = ex.getcsvdata("bg")		-- 背景
		local b2 = ex.getcsvdata("front")	-- 飾り
		local ms = ex.getcsvdata("mask")	-- mask
		if b1 then lyc2{ id=(id.."."..b1[1]), file=(":line/"..b1[2]..nx), x=(b1[3]), y=(b1[4])} end
		if b2 then lyc2{ id=(id.."."..b2[1]), file=(":line/"..b2[2]..nx), x=(b2[3]), y=(b2[4])} end
		if ms then tag{"lyprop", id=(id), intermediate_render="1", intermediate_render_mask=(":line/"..ms..nx)} end

		-- 位置
		local sz = ex.getcsvdata("pos")
		tag{"lyprop", id=(id), left=(sz[1]), top=(sz[2])}

		----------------------------------------
		-- タイトル
		local t  = ex.getcsvdata("title")
		local tx = p.title
		if t and tx then
			if t[5] == "image" then
				local px = t[2]..nx..'/'
				local fl = tx..".png"
				if isFile(px..fl) then
					local ln = get_language(true)
					if ln ~= "ja" then fl = fl..'_'..ln end
				else
					fl = "none"
				end
				lyc2{ id=(id.."."..t[1]), file=(px..fl), x=(t[3]), y=(t[4])}
			else
				ui_message((id.."."..t[1]), { t[2], text=(tx)})
			end
		end

		----------------------------------------
		-- draw
		if ex.getdraw() then mwline_main() end

		----------------------------------------
		-- pos / tag
		local id = ex.getid("pos")
		local x  = p.x or 0
		local y  = p.y or 0
		tag{"lyprop", id=(id), left=(x), top=(y)}
		scr.line.pos = { x, y }

		-- disp
		if not flag then
			local tm = get_tweentime(p.speed or ex.getcsvdata("fade"))
			if not getSkip() then
				if p.mx then tween{ id=(id), x=((p.mx + x)..","..x), time=(tm) } end
				if p.my then tween{ id=(id), y=((p.my + y)..","..y), time=(tm) } end
			end
			trans{ fade=(tm) }
		end
	end
end
----------------------------------------
-- 消去
function mwline_close(p)
	if scr.line then
		local sync = p and tn(p.sync) ~= 0
		local id = ex.getid("base")
		local tm = get_tweentime(p.speed or ex.getcsvdata("fade"))
		local px = ":line/mask.png"
		if not isFile(px) then px = init.white end
		tag{"lyprop", id=(id), intermediate_render="1", intermediate_render_mask=(px)}
		if sync and not getSkip() then
			local ix = ex.getid("pos")
			local z  = scr.line.pos or {}
			if p.mx and z[1] then tween{ id=(ix), x=(z[1]..","..(p.mx + z[1])), time=(tm) } end
			if p.my and z[2] then tween{ id=(ix), y=(z[2]..","..(p.my + z[2])), time=(tm) } end
		end
		lydel2(id)
		if sync then
			mwline_del()
			trans{ fade=(tm) }
		elseif game.sw then		-- switchだけは専用処理にしておく
			mwline_del()
			flip()
		else
			flg.transcom = "mwline_del"
		end
		scr.line = nil
	end
	scr.ip.line = nil
end
----------------------------------------
-- 
----------------------------------------
--　本体
function mwline_main(flag)
	local t  = getTextBlock()
	local m  = t.linemode
	local s  = scr.line
--	local ch = s.ch
	local ln = get_language(true)

	-- text
	for i, v in ipairs(t[ln]) do
		-- buffに保存
		local bf = {
			y	  = scr.line.y,		-- y位置
			file  = scr.ip.file,	-- file
			block = scr.ip.block,	-- block name
		}
		scr.line.buff[scr.line.count] = bf

		-- 描画
		ex.linetext(v, flag)		-- text
		scr.line.count = scr.line.count + 1
	end

	-- check
	if debug_flag and scr.line.count > ex.max then
		error_message("扱えるlineの最大数を超えました")
	end

	-- trans
	if not flag and ex.getdraw() ~= "all" then
		-- voice
		if t.vo then
			sesys_vostack(t.vo)
			sesys_voloop()
		end

		-- scroll
		local zz = ex.getcsvdata("scroll")
		if getSkip() then flip() else
			local zz = ex.getcsvdata("scroll")
			uitrans(zz[2])
			flg.trans = nil		-- quickjump時のために倒しておく
		end
	end
end
----------------------------------------
-- 単体テキスト表示
function ex.linetext(t, flag)
	local s  = scr.line or {}		-- lineデータ
	local ct = s.count				-- line行番号
	local tb = getTextBlock()		-- textblock
	local lm = tb.linemode			-- linemode

	-- 初期化
	local ht = getLangHelp("line")	-- 既読(多言語文字データ)
	local p  = s.buff[ct]			-- タグデータ
	local ch = s.ch					-- 持ち主名
	local nm = ex.getname(t)		-- 話者名
	local z  = ex.getcsvdata(ch) or {}
	local wn = z[1] or 1			-- window番号

	-- id
	local ib   = ex.getid("text").."."..ct
	local idtx = ib..".tx"	-- 本文
	local idnm = ib..".nm"	-- 名前
	local idic = ib..".ic"	-- icon
	local idtm = ib..".tm"	-- time
	local idar = ib..".ar"	-- aread

	----------------------------------------
	-- 左右番号
	local us = s.ch == nm							-- user flag
	local no = us and "us" or "pa"					-- 持ち主番号
	local nw = string.format("%02d", wn)			-- ２桁(wd)
	local nx = nw..no								-- ４桁(wd+no)

	----------------------------------------
	-- text / stamp
	local w  = 100			-- size w
	local h  = 100			-- size h
	local view = true		-- 吹き出し表示フラグ

	-- text
	if not lm.stamp then
		set_textfont("line"..nx, idtx, true)
		tag{"chgmsg", id=(idtx)}
		tag{"rp"}
		ex.textdraw(t)
		tag{"var", name="t.w", system="get_message_layer_width"}
		tag{"var", name="t.h", system="get_message_layer_height"}
		tag{"/chgmsg"}
		w = tn(e:var("t.w"))
		h = tn(e:var("t.h"))

	-- stamp
	else
		-- file確認 / 多言語差し替え
		local sf = lm.stamp
		local ax = explode("/", sf)
		local fz = ax[#ax]
		local zz = anyCheck{ file=(fz) }
		if fz ~= zz then sf = sf:gsub(fz.."$", zz) end
		lyc2{ id=(ib..".st"), file=(sf) }
		w = mulpos(lm.w)	-- stamp size w
		h = mulpos(lm.h)	-- stamp size h

		-- 背景なし
		local zz = ex.getcsvdata("stamp") or {}
		local sm = zz[1] or "bgoff"
		if sm == "bgoff" then view = nil end
	end

	----------------------------------------
	-- 吹き出し背景
	local zz = ex.getcsvdata(s.mode..nx)
	local md = zz[2]	-- name mode
	local bx = zz[3]	-- 相対位置x
	local by = zz[4]	-- 相対位置y
	local bw = zz[5]	-- パーツサイズw
	local bh = zz[6]	-- パーツサイズh
	local rx = 0		-- 既読/時刻x相対値
	local ry = 0		-- 既読/時刻y相対値
	local rs = 0		-- 間隔補正
	if not view then
		-- stamp自動補正
		local sm = ex.getcsvdata("stamp") or {}
		rx = us and bw*2 - sm[2] or -(bw*2) + sm[2]
		ry = -bh + sm[3]
		rs = -(bh*2)
		local sx = us and bw or -bw
		tag{"lyprop", id=(ib..".st"), left=(sx), top=(-bh) }
	else
		local fl = ":line/"..zz[1]	-- base file
		local zw = math.ceil(w * 100 / bw)
		local zh = math.ceil(h * 100 / bh)
		lyc2{ id=(ib..".bg.lu"), file=(fl), anchorx="0", anchory="0", xscale="100", yscale="100", clip=("0,0,"..bw..","..bh), x=(-bw), y=(-bh) }
		lyc2{ id=(ib..".bg.up"), file=(fl), anchorx="0", anchory="0", xscale=(zw) , yscale="100", clip=((bw*1)..",0,"..bw..","..bh), y=(-bh) }
		lyc2{ id=(ib..".bg.ru"), file=(fl), anchorx="0", anchory="0", xscale="100", yscale="100", clip=((bw*2)..",0,"..bw..","..bh), x=(w), y=(-bh) }
		lyc2{ id=(ib..".bg.lt"), file=(fl), anchorx="0", anchory="0", xscale="100", yscale=(zh) , clip=("0,"..bh..","..bw..","..bh), x=(-bw) }
		lyc2{ id=(ib..".bg.ct"), file=(fl), anchorx="0", anchory="0", xscale=(zw) , yscale=(zh) , clip=(bw..","..bh..","..bw..","..bh) }
		lyc2{ id=(ib..".bg.rt"), file=(fl), anchorx="0", anchory="0", xscale="100", yscale=(zh) , clip=((bw*2)..","..bh..","..bw..","..bh), x=(w) }
		lyc2{ id=(ib..".bg.ld"), file=(fl), anchorx="0", anchory="0", xscale="100", yscale="100", clip=("0,"..(bh*2)..","..bw..","..bh), x=(-bw), y=(h) }
		lyc2{ id=(ib..".bg.dw"), file=(fl), anchorx="0", anchory="0", xscale=(zw) , yscale="100", clip=((bw*1)..","..(bh*2)..","..bw..","..bh), y=(h) }
		lyc2{ id=(ib..".bg.rd"), file=(fl), anchorx="0", anchory="0", xscale="100", yscale="100", clip=((bw*2)..","..(bh*2)..","..bw..","..bh), x=(w), y=(h) }

		-- 吹き出しマーク
		local fk = zz[7]		-- 吹き出しfile
		if fk ~= "none" then
			-- 左右位置
			local fm = zz[8]	-- 吹き出しalign mode top/center/bottom
			local fx = zz[9]	-- 吹き出し左右位置補正
			local fy = zz[10]	-- 吹き出し上下位置補正
			local fh = zz[11]	-- 吹き出しheight
			local gx = us and (w + fx) or fx
			local gy = fy
			if fm == "bottom" then
				gy = fy + h - fh
			elseif fm == "center" then
				gy = fy + math.floor((h - fh) / 2)
			end
			lyc2{ id=(ib..".bg.fk"), file=(":line/"..fk), x=(gx), y=(gy)}
		end
	end

	----------------------------------------
	-- 位置調整
	local ar = ex.getcsvdata("area")
	local yy = s.yy or by
	local x  = bx + ar[1]
	local y  = by + ar[2] + yy
	if us then
		local ww = ar[3] - w - bx
		x = x + ww
	end
	tag{"lyprop", id=(ib), left=(x), top=(y)}
	scr.line.yy = by + yy + h + ar[5] + rs

	----------------------------------------
	-- 名前とアイコン
	local hd = s.mode
	if md == "name" or md == "both" then
		set_textfont((hd.."nm"..nw), idnm, true)
		tag{"chgmsg", id=(idnm)}
		tag{"print", data=(nm)}
		tag{"/chgmsg"}
		tag{"lyprop", id=(idnm), left="0", top="0"}
	end

	-- icon
	local zz = ex.getcsvdata(nm)
	if zz and (md == "icon" or md == "both") then
		local ic = not us and zz[5] or zz[2]
		local ix = not us and zz[6] or zz[3] + w
		local iy = not us and zz[7] or zz[4]
		if ic ~= "none" then
			lyc2{ id=(idic), file=(":line/"..ic), x=(ix), y=(iy)}
		end
	end

	-- time
	if lm.time then
		local tx = us and 0 or w
		local ty = h
		set_textfont((hd.."tm"..nx), idtm, true)
		tag{"chgmsg", id=(idtm)}
		tag{"rp"}
		tag{"print", data=(lm.time)}
		tag{"/chgmsg"}
		tag{"lyprop", id=(idtm), left=(tx+rx), top=(ty+ry)}
	end

	-- aread
	local tx = lm.aread or 1
	local ar = hd.."ar"..nw
	if us and tx ~= "none" and lang.font[ar] then
		local v  = getLangHelp("line")
		local nn = v.arad or "既読"
		if tx == 1 then tx = nn else tx = nn.." "..tx end
		set_textfont((hd.."ar"..nw), idar, true)
		tag{"chgmsg", id=(idar)}
		tag{"rp"}
		tag{"print", data=(tx)}
		tag{"/chgmsg"}
		tag{"lyprop", id=(idar), left=(rx), top=(h+ry)}
	end

	----------------------------------------
	-- 表示
	local dr = ex.getdraw()
	local zz = ex.getcsvdata("scroll")
	if not flag and not dr and not getSkip() then
		tween{ id=(ib), y=((y+zz[1])..","..y), time=(zz[2]) }
	end

	-- 全体チェック
	local z  = ex.getcsvdata("area")
	local y  = scr.line.yy
	local mx = z[4]
	if y > mx then
		local sc = scr.line.y or 0
		local nx = mx - y
		local id = ex.getid("scrl")
		if not flag and not dr and not getSkip() then
			tween{ id=(id), y=(sc..","..nx), time=(zz[2]) }
		else
			tag{"lyprop", id=(id), top=(nx)}
		end
		scr.line.y = nx
	end
end
----------------------------------------
function mwline_del()
	local tb = { ".tx", ".nm", ".tm", ".ar" }	-- text / name / time / aread
	local id  = ex.getid("text").."."
	for i=1, ex.max do
		for j, nm in ipairs(tb) do
			tag{"chgmsg", id=(id..i..nm)}
			tag{"rp"}
			tag{"/chgmsg"}
		end
	end

	-- title
	local t  = ex.getcsvdata("title")
	if t and t[5] == "font" then
		local id = ex.getid("base")
		ui_message((id.."."..t[1]))
	end
end
----------------------------------------
function mwline_reset()
	local s = scr.line
	if s then
		mwline_del()
		lydel2(init.mwlineid)
	end
	scr.line = nil
	if scr.ip then scr.ip.line = nil end
end
----------------------------------------
-- データ
----------------------------------------
-- csv読み込み
function ex.getcsv()
	local v  = csv.line or {}
	local s  = scr.line or {}
	local md = s.mode or "line"
	return v[md] or {}
end
----------------------------------------
-- csvデータ読み込み
function ex.getcsvdata(nm)
	local v  = csv.line or {}
	local s  = scr.line or {}
	local md = s.mode or "line"
	return v[md] and v[md][nm] or v.base and v.base[nm]
end
----------------------------------------
-- id
function ex.getid(nm)
	local id = init.mwlineid
	local tbl = {
		pos  = ".p",
		base = ".p.b",
		scrl = ".p.b.1",
		area = ".p.b.1.a",
		text = ".p.b.1.a.1",
	}
	if tbl[nm] then id = id..tbl[nm] end
	return id
end
----------------------------------------
-- 名前を取得
function ex.getname(p)
	local r = nil
	if p.name then r = p.name[1] end
	return r
end
----------------------------------------
-- draw取得
function ex.getdraw()
	local t = getTextBlock()
	local r = t.linemode and t.linemode.draw
	return r
end
----------------------------------------
-- テキスト描画 / blockごと
function ex.textdraw(p)
	for i, v in ipairs(p) do
		if type(v) == "table" then
			local s = v[1]
			if tags[s] then tags[s](e, v) else e:tag(v) end		-- [ruby][rt]等の実行
		else
			tag{"print", data=(v)}
		end
	end
end
----------------------------------------
-- quickjump関連
----------------------------------------
-- text再描画
function mwline_quickjump(no, flag)
	if not no then return end

	-- 現在の値を保存
	local fl = scr.ip.file
	local bl = scr.ip.block

	-- 下処理
	local p  = log.stack
	local ln = p[no].line

	-- 現在がlinemodeであれば手前で止める
	local t  = ast[bl].text
	if not flag and ln.linemode then table.remove(ln.buff) end
	local mx = #ln.buff

	-- 
	if mx >= 1 then
		for i=1, mx do
			local bx = ln.buff[i]
			local z  = ast[bx].text
			if z and z.linemode and not z.linemode.draw then
--				scr.ip.file  = fl
				scr.ip.block = bx
				mwline_main(true)
			end
		end
	end

	-- 戻す
	scr.ip.file  = fl
	scr.ip.block = bl
	scr.ip.line  = ln.buff
end
----------------------------------------
-- quickjump tag実行
function mwline_quicktags(p, no, md)
	local z  = log.stack[no]
	local bl = z.block
	local t  = ast[bl].text.linemode
	if t and t.start and md == "exskip" then

	elseif z.line then
		local fl = z.file
		local bl = z.block
		local r  = readScriptFile(fl)	-- 読み直しておく
		if r then
			scr.ip.file  = fl
			scr.ip.block = bl
			mwline_open(p, true)	-- 再表示
			mwline_quickjump(no)	-- line check
		end
	end
end
----------------------------------------
-- exskip呼び出し時に実行
function mwline_exskip()
	if init.mwlineid then
		local bl = scr.ip.block
		local z  = ast[bl].text or {}
		if z.linemode then
			scr.ip.line = {}
		end

		-- すでに開かれている場合は現在値を保存
		local g = log.stack
		if g and g[#g] and g[#g].line then
			scr.ip.line = tcopy(g[#g].line.buff)
		end
	end
end
----------------------------------------
-- baclkogに保存
function getLineData()
	local r = nil
	local s = scr.ip
	local p = ast[s.block].text
	if init.mwlineid and scr.ip.line then
		r = { file=(s.file), block=(s.block) }

		-- 行コントロール
		local ln = tcopy2(s.line)
		if p.linemode then
			table.insert(ln, s.block)
			r.linemode = true
		end
		r.buff = tcopy2(ln)
		scr.ip.line = ln
	end
	return r
end
----------------------------------------
