----------------------------------------
-- おまけ／立ち絵鑑賞
----------------------------------------
local ex = {
	char = { "hiy", "kan", "asu", "shi", "ame", "mir", "hir", "rir" },
	chno = { hiy=1, kan=2, asu=3, shi=4, ame=5, mir=6, hir=7, rir=8 },
	font = { "btrt02", "btrt06", "btrt10", "btrt14", "btrt18", "btrt22" },
	siki = 9,
	csfg = 8	-- csfg scroll size
}
----------------------------------------
-- 立ち位置lock
--			左５  左３  左    左２ 中  右２ 右   右３ 右５
ex.lock = { -520, -380, -230, -160, 0, 160, 230, 380, 520 }
----------------------------------------
-- FG初期化
function exf.fginit()
	message("通知", "立ち絵鑑賞")

	local nm = game.pa and "exlist.tbl" or "exlist_cs.tbl"
	e:include("system/table/"..nm)

	-- 初期化
	if not appex.exfg then appex.exfg = {} end
	exf.fgreset()

	-- MW alpha
	local p = repercent(conf.mw_alpha, 255)
	e:tag{"lyprop", id=(getBtnID("mw")), alpha=(p)}
	e:tag{"lyprop", id=(getBtnID("nm")), alpha=(p)}

	-- drag
	exf.fgdraginit()

	appex.exfg.pagemax = 0
end
----------------------------------------
-- drag
function exf.fgdraginit()
	lyc2{ id="500.1", width=(game.width), height=(game.height), color="00000000", draggable="1"}
	lyevent{ id="500.1", name="extr", dragin="extra_fgbgdragin", drag="extra_fgbgdrag", dragout="extra_fgbgdragout"}
end
----------------------------------------
-- reset
function exfg_reset()
	message("通知", "fg reset")
	exf.fgtext()
end
----------------------------------------
-- 
function exf.fgresetsave()
	for i, nm in ipairs(ex.char) do
		sys.extr[nm] = nil
	end
end
----------------------------------------
-- 終了時に呼び出す
function exf.fgexit()
	message("通知", "立ち絵鑑賞を終了します")
	exf.fgtext()
	exf.fgresetsave()
	exfgtable = nil
end
----------------------------------------
-- 
function exf.fgtext(flag)
	if flag == "del" then
		ui_message("500.z.rt.p01", "--")
		ui_message("500.z.rt.p02", "--")
		ui_message("500.z.rt.p03", "--")
		ui_message("500.z.rt.p04", "--")
	elseif flag then
		-- ボタンから座標を作る
		if game.pa then
			for i, nm in ipairs(ex.font) do
				local v  = getBtnInfo(nm)
				local id = "500.z.rt.p0"..i
				ui_message((id), {"exfgnum", x=(v.x), y=(v.y), text="--"})
			end
		end
		ui_message("500.bm.tx", {"fgtext", text=""})
		ui_message("500.bm.nm", {"fgname", text=""})
		set_uihelp("500.z.bt.help", "fghelp")
	else
		-- 消去
		del_uihelp()			-- ui help
		ui_message("500.z.rt.p01")
		ui_message("500.z.rt.p02")
		ui_message("500.z.rt.p03")
		ui_message("500.z.rt.p04")
		ui_message("500.z.rt.p05")
		ui_message("500.z.rt.p06")
		ui_message("500.bm.tx")
		ui_message("500.bm.nm")
	end
end
----------------------------------------
-- ページ生成
function exf.fgpage()
	local p, page, char = exf.getTable()
	local px = p.p

	exf.fgview()
end
----------------------------------------
-- 
----------------------------------------
-- 変数初期化
function exf.fgreset(flag)
	if game.cs or not sys.exfg then sys.exfg = {} end
	sys.exfg.open = 1
	local s = sys.exfg

	-- text
	sys.extr.mw = s.mw or 0		-- MW 0:非表示
	sys.exfg.mw = s.mw or 0
	exf.fgtext(not flag)

	-- 背景
	sys.exfg.bg = s.bg or 0		-- 背景番号 0:なし -1:外部

	-- 立ち絵ボタン
	for i, nm in ipairs(ex.char) do
		sys.extr[nm] = s[nm] or 0
		local bt = "ch"..string.format("%02d", i)
		local c  = sys.exfg[nm] == 1 and "clip_c" or "clip"
		btn_clip(bt, c)
	end
end
----------------------------------------
-- 表示制御
function exf.fgview()
	local s = sys.exfg

	if game.pa then
		-- 立ち絵ボタン類
		local c = not s.fgview and "c"
		for i=1, 16 do
			local nm = "btrt"..string.format("%02d", i)
			setBtnStat(nm, c)
		end

		-- 背景時間帯
		local c = s.bg < 1 and "c"
		for i=21, 24 do
			local nm = "btrt"..i
			setBtnStat(nm, c)
		end
	end

	----------------------------------------
	-- 画像表示
	----------------------------------------
	-- MW
	extra_exfgmw()

	----------------------------------------
	-- 背景
	local p  = exfgtable.bg
	local id = "500.bg"
	local no = s.bg
	local nx = "--"
	lydel2(id)
	if no == -1 and s.img then
		local px = e:var("s.savepath").."/"
		local fl = px..s.img
		if isFile(fl) then
			lyc2{ id=(id..".0"), file=(init.black)}
			lyc2{ id=(id..".1"), file=(fl)}

			-- get_layer_info
			tag{"var", name="t.ly", system="get_layer_info", id=(id..".1")}
			local x = math.floor((game.width  - e:var("t.ly.width" )) / 2)
			local y = math.floor((game.height - e:var("t.ly.height")) / 2)
			tag{"lyprop", id=(id..".1"), left=(x), top=(y)}
		else
			sys.exfg.img = nil
			sys.exfg.bg  = 0
			no = 0
		end
	elseif no > 0 then
		local m = #p[no]
		nx = s.bgst or 1
		if nx > m then nx = 1 end
		sys.exfg.bgst = nx
		lyc2{ id=(id), file=(":bg/"..p[no][nx])}
	end
	ui_message("500.z.rt.p05", no)
	ui_message("500.z.rt.p06", nx)

	----------------------------------------
	-- 立ち絵
	lydel2(extra_getfgid())
	local nm = s.active
	if nm then
		-- 文字
		local z = s.fgs[nm]
		ui_message("500.z.rt.p01", z.fuku)
		ui_message("500.z.rt.p02", z.pose)
		ui_message("500.z.rt.p03", z.face)
		ui_message("500.z.rt.p04", z.size)
	else
		exf.fgtext("del")
	end

	-- 表示
	local ct = 0
	if s.fgs then
		for nm, v in pairs(s.fgs) do
			if v.show then extra_eximage(nm) ct = ct + 1 end
		end
	end

	-- systemボタン / cs
	if game.cs then
		local dt = ct == 0 and 'c'
		setBtnStat('exsy02', dt)	-- move
		setBtnStat('exsy03', dt)	-- save
		setBtnStat('exsy05', dt)	-- def

		-- load
		if e:var("g.fgsave") == "0" then
			setBtnStat('exsy04', 'c')
		else
			setBtnStat('exsy04', nil)
		end

		-- char icon
		local bt = btn.cursor
		for ch, i in pairs(ex.chno) do
			local nm = string.format("ch%02d", i)
			local v  = getBtnInfo(nm)
			local z  = s.fgs or {}
			if z[ch] and z[ch].show then
				local cl = nm == bt and "clip_d" or "clip_c"
				tag{"lyprop", id=(v.idx..".0"), clip=(v[cl])}
				sys.extr[ch] = 1
			else
				local cl = nm == bt and "clip_a" or "clip"
				tag{"lyprop", id=(v.idx..".0"), clip=(v[cl])}
				sys.extr[ch] = 0
			end
		end
	end
end
----------------------------------------
-- fg
function extra_eximage(nm)
	local tb = ex.chno
	local s  = sys.exfg
	local p  = exfgtable.fg[tb[nm]]
	local z  = s.fgs[nm]
	local sz = z.size
	local po = z.pose
	local fk = z.fuku
	local yu = nil

	----------------------------------------
	-- id
	local id  = extra_getfgid(nm)
	local idx = id..".0"

	----------------------------------------
	-- body
	local size = exfgtable.fg.size[sz]
	local path = p.path..size.."/"
	local head = p.head
	local fuku = p.fuku[fk]
	if fuku == "99" then
		path = ":fg/yuk/"..size.."/"
		head = "yuk_"
		fuku = "02"
		po = 1
		yu = "z"
	end
	local pose = p.pose[po][1]
	local arms = p.pose[po][2]
	local fmax = p.pose[po][3]
	local head = head..size..pose
	local ext  = game.fgext

	-- asu 03(マイク)
	local ex01 = nil
	if fuku:find('|') then
		local a = explode("|", fuku) 
		fuku = a[1]
		ex01 = pose..a[2]
	end
	local file = head..fuku..arms.."0"

	-- 設置
	local md = init.system.fgmode == "csv"
	local px = path..file..ext
	local v  = md and fgpos[head]
	local zz = v  and v[file] or getfgfilepos(px)
	lyc2{ id=(idx..'.0'), file=(px), clickablethreshold="1"}
	tag{"lyprop", id=(idx), left=(zz.x), top=(zz.y)}
	tag{"lyevent", id=(idx..'.0'), type="click", name="extr", mode="init", fgnm=(nm), key="1", handler="calllua", ["function"]="extra_fgmovetarget"}

	-- face
	local pz = yu or pose
	local tb = p.face[pz]
	local no = z.face if no > #tb then no = #tb end
	local fa = tb[no]
	local ex = nil
	if fa:find('|') then
		local a = explode("|", fa) 
		fa = a[1]
		ex = a[2]
	end
	if nm == "asu" and fuku == "06" and pose == "a" or nm == "hir" and fuku == "08" then
		local a = fa:sub(6)
		local b = fa:sub(1, 5)
		if a == "" then a = "f" else a = "g" end
		fa = b..a
	end
	local px = path..fa..ext
	local zf = v  and v[fa] or getfgfilepos(px)
	lyc2{ id=(idx..'.1'), file=(px), x=(zf.x - zz.x), y=(zf.y - zz.y)}

	-- ex
	if ex01 then
		local px = path..ex01..ext
		local zf = v  and v[ex01] or getfgfilepos(px)
		lyc2{ id=(idx..'.2'), file=(px), x=(zf.x - zz.x), y=(zf.y - zz.y)}
	else
		lydel2(idx..'.2')
	end
	if ex then
		local px = path..ex..ext
		local zf = v  and v[ex] or getfgfilepos(px)
		lyc2{ id=(idx..'.3'), file=(px), x=(zf.x - zz.x), y=(zf.y - zz.y)}
	else
		lydel2(idx..'.3')
	end
--[[
	local a1 = z.ex01
	if a1 then
		local px = path..pose.."00"..a1..ext
		local zf = v  and v[a1] or getfgfilepos(px)
		lyc2{ id=(idx..'.4'), file=(px), x=(zf.x - zz.x), y=(zf.y - zz.y)}
	else
		lydel2(idx..'.4')
	end
	local a2 = z.ex02
	if a2 then
		local px = path..pose.."00"..a2..ext
		local zf = v  and v[a2] or getfgfilepos(px)
		lyc2{ id=(idx..'.5'), file=(px), x=(zf.x - zz.x), y=(zf.y - zz.y)}
	else
		lydel2(idx..'.5')
	end
]]
	-- 位置
	local x = z.x or 0
	local y = z.y or 0
	tag{"lyprop", id=(id), left=(x), top=(y)}

	-- active
	local hd = s.hide
	local ac = s.active
	local c  = not hd and nm ~= ac and "808080"
	local a  = not hd and nm ~= ac and  128 or 255
	tag{"lyprop", id=(idx), intermediate_render="1", colormultiply=(c), alpha=(a)}
end
----------------------------------------
-- id取得
function extra_getfgid(nm)
	local id = "500.bh"
	if nm then
		if not sys.exfg.id  then sys.exfg.id  = {} end
		if not sys.exfg.ida then sys.exfg.ida = {} end
		local s  = sys.exfg.fgs[nm]
		local sz = s.size
		local sm = sys.exfg.id[sz] or 0		-- 全体id
		local im = s.id or {}				-- キャラのid
		local ix = im[sz] or sm

		-- move時は実行しない
		if not flg.fghide then
			-- アクティブ状態で後ろにある場合は最前面に出す
			local ac = sys.exfg.active
			local sa = sys.exfg.ida[sz]
			if not sa then
				sys.exfg.id[sz]  = sm
				sys.exfg.ida[sz] = nm
			elseif ac == nm and sa ~= nm and ix <= sm then
				ix = sm + 1
				sys.exfg.id[sz]  = sm + 1
				sys.exfg.ida[sz] = nm
			end

			-- キャラid保存
			if not s.id then sys.exfg.fgs[nm].id = {} end
			sys.exfg.fgs[nm].id[sz] = ix
		end
		id = id.."."..sz.."."..ix
	end
	return id
end
----------------------------------------
-- 立ち絵drag
function extra_fgbgdrag()
	local s  = sys.exfg
	local nm = s.active

	-- ボタンの上
	if flg.fgdrag then
		tag{"lyprop", id="500.1", left="0", top="0"}
		flip()

	-- drag
	elseif nm and (not s.hide or flg.fghide) then
		local z  = sys.exfg.fgs[nm]
		local id = extra_getfgid(nm)

		-- get_layer_info
		tag{"var", name="t.ly", system="get_layer_info", id="500.1"}
		local lx = tn(e:var("t.ly.left"))
		local ly = tn(e:var("t.ly.top"))
		local x  = lx + z.x
		local y  = ly + z.y

		-- 座標lock
		if not appex.shlock then
			local lc = 32
--			lx = math.floor(lx / lc) * lc
--			ly = math.floor(ly / lc) * lc
			local tbl = ex.lock
			for i, v in ipairs(tbl) do
				if x > v-lc and x < v+lc then lx = v - z.x break end			
			end
			if y > -lc and y < lc then ly = 0 - z.y end
		end

		sys.exfg.pos = { x=(lx), y=(ly) }
		tag{"lyprop", id=(id), left=(z.x + lx), top=(z.y + ly)}
		flip()
	end
end
----------------------------------------
function extra_fgbgdragin()
	sys.exfg.pos = { x=0, y=0 }
	if game.pa and btn.cursor then flg.fgdrag = true end	-- ボタンの上
end
----------------------------------------
function extra_fgbgdragout(e, p)
	local s  = sys.exfg
	local nm = s.active
	if nm then
		local z  = sys.exfg.fgs[nm]
		local px = sys.exfg.pos
		local id = extra_getfgid(nm)
		local x  = z.x + px.x
		local y  = z.y + px.y
		tag{"lyprop", id=(id), left=(x), top=(y)}
		sys.exfg.fgs[nm].x = x
		sys.exfg.fgs[nm].y = y
	end
	sys.exfg.pos = nil
	flg.fgdrag = nil			-- ボタンの上

	-- 初期位置へ
	local id = p.id
	tag{"lyprop", id=(id), left="0", top="0"}
	flip()
end
----------------------------------------
-- 
----------------------------------------
-- MW
function extra_exfgmw()
	local s = sys.exfg
	local n = s.name if n == "" then n = nil end	-- name
	local t = s.text if t == "" then t = nil end	-- text
	local v = sys.extr.mw or 0						-- mw状態
	local c = n and 1 or 0							-- name背景状態
	sys.exfg.mw = v

	-- close
	if game.pa then
		local nm = v == 0 and "clip" or "clip_c"
		btn_clip("cl", nm)
	end

	-- name
	local id = "500.bm.nz"
	lydel2(id)
	if n then
		local px = get_uipath().."mw/name/"..n..".png"
		if isFile(px) then
			local t  = csv.mw.name
			lyc2{ id=(id), file=(px), x=(t.x), y=(t.y)}
			c = 0
			n = nil
		end
	end
	tag{"lyprop", id="500.bm", visible=(v)}
	tag{"lyprop", id=(getBtnID("nm")), visible=(c)}
	extra_exfgmw_textview("500.bm.nm", n)
	extra_exfgmw_textview("500.bm.tx", t)
end
----------------------------------------
-- キャラ
function extra_exfgmw_textview(id, text)
	local f = {"font", face=(init.font02)}
	e:tag{"chgmsg", id=(id), layered="1"}
	e:tag{"rp"}
	if text then
		local s = text:gsub("[a-zA-Z0-9]+", "<>%1<>")
		local a = explode("<>", s)
		local c = true
		for i, tx in ipairs(a) do
			if c then
				e:tag{"print", data=(tx)}
				c = nil
			else
				c = true
				e:tag(f)
				e:tag{"print", data=(tx)}
				e:tag{"/font"}
			end
		end
	end
	e:tag{"/chgmsg"}
end
----------------------------------------
-- キャラ
function exf.fgchar(v)
	if not sys.exfg.fgs then sys.exfg.fgs = {} end
	local s  = sys.exfg
	local ac = s.active
	local nm = v.def
	if not nm then
		message("通知", "不明なエラーです", nm)
		return
	end
	local z  = s.fgs[nm] or {}

	-- 新規表示
	if not z.show then
		exf.fgcharreset(nm)
		sys.exfg.fgs[nm].show = true
		sys.exfg.active = nm
		sys.exfg.fgview = true
		sys.exfg[nm] = 1
		sys.extr[nm] = 1

	-- 消去
	elseif z.show and nm == ac then
		sys.exfg.fgs[nm].show = nil
		sys.exfg.active = nil
		sys.exfg.fgview = nil
		sys.exfg[nm] = 0
		sys.extr[nm] = 0

	-- active
	else
		sys.exfg.active = nm
		sys.exfg.fgview = true
		sys.exfg[nm] = 1
		sys.extr[nm] = 1
	end

	-- ボタン
	local bt = btn.cursor
	local bx = "btlt_"..nm
	if bt == bx then
		local c = sys.exfg[nm] == 1 and "clip_d" or "clip_a"
		btn_clip(bt, c)
	end

	exf.fgview()
	flip()
end
----------------------------------------
-- キャラクタリセット
function exf.fgcharreset(nm, flag)
	if not sys.exfg.fgs[nm] then sys.exfg.fgs[nm] = {} end
	local s = sys.exfg.fgs[nm]

	sys.exfg.fgs[nm].fuku = not flag and s.fuku or 1
	sys.exfg.fgs[nm].pose = not flag and s.pose or 1
	sys.exfg.fgs[nm].face = not flag and s.face or 1
	sys.exfg.fgs[nm].size = not flag and s.size or 2
	sys.exfg.fgs[nm].x = not flag and s.x or 0
	sys.exfg.fgs[nm].y = not flag and s.y or 0
end
----------------------------------------
-- 初期化
function exf.fgimagedef()
	local s  = sys.exfg
	local nm = s.active
	if nm then
		local z = s.fgs[nm]
--		if z.x == 0 and z.y == 0 then
			exf.fgcharreset(nm, true)
--		else
--			sys.exfg.fgs[nm].x = 0
--			sys.exfg.fgs[nm].y = 0
--		end
	end

	-- 背景は毎回初期化
	sys.exfg.bg   = 0
	sys.exfg.bgst = nil
	sys.exfg.img  = nil
	exf.fgview()

	-- cs active
	local bt = btn.cursor
	if bt and game.cs then btn_active2(bt) end
	flip()
end
----------------------------------------
-- 
----------------------------------------
function extra_exfgclick(e, p)
	local bt = p.bt or btn.cursor
	local sw = {

		add  = function(v) exf.fgadd(v) end,
		char = function(v) exf.fgchar(v) end,
		ex01 = function(v) exf.fgimageex(v, "ex01") end,		-- ex01
		ex02 = function(v) exf.fgimageex(v, "ex02") end,		-- ex02


		hide = function() exf.fghide("extra_fghidewait") end,	-- ボタン非表示
		move = function() exf.fghide("extra_fghidemove") end,	-- キャラ移動
		capt = function() exf.fghide("extra_fgimagewhite") end,	-- スクショ
		read = function() exf.fgimageread() end,				-- image読み込み
		save = function() exf.fgimagesave() end,				-- 簡易セーブ
		load = function() exf.fgimageload() end,				-- 簡易ロード
		def  = function() exf.fgimagedef() end,					-- 立ち絵リセット

		text = function() exf.fgmwtext() end,					-- mw text

		path = function() open_savepath() end,
	}
	if bt then
		local v = getBtnInfo(bt)
		local p1 = v.p1
		local p2 = v.p2
			if sw[p1] then se_ok() sw[p1](v)
		elseif sw[p2] then se_ok() sw[p2](v)
		else message(bt, p1) end
	end
end
----------------------------------------
-- 加減算
function exf.fgadd(v)
	local s  = sys.exfg
	local p  = exfgtable
	local cm = v.def
	local p2 = tn(v.p2)
	local p3 = v.p3
	local no = s[cm] or 0

	----------------------------------------
	-- 背景は-1まである
	if cm == "bg" then
		local m = #p.bg
		if s.img then	no = addsubloop(no, p2, -1, m)
		else			no = addsubloop(no, p2,  0, m) end
		sys.exfg.bg = no
	elseif cm == "bgst" then
		local m = #p.bg[s.bg]
		sys.exfg[cm] = addsubloop(no, p2, 1, m)

	----------------------------------------
	-- 立ち絵
	elseif p3 == "fg" then
		local nm = s.active
		local tb = ex.chno
		local an = tb[nm]
		local s  = s.fgs[nm]
		local p  = exfgtable.fg[an]
		if cm == "face" then
			local z = s.pose or 1
			local m = p.pose[z][3]
			local n = addsubloop((s.face or 1), p2,  1, m)
			sys.exfg.fgs[nm].face = n
		elseif cm == "size" then
			local v = exfgtable.fg.size
			local m = #v
			local n = addsubloop((s.size or 2), p2,  1, m)
			sys.exfg.fgs[nm].size = n
		elseif cm == "fuku" then
			local m = #p[cm]
			local n = 1
			if nm == "ma" then
				n = s[cm] == 1 and 2 or 1
			else
				n = addsubloop((s[cm] or 1), p2,  1, m)
			end
			sys.exfg.fgs[nm][cm] = n
		elseif cm == "pose" then
			local m = #p[cm]
			local n = s.pose or 1
			if m > 1 then
				if p2 == 1 or p2 == -1 then
					n = addsubloop(n, p2,  1, m)
				else
					local a = p2 < 0 and 1 or -1
					n = addsubloop(n, a,  1, m)
				end
				sys.exfg.fgs[nm].pose = n
			end
		else
			local m = #p[cm]
			local n = addsubloop((s[cm] or 1), p2,  1, m)
			sys.exfg.fgs[nm][cm] = n
		end

		-- 雪景シキ
		if nm == "asu" then
			local s  = sys.exfg.fgs[nm]
			local fk = s.fuku
			if fk == ex.siki then
				local tb = ex.chno
				local p  = exfgtable.fg[tb[nm]]
				local ma = #p.face.a
				local mz = #p.face.z
				local fa = s.face
				if fa == ma then fa = mz elseif fa > mz then fa = 1 end
				sys.exfg.fgs[nm].pose = 1
				sys.exfg.fgs[nm].face = fa
			end
		end
	else
		local m = #p[p3][s[p3]]
--		if no > m then no = 1 elseif no < 1 then no = m end
		sys.exfg[cm] = addno(no, 1, m, p2)
	end
	exf.fgview()
	button_autoactive()
	flip()
end
----------------------------------------
-- 拡張画像
function exf.fgimageex(v, nm)
	local s  = sys.exfg
	local ch = s.active
	local p  = ch and s.fgs[ch]
	if p and not flg.fghide and not s.hide then
		if p[nm] then
			sys.exfg.fgs[ch][nm] = nil
		else
			sys.exfg.fgs[ch][nm] = v.p2
		end
		exf.fgview()
		button_autoactive()
		flip()
	end
end
----------------------------------------
-- ボタン非表示
function exf.fghide(nm)
	local bt = btn.cursor
	if bt then
		flg.csfgbtn = bt
		btn_nonactive(bt)
	end

	-- 立ち絵再表示
	sys.exfg.hide = true
	exf.fgview()
	flip()

	-- hide
	local time = 200
--	systween{ id="500.z.lt", x="0,-360", time=(time)}
	systween{ id="500.z.rt", x="0,384" , time=(time)}
	systween{ id="500.z.bt", y="0,72"  , time=(time)}
	systween{ id="500.sy"  , x="0,-200", time=(time)}
	if game.cs then
		local v = getBtnInfo("help")
		systween{ id=(v.idx), y=(v.y..","..(v.h + v.y)), time=(time)}
	end
	estag("init")
	estag{"eqwait", time}
	estag{"lyprop", id="500.z" , visible="0"}
	estag{"lyprop", id="500.sy", visible="0"}
	estag{"flip"}
--	estag{"lytweendel", id="500.z.lt"}
	estag{"lytweendel", id="500.z.rt"}
	estag{"lytweendel", id="500.z.bt"}
	estag{"lytweendel", id="500.sy"}
	if nm then estag{nm} end
	estag()
end
----------------------------------------
-- ボタン表示
function extra_fgshow()
	local time = 200
	tag{"lyprop", id="500.z" , visible="1"}
	tag{"lyprop", id="500.sy", visible="1"}
	sys.exfg.hide = nil
	exf.fgview()
	flip()
--	systween{ id="500.z.lt", x="-360,0", time=(time)}
	systween{ id="500.z.rt", x="384,0" , time=(time)}
	systween{ id="500.z.bt", y="72,0"  , time=(time)}
	systween{ id="500.sy"  , x="-200,0", time=(time)}
	if game.cs then
		local v = getBtnInfo("help")
		systween{ id=(v.idx), y=((v.h + v.y)..","..v.y), time=(time)}
	end
	estag("init")
	estag{"eqwait", time}
--	estag{"lytweendel", id="500.z.lt"}
	estag{"lytweendel", id="500.z.rt"}
	estag{"lytweendel", id="500.z.bt"}
	estag{"lytweendel", id="500.sy"}
	if game.cs then estag{"extra_fgshow_csactive"} end
	estag()
end
----------------------------------------
-- CS / btn active
function extra_fgshow_csactive()
	local bt = flg.csfgbtn
	if bt then
		btn_active2(bt)
		flip()
		flg.csfgbtn = nil
	end
end
----------------------------------------
-- ボタン非表示待機
function extra_fghidewait()
	estag("init")
	estag{"eqwait", {time="20000000", input="1"}}
	estag{"se_cancel"}
	estag{"extra_fgshow"}
	estag()
end
----------------------------------------
-- 移動
----------------------------------------
-- 移動開始
function extra_fghidemove()
	local s = sys.exfg
	flg.fghide = {}
	flg.fgacti = s.active
	flg.repeattime = 1			-- key repeat上書き
	message("通知", "drag mode")
end
----------------------------------------
-- close
function extra_fghideclose(e, p)
	if flg.fghide then
		if not sys.exfg.active then sys.exfg.active = flg.fgacti end
		flg.fghide = nil
		flg.fgacti = nil
		flg.repeattime = nil	-- key repeat消去
		message("通知", "drag mode終了")
		se_cancel()
		extra_fgshow()
	else
		extra_exfgclick(e, p)
	end
end
----------------------------------------
-- clickで代用してみる
function extra_fgmovetarget(e, p)
	if flg.fghide then
		local nm = p.fgnm
		sys.exfg.active = nm
		sys.exfg.fgview = true
	end
end
----------------------------------------
--[[
function extra_fgmoveover(e, p)
	if flg.fghide then
		local nm = p.name
		flg.fghide[nm] = true

		local s = sys.exfg
		if not s.pos then
			local nx = extra_fgmove_getname()
			sys.exfg.active = nx
		end
	end
end
----------------------------------------
function extra_fgmoveout(e, p)
	if flg.fghide then
		local nm = p.name
		flg.fghide[nm] = nil

		local s = sys.exfg
		if not s.pos then
			local nx = extra_fgmove_getname()
			sys.exfg.active = nx
		end
	end
end
----------------------------------------
-- 一番手前のキャラを返す
function extra_fgmove_getname()
	local r = nil
	local p = flg.fghide
	if p then
		local sx = 0
		local nx = { -1, -1, -1 }
		for nm, tr in pairs(p) do
			local s  = sys.exfg.fgs[nm]
			local sz = s.size
			local no = s.id[sz]
			if sz > sx and no > nx[sz] then
				r = nm
				sx = sz
				nx[sz] = no
			end
		end
		if r then flg.fgacti = r end
	end
	return r
end
]]
----------------------------------------
-- 
----------------------------------------
-- セーブフォルダに画像を書き出す
function extra_fgimagewhite()
	local path = e:var("s.savepath").."/"
	local file = "screen"
	for i=1, 9999 do
		local fl = file..string.format("%04d", i)
		local px = path..fl..".png"
		if not isFile(px) then
			file = fl
			break
		end
	end

	-- 
	local v  = getLangHelp("dlgmes")
	local nm = v.exfg_write:gsub("%[file%]", file)
	estag("init")
	estag{"eqwait", 100}
	estag{"takess"}	-- SSをメモリに保存
	estag{"savess", file=(file), width=(game.width), height=(game.height)}
	estag{"extra_fgshow"}
	estag{"eqwait", 10}
--	estag{"tag_dialog", { title="notice", message="セーブフォルダに "..file..".png を書き出しました"}}
	estag{"tag_dialog", { title="notice", message=(nm)}}
	estag()
end
----------------------------------------
-- セーブフォルダから画像を読み出す
function exf.fgimageread()
	-- exfg_readfile:読み込むファイル名を指定してください
	local nm = sys.exfg.img or ""
	tag_dialog({ varname="t.yn", textfield="t.tx", textfieldsize="60", title="exfg_readfile", message=(nm)}, "extra_fgimageread_next")
end
----------------------------------------
function extra_fgimageread_next()
	local yn = e:var("t.yn")
	local nm = e:var("t.tx"):gsub("\n", "")
	if yn == "1" and nm ~= "" then
		local p = appex.exfg.buff
--		if nm:sub(1, 5) ~= "image" then nm = "image"..nm end

		exf.fgimageread_check(nm)
	end
end
----------------------------------------
-- 読み込んだファイルを確認
function exf.fgimageread_check(nm)
	local px = e:var("s.savepath").."\\"..nm
	local t = {"", ".png", ".jpg", ".jpeg"}
	local flag = true
	for i, exp in ipairs(t) do
		if isFile(px..exp) then
			sys.exfg.bg = -1
			sys.exfg.img = nm..exp
			exf.fgview()
			flip()
			flag = nil
			break
		end
	end
	if flag then
		local v  = getLangHelp("dlgmes")
		local tx = v.exfg_badname:gsub("%[name%]", nm)
--		tag_dialog({ title="error", message=(nm.."は読み込めないファイルです。")})
		tag_dialog({ title="error", message=(tx)})
	end
end
----------------------------------------
--
----------------------------------------
-- 保存
function exf.fgimagesave()
	-- exfg_savenum:保存する番号を指定してください[1-50]
	tag_dialog({ varname="t.yn", textfield="t.tx", textfieldsize="10", title="exfg_savenum"}, "fgimagesave_next")
end
----------------------------------------
function exf.fgimagesave_next()
	local v  = getLangHelp("dlgmes")
	local yn = tn(e:var("t.yn"))
	local nm = e:var("t.tx")
	local no = tn(nm)
	if yn == 1 then
		if no and no >= 1 and no <= 50 then
			exf.fgresetsave()
			local p = fload_pluto("g.fgsave") or {}
			p[no] = sys.exfg
			fsave_pluto("g.fgsave", p)

			local tx = v.exfg_oknum:gsub("%[no%]", no)
			estag("init")
			estag{"asyssave"}
			estag{"fgimagesave_next2"}
--			estag{"tag_dialog", { title="notice", message=(no.."番に保存しました。") }}
			estag{"tag_dialog", { title="notice", message=(tx) }}
			estag()
		elseif nm == "" or type(nm) ~= "number" then
--			tag_dialog({ title="error", message=("番号を入力してください。")})
			tag_dialog({ title="error", message="exfg_no"})
		else
			local tx = v.exfg_badnum:gsub("%[no%]", no)
--			tag_dialog({ title="error", message=(nm.." は使用できない番号です。")})
			tag_dialog({ title="error", message=(tx)})
		end
	end
end
----------------------------------------
function exf.fgimagesave_next2()
	exf.fgreset()
	exf.fgview()
	flip()
end
----------------------------------------
-- 読み込み
function exf.fgimageload()
	-- exfg_readnum:読み込む番号を指定してください[1-50]
	tag_dialog({ varname="t.yn", textfield="t.tx", textfieldsize="10", title="exfg_readnum"}, "fgimageload_next")
end
----------------------------------------
function exf.fgimageload_next()
	local v  = getLangHelp("dlgmes")
	local yn = tn(e:var("t.yn"))
	local nm = e:var("t.tx")
	local no = tn(nm)
	if yn == 1 then
		if no and no >= 1 and no <= 50 then
			local p = fload_pluto("g.fgsave") or {}
			if p[no] then
				sys.exfg = p[no]
				exf.fgreset()
				exf.fgview()
				flip()
			else
				local tx = v.exfg_nonum:gsub("%[no%]", no)
				tag_dialog({ title="notice", message=(tx) })	-- no.."番にデータがありませんでした
			end
		elseif nm == "" or type(nm) ~= "number" then
			tag_dialog({ title="error", message="exfg_no"})		-- 番号を入力してください。
		else
			local tx = v.exfg_badnum:gsub("%[no%]", nm)
			tag_dialog({ title="error", message=(tx)})			-- nm.." は使用できない番号です。
		end
	end
end
----------------------------------------
-- 
----------------------------------------
-- 文字入力
function exf.fgmwtext()
	local s = sys.exfg
--	tag_dialog({ varname="t.yn", title="名前を入力してください", message=(s.name), textfield="t.nm", textfieldsize="40" }, "fgmwtext2")
	tag_dialog({ varname="t.yn", title="exfg_name", message=(s.name), textfield="t.nm", textfieldsize="60" }, "fgmwtext2")
end
function exf.fgmwtext2()
	local yn = tn(e:var("t.yn"))
	if yn == 1 then
		local s = sys.exfg
--		tag_dialog({ varname="t.yn", title="本文を入力してください", message=(s.text), textfield="t.tx", textfieldsize="200"}, "fgmwtext_next")
		tag_dialog({ varname="t.yn", title="exfg_text", message=(s.text), textfield="t.tx", textfieldsize="240"}, "fgmwtext_next")
	end
end
----------------------------------------
function exf.fgmwtext_next()
	local yn = tn(e:var("t.yn"))
	local nm = e:var("t.nm")
	local tx = e:var("t.tx")
	if yn == 1 then
		sys.exfg.name = mb_substr(nm, 1, 16)
		sys.exfg.text = mb_substr(tx, 1, 26*3*2)
		sys.extr.mw = 1				-- MW 0:非表示
		exf.fgview()
		flip()
	end
end
----------------------------------------
-- CS版
----------------------------------------
function extra_csfgclick(e, p)	 extra_csfgclickex(btn.cursor) end
function extra_csfgclickui(e, p) extra_csfgclickex(p.bt) end
function extra_csfgclickex(bt)
	local sw = {
		-- MW on/off
		mw = function()
			local s = (sys.extr.mw or 0) + 1
			if s >= 2 then s = 0 end
			sys.extr.mw = s
			sys.exfg.mw = s
			extra_exfgmw()
			flip()
		end,

		hide = function() exf.fghide("extra_fghidewait") end,	-- ボタン非表示
		move = function() exf.fghide("extra_csfghidemove") end,	-- キャラ移動
		def  = function() exf.fgimagedef() end,					-- 立ち絵リセット
		text = function() exf.fgmwtext() end,					-- mw text
		save = function() exf.fghide("extra_csfg_save") end,	-- save
		load = function() exf.fghide("extra_csfg_load") end,	-- load

		-- BG
		bg = function() exf.fgadd{ def="bg", p2=(1), p3="bg" } end,

		-- drag
		EXIT = function() extra_fghideclose(e, {}) end,
		LB	 = function() extra_csfgmove_char(-1) end,
		RB	 = function() extra_csfgmove_char( 1) end,
	}
	if bt then
		local bx = btn.cursor
		local s  = sys.exfg.fgs or {}
		local v  = getBtnInfo(bt)
		local p1 = v.p1
		local p2 = v.p2
		local p3 = tn(v.p3)
		if flg.fghide then
			local cm = v.key
			if sw[cm] then sw[cm]() end

		elseif sw[p1] then
			sw[p1]()

		elseif p1 == "extra" then
			exf.clickextra(p2)

		elseif p1 == "param" then
			-- bg
			if bx == "exsy01" then
				if p2 == "add" then			 se_ok() exf.fgadd{ def="bg"  , p2=(p3), p3="bg" }		-- 背景
				elseif sys.exfg.bg ~= 0 then se_ok() exf.fgadd{ def="bgst", p2=(1 ), p3="bg" } end	-- 時間帯

			-- char
			elseif bx then
				local z  = getBtnInfo(bx)
				local ch = z.def
				if s[ch] and s[ch].show then
					-- active check
--					if not sys.exfg.active then sys.exfg.active = ch end
					sys.exfg.active = ch

					-- 切り替え
					if p2 == "add" then		 se_ok() exf.fgadd{ def="face", p2=(p3), p3="fg" }		-- 表情
					else					 se_ok() exf.fgadd{ def=(p2)  , p2=(1 ), p3="fg" } end	-- その他
				end
			end
		end
	end
end
----------------------------------------
function extra_csfg_posx(no)
	local bt = btn.cursor
	if bt == "exsy01" then
		se_ok()
		exf.fgadd{ def="bg", p2=(no), p3="bg" }

	elseif bt then
		local s  = sys.exfg.fgs or {}
		local v  = getBtnInfo(bt)
		local ch = v.def
		if v.p2 == "char" and s[ch] and s[ch].show then
			-- active check
			if not sys.exfg.active then sys.exfg.active = ch end

			-- lock位置
			local id = extra_getfgid(ch)
			local t  = ex.lock
			local mx = #t
			local x  = s[ch].x or 0
			local y  = s[ch].y or 0

			-- 左へ移動
			if no < 0 and x > t[1] then
				for i=mx-1, 1, -1 do
					if t[i] < x and x <= t[i+1] then
						x = t[i]
						break
					end
				end

			-- 右へ移動
			elseif no > 0 and x < t[mx] then
				for i=2, mx do
					if t[i-1] <= x and x < t[i] then
						x = t[i]
						break
					end
				end
			end
			sys.exfg.fgs[ch].x = x

			-- 表示
			tag{"lyprop", id=(id), left=(x), top=(y)}
			flip()
		end
	end
end
----------------------------------------
function extra_csfg_lt(e, p)
	if flg.fghide then	extra_csfgmove_add("x", -1)
	else				extra_csfg_posx(-1) end
end
----------------------------------------
function extra_csfg_rt(e, p)
	if flg.fghide then	extra_csfgmove_add("x", 1)
	else				extra_csfg_posx(1) end
end
----------------------------------------
function extra_csfg_up(e, p)
	if flg.fghide then	extra_csfgmove_add("y", -1)
	else				btn_up(e, { name="UP"}) end
end
----------------------------------------
function extra_csfg_dw(e, p)
	if flg.fghide then	extra_csfgmove_add("y", 1)
	else				btn_down(e, { name="DW"}) end
end
----------------------------------------
-- CS move
----------------------------------------
-- move
function extra_csfghidemove(e, p)
	extra_fghidemove()			-- 初期化

	-- cs table
	local ch = flg.fgacti
	local fl = false
	local m  = 0
	local z  = {}
	local s  = sys.exfg.fgs or {}
	for nm, v in pairs(s) do
		if v.show then
			table.insert(z, nm)
			m = m + 1
			if ch == nm then fl = true end
		end
	end
	flg.fghide.cs = z		-- キャラ一覧
	flg.fghide.csmax = m	-- キャラ数

	-- active
	if not fl then flg.fgacti = z[1] end
	extra_csfgmove_active()
end
----------------------------------------
function extra_csfgmove_char(no)
	local z  = flg.fghide.cs
	local mx = flg.fghide.csmax
	local ch = flg.fgacti
	if mx and mx > 1 and z and ch then
		-- 現在のキャラ
		local ct = 1
		for i, v in pairs(z) do
			if ch == v then
				ct = i
				break
			end
		end

		-- 計算
		local nx = ct + no
		if nx < 1 then nx = mx elseif nx > mx then nx = 1 end

		-- 変更
		se_ok()
		flg.fgacti = z[nx]
		extra_csfgmove_active()
	end
end
----------------------------------------
function extra_csfgmove_add(nm, no)
	local s  = sys.exfg.fgs or {}
	local ch = flg.fgacti
	if s[ch] then
		local id = extra_getfgid(ch)
		local x = s[ch].x or 0
		local y = s[ch].y or 0
		if nm == "x" then x = x + no * mulpos(ex.csfg)
		else			  y = y + no * mulpos(ex.csfg) end

		-- 保存
		sys.exfg.fgs[ch].x = x
		sys.exfg.fgs[ch].y = y
		tag{"lyprop", id=(id), left=(x), top=(y)}
		flip()
	end
end
----------------------------------------
function extra_csfgmove_active()
	local s  = sys.exfg.fgs or {}
	local ch = flg.fgacti
	for nm, v in pairs(s) do
		if v.show then
			local id = extra_getfgid(nm)
			local cl = nm ~= ch and "0xc0c0c0" or "ffffff"
			local al = nm ~= ch and 240 or 255
			tag{"lyprop", id=(id), intermediate_render="1", colormultiply=(cl), alpha=(al)}
		end
	end
	flip()
end
----------------------------------------
-- cs save/load
----------------------------------------
function extra_csfg_save()
	tag{"takess"}				-- サムネイル
	extra_csfg_dragsetting()	-- drag停止

	flg.csfg = { mode="save" }

	csvbtn3("fgsv", "600", lang.ui_fgsave)
	lyc2{ id="600.-1", width=(game.width), height=(game.height), color="0x80000000"}
	exf.csfg_savepage()
	uitrans()
end
----------------------------------------
function extra_csfg_load()
	extra_csfg_dragsetting()	-- drag停止

	flg.csfg = { mode="load" }

	csvbtn3("fgsv", "600", lang.ui_fgsave)
	lyc2{ id="600.-1", width=(game.width), height=(game.height), color="0x80000000"}
	exf.csfg_savepage()
	uitrans()
end
----------------------------------------
function exf.csfg_savepage()
	local px = e:var("s.savepath").."/"
	local pg = (flg.csfg.page or 1) - 1
	local mx = init.csfg_column or init.save_column
	local hd = pg * mx
	local p  = fload_pluto("g.fgsave") or {}
	local fc = "csfg"

	local ss = csv.mw.csfgthumb or csv.mw.savethumb				-- サムネイル位置
	local mm = init.csfg_message_max or init.save_message_max	-- セーブ文字数

	-- mask / none
	local mspx = get_uipath()..'extra/'
	local none = isFile(mspx.."none"..fc..".png") and mspx.."none"..fc or isFile(mspx.."none.png") and mspx.."none"
	local mask = isFile(mspx.."mask"..fc..".png") and mspx.."mask"..fc or isFile(mspx.."mask.png") and mspx.."mask"

	-- font color
	local ft = lang.font
	local t0 = ft[fc.."no"]	  and fc.."no"	 or ft.saveno	and "saveno"
	local t1 = ft[fc.."date"] and fc.."date" or ft.savedate and "savedate"
	local t2 = ft[fc.."titl"] and fc.."titl" or ft.savetitl and "savetitl"
	local t3 = ft[fc.."text"] and fc.."text" or ft.savetext and "savetext"
	local tp = ft[fc.."page"] and fc.."page" or ft.savepage and "savepage"

	-- loop
	for i=1, mx do
		local no = hd + i
		local v  = getBtnInfo('bt_save'..string.format("%02d", i))
		local id = v.idx
		local thid = id..".1"				-- サムネイルid
		lydel2(thid)

		-- font
		local sn = string.format("No.%02d", no)
		if t0 then ui_message((id..'.20'), { t0, text=(sn)}) end	-- セーブNo
		if t1 then ui_message((id..'.21'), { t1 }) end				-- セーブ日付／ゲーム内
		if t2 then ui_message((id..'.22'), { t2 }) end				-- セーブタイトル
		if t3 then ui_message((id..'.23'), { t3 }) end				-- セーブテキスト

		-- ある
		local t = p[no]
		if t then
			local fl = px..exf.csfg_getthumb(no)
			lyc2{ id=(thid), file=(fl), x=(ss.x), y=(ss.y), mask=(mask)}

			local tm = get_osdate("%Y/%m/%d %H:%M", t.date)
			local nm = t.name or ""
			local tx = mb_substr(t.text or "", 1, mm)
			if t1 then ui_message((id..'.21'), tm) end			-- セーブ日付／ゲーム内
			if t2 then ui_message((id..'.22'), nm) end			-- セーブタイトル
			if t3 then ui_message((id..'.23'), tx) end			-- セーブテキスト

		-- ない
		else
			if t1 then ui_message((id..'.21'), "") end			-- セーブ日付／ゲーム内
			if t2 then ui_message((id..'.22'), "NO DATA") end	-- セーブタイトル
			if t3 then ui_message((id..'.23'), "") end			-- セーブテキスト
		end
	end
end
----------------------------------------
function exf.csfg_getthumb(no)
	return string.format("csfg_%04d.png", no)
end
----------------------------------------
function extra_csfg_dragsetting(flag)
	local md = flag and "enable" or "disable"
	tag{"lyevent", id="500.1", mode=(md), type="dragin"}
	tag{"lyevent", id="500.1", mode=(md), type="drag"}
	tag{"lyevent", id="500.1", mode=(md), type="dragout"}
end
----------------------------------------
function extra_csfg_close()
	csvbtn3("extr", "500", lang.ui_fgmode)
	exf.fgdraginit()	-- drag
	extra_fgshow()
end
----------------------------------------
function extra_csfg_saveclick(e, p)
	local bt = p.bt or p.btn
	local v  = getBtnInfo(bt)
	local p1 = v.p1
	local p2 = tn(v.p2)

	-- 閉じる
	local close = function(flag)
		flg.fghide = nil
		flg.fgacti = nil
		flg.repeattime = nil	-- key repeat消去

		-- text
		local mx = init.csfg_column or init.save_column
		for i=1, mx do
			local nm = string.format("bt_save%02d", i)
			ui_message(getBtnID(nm)..'.20')
			ui_message(getBtnID(nm)..'.21')
			ui_message(getBtnID(nm)..'.22')
			ui_message(getBtnID(nm)..'.23')
		end

		flg.csfg = nil
		delbtn("fgsv")

		estag("init")
		estag{"uitrans"}
		if flag then estag{"syssave"} end
		estag{"extra_csfg_close"}
		estag()
	end

	-- 
	local sw = {
		-- close
		close = function() close() end,

		-- saveload
		save = function()
			se_ok()
			local p = fload_pluto("g.fgsave") or {}
			if flg.csfg.mode == "save" then
				local t = csv.mw.exfgsave or csv.mw.savethumb
				tag{"savess", file=(exf.csfg_getthumb(p2)), width=(t.w), height=(t.h)}

				sys.exfg.date = get_unixtime()		-- 現在時刻(unixtime)
				p[p2] = sys.exfg
				fsave_pluto("g.fgsave", p)
				close(true)
			else
				sys.exfg = p[p2] or sys.exfg
				sys.extr.mw = sys.exfg.mw			-- mw
				close()
			end
		end,
	}
	if sw[p1] then sw[p1]() end
end
----------------------------------------
