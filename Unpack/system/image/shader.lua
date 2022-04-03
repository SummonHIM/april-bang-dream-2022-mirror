----------------------------------------
-- image / shader
----------------------------------------
local ex = {}
----------------------------------------
ex.digit = "%.12f"
ex.userpath	= ":sys/"
ex.userid	= ".effect"
----------------------------------------
-- 対応するシェーダー
ex.shadertable = {
	reset	= true,			-- リセット
	blur_h	= true,			-- ガウスフィルタ / 横
	blur_v	= true,			-- ガウスフィルタ / 縦
--	add		= "cadd",		-- 色加算 / 加算合成
--	mul		= "cmul",		-- 色乗算 / 乗算合成
	gray	= true,			-- グレースケール
	sepia	= true,			-- セピア
--	sepia2	= true,			-- セピア
	nega	= true,			-- ネガポジ反転
--	rgb		= true,			-- RGB

	-- 合成
--	add		= "cadd",		-- 色加算 / 加算合成
--	mul		= "cmul",		-- 色乗算 / 乗算合成
	screen	= true,			-- スクリーン合成
--	compbr	= true,			-- 比較(明)
--	compbrc	= true,			-- 比較(明)／カラー
--	compdk	= true,			-- 比較(暗)
--	compdkc	= true,			-- 比較(暗)／カラー

	-- 加工
--	raster	= true,			-- ラスタースクロール
--	mosaic	= true,			-- モザイク
--	fglass	= true,			-- すりガラス
--	uzumaki	= true,			-- うずまき
}
----------------------------------------
-- 動作時にバッファをクリアしない
ex.shaderstop = {
	raster	= true,
}
----------------------------------------
-- モザイクパラメータ(決め打ち)
ex.mosaic = {
	["out"]	= { 20, 30, 40, 50, 60, 70, 80, 90, 160, 0 },
	["in"]	= { 100, 90, 80, 70, 60, 50, 40, 30, 20, 10 },
	inout	= { 100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 20, 30, 40, 50, 60, 70, 80, 90, 160, 0 },
}
----------------------------------------
-- 
----------------------------------------
-- shader初期化
function shader_init()
	local z  = init.system
	local px = z.blur_path		-- path
	local ep = z.blur_exp		-- 拡張子
	if not px or not ep then
		return
	elseif game.os ~= "windows" and game.trueos == "windows" and z.fake then
		px = z.fake.blur_path
		ep = z.fake.blur_exp
	end

	-- 読み込み
	if not shadersave then shadersave = {} end
	local path = "system/shader/"..px
	local read = function(nm)
		local px = path..nm..ep
		local md = nm:gsub("ma/", "")
		if not shadersave[md] and isFile(px) then
--			message("shader", md, "を読み込みました", px)
			tag{"lyshader", id=(md), file=(px)}
			shadersave[md] = true
		end
	end

	-- loop
	for nm, nx in pairs(ex.shadertable) do
		read(nm)
--		read("ma/"..nm.."_a")
--		read("ma/"..nm.."_m")
--		read("ma/"..nm.."_a_m")
		if type(nx) == "string" then
			read(nx)
		end
	end
end
----------------------------------------
-- シェーダー適用
function shader_lyprop(id, p)
	local z  = ex.shadertable
	local md = p.style

	-- blur
	if not p.noblur then
		shader_psstop(id, true)		-- 前のは停止
		shader_blur(id, p)
	end
	if not md then return end

	----------------------------------------
	-- effect
	local no = p.effect			-- shadertexture番号
	if not no and type(z[md]) == "string" then md = z[md] end	-- shadertexture処理がある場合にシェーダー名を書き換える

	-- vsync停止
	if flg.shader and ex.shaderstop[md] ~= true then shader_vsyncstop(id) end

	----------------------------------------
	-- 分岐
	local sw = {
		-- 停止
		reset = function() shader_psstop(id) end,

		-- 色加算
		cadd = function()
			local r = shader_getcolor(p, "000000")
			tag{"lyprop", id=(id), shader=(md), shaderconstant="red,green,blue", red=(r.r), green=(r.g), blue=(r.b)}
		end,

		-- 色減算
		csub = function()
			local r = shader_getcolor(p, "000000")
			tag{"lyprop", id=(id), shader=(md), shaderconstant="red,green,blue", red=(r.r), green=(r.g), blue=(r.b)}
		end,

		-- 色乗算
		cmul = function()
			local r = shader_getcolor(p, "ffffff")
			tag{"lyprop", id=(id), shader=(md), shaderconstant="red,green,blue", red=(r.r), green=(r.g), blue=(r.b)}
		end,

		-- sepia / 乗算
		sepia = function()
			local r = shader_getcolor(p, init.sepia)
			tag{"lyprop", id=(id), shader=(md), shaderconstant="red,green,blue", red=(r.r), green=(r.g), blue=(r.b)}
		end,

		-- sepia2 / 加算乗算
		sepia2 = function()
			local z = init.shader_sepia2 or {}
			local r = shader_getcolor({ r = (p.r or z[1] or 0.15), g = (p.g or z[2] or 1.00), b = (p.b or z[3] or 0.85) }, "26ffd8")
			tag{"lyprop", id=(id), shader=(md), shaderconstant="red,green,blue", red=(r.r), green=(r.g), blue=(r.b)}
		end,

		-- RGB
		rgb = function()
			local r = shader_tostring(p.r or 0)
			local g = shader_tostring(p.g or 0)
			local b = shader_tostring(p.b or 0)
			tag{"lyprop", id=(id), shader=(md), shaderconstant="red,green,blue", red=(r), green=(g), blue=(b)}
		end,

		-- 特殊動作 / vsync
		mosaic = function()	shader_mosaicinit(id, p) end,		-- モザイク

		-- ラスタースクロール
		raster = function()
			local es = p.ease
			if es == "out" then
				local z = flg.shader or {}
				local v = z[id]
				if v then shader_rasterstop(id, p) end
			else
				shader_psstop(id, true)	-- 前のは停止
				shader_blur(id, p)
				shader_rasterinit(id, p)
			end
		end,

		-- ラスタースクロール停止
		rasterout = function()
			local z = flg.shader or {}
			local v = z[id]
			if v then shader_rasterstop(id, p) end
		end,

		-- すりガラス
		fglass = function()
			local w = shader_tostring(1 / game.width)
			local h = shader_tostring(1 / game.height)
			local s = shader_tostring(p.ssize or "5.0")
			tag{"lyprop", id=(id), shader=(md), shaderconstant="width,height,size", width=(w), height=(h), size=(s)}
		end,

		-- うずまき
		uzumaki = function()
			local w = shader_tostring(1 / game.width)
			local h = shader_tostring(1 / game.height)
			local s = shader_tostring(p.ssize or "0.1")
			local r = shader_tostring(p.radius or "2.0")
			tag{"lyprop", id=(id), shader=(md), shaderconstant="width,height,size,radius", width=(w), height=(h), size=(s), radius=(r)}
		end,

		-- artemis
		ar_add	 = function(c) tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="0", colormultiply=(c)} end,
		ar_multi = function(c) tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="0", colormultiply=(c)} end,
		ar_nega  = function(c) tag{"lyprop", id=(id), intermediate_render="1", negative="1", grayscale="0", colormultiply="0xFFFFFF"} end,
		ar_gray  = function(c) tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="1", colormultiply="0xFFFFFF"} end,
		ar_sepia = function(c) tag{"lyprop", id=(id), intermediate_render="1", negative="0", grayscale="1", colormultiply=(c)} end,
--		ar_reset = function(c) tag{"lyprop", id=(id), intermediate_render="0", negative="0", grayscale="0", colormultiply="0xFFFFFF"} scr.tone = nil end,
		ar_anistop=function(c) end,
		ar_ex	 = function(c) end,
	}

	-- 振り分け
	if shadersave[md] then
		if sw[md] then
			shader_crop(id, p)
			sw[md]()
		else
			shader_crop(id, p, md)
		end
	elseif ex.shaderstop[md] and sw[md] then
		shader_crop(id, p)
		sw[md]()
	else
		local md = md:find("ar_") and md or "ar_"..md
		local c  = p.color
		if sw[md] then sw[md](c) end
	end
end
----------------------------------------
-- シェーダー / crop
function shader_crop(id, p, sh)
	local no = p.effect
	local cg = id..ex.userid
	lydel2(cg)

	-- shadertexture
	local func = function()
		if no then
			local lp = p.efloop				-- ループ
			local ax = p.efrange or 255		-- 効果範囲
			local pr = shader_tostring(ax / 255)
			local fl = no:find(":[a-z]+/") and no or ex.userpath..no
			if isFile(fl..".ogv") then
				tag{"video" , id=(cg), file=(fl..".ogv"), loop=(lp)}
				tag{"lyprop", id=(cg), visible="0"}
			else
				lyc2{ id=(cg), file=(fl), visible="0"}
			end

			-- 設置
			if id == "1.0" then
				screen_crop(id)
				tag{"lyprop", id=(id), shader=(sh), shadertexture="textureUser", textureUser=(cg), shaderconstant="param", param=(pr)}
			else
				tag{"lyprop", id=(id), shader=(sh), shadertexture="textureUser", textureUser=(cg), shaderconstant="param", param=(pr), intermediate_render="1", clip=(game.clip)}
			end
		else
			message("警告", no, "は存在しないcgです")
		end
	end

	-- crop
	if id == "1.0" then
		if no then
			func()
		else
			screen_crop(id)
			if sh then tag{"lyprop", id=(id), shader=(sh)} end
		end
	elseif no then
		func()
	elseif sh then
		tag{"lyprop", id=(id), intermediate_render="1", clip=(game.clip), shader=(sh)}
	else
		tag{"lyprop", id=(id), intermediate_render="1", clip=(game.clip)}
	end
end
----------------------------------------
-- シェーダー / フィルタ処理
function shader_colortone(id, p)
	-- style
	if p.style or p.blur then shader_lyprop(id, p) end

	-- zone
	local zo = scr.zone
	if zo then
		local ix = addImageID(id, 'tone')
		shader_lyprop(ix, { style="cmul", scolor=(zo), noblur=true })
	end

	-- fgfフィルタ
	local ch = p.ch
	local sf = scr.img.fgf
	local ff = sf and sf[ch] and sf[ch].zone
	local zo = ff or zo
	if zo then
		shader_lyprop(id, { style="cmul", scolor=(zo), noblur=true })
	end
end
----------------------------------------
-- シェーダー / trans時に実行
function shader_trans(p)
	local s = scr.tone
	if s then shader_lyprop("1.0", s.p) end
end
----------------------------------------
-- カラー変換
function shader_getcolor(p, def)
	local co = (p.scolor or def):gsub("0?x", "")
	local func = function(d1, d2, def)
		local r = d1 or d2
		if not r then r = tonumber(def, 16) / 255 end
--		if r < 0 then r = 0 elseif r > 1 then r = 1 end

		r = shader_tostring(r)
		if r == "0" then r = "0.0" elseif r == "1" then r = "1.0" end
		return r
	end
	return {
		r  = func(p.gammar, p.red  , co:sub(1, 2)),
		g  = func(p.gammag, p.green, co:sub(3, 4)),
		b  = func(p.gammab, p.blue , co:sub(5, 6))
	}
end
----------------------------------------
-- シェーダー / PixelShader停止
function shader_psstop(id, flag)
	if not flag then
		shader_vsyncstop(id)	-- vsync停止

		-- shader / ps reset
		tag{"lyprop", shader="reset", id=(id)}	-- 画面を戻す
		tag{"lyprop", shader="", id=(id)}		-- 空にすると無効化
	end

	-- blur停止
	local md = id == "1.0"
	local ix = md and getImageID("blurx") or addImageID(id, "blurx")
	local iy = md and getImageID("blury") or addImageID(id, "blury")
	tag{"lyprop", shader="", id=(ix)}
	tag{"lyprop", shader="", id=(iy)}
end
----------------------------------------
-- blur
----------------------------------------
function shader_blur(id, p)
	local bx = p.blurx or p.blur or 0	-- 
	local by = p.blury or p.blur or 0	-- 
	if bx > 0 or by > 0 then
		local md = id == "1.0"
		local cl = game.clip
		local sh_x = "blur_h"	-- 横
		local sh_y = "blur_v"	-- 縦
--[[
		local nm = p[1]
		if nm == "fg" or nm == "bg" and p.id then
			sh_x = sh_x.."_a"
			sh_y = sh_y.."_a"
		end
		if p.mask then
			sh_x = sh_x.."_m"
			sh_y = sh_y.."_m"
		end
]]
		-- 横
		if bx > 0 then
			local ix = md and getImageID("blurx") or addImageID(id, "blurx")
			local wx = shader_getgauss(bx)
			local sw = shader_tostring(1 / game.width)
			tag{"lyprop", id=(ix), shader=(sh_x), shaderconstant="weights,width", weights=(wx), width=(sw), intermediate_render="1", clip=(cl)}
		end

		-- 縦
		if by > 0 then
			local ix = md and getImageID("blury") or addImageID(id, "blury")
			local wx = shader_getgauss(by)
			local sh = shader_tostring(1 / game.height)
			tag{"lyprop", id=(ix), shader=(sh_y), shaderconstant="weights,height", weights=(wx), height=(sh), intermediate_render="1", clip=(cl)}
		end
	end
end
----------------------------------------
-- ガウス関数 / a exp{ -(x-b)^2 / 2c^2 }
function shader_getgauss(no)
	local sz = no	-- 参照するピクセル半径(1-8)
	local pr = 2	-- 調整パラメータ
	if sz > 8 then
		sz = 8
		pr = no - 6
	end

	-- 加算
	local w  = {}
	local ct = 0	-- カウンタ
	local mx = 0	-- 最大値
	for i=1, sz do
		local wg = math.exp(-(ct * ct) / (2 * pr * pr))
		mx = mx + wg
		ct = ct + 1
		table.insert(w, wg)
	end

	-- stringにして返す
	mx = mx * 2 - 1
	for i=1, 8 do
		if w[i] then w[i] = shader_tostring(w[i] / mx)
		else		 w[i] = "0.0" end
	end
	return table.concat(w, ",")
end
----------------------------------------
-- 整数確認
function shader_tostring(no)
	local r = tostring(no)
	if not r:find(".", 1, true) then
		r = r..".0"
	elseif #r > 10 then
		r = string.format(ex.digit, no)
	end
	return r
end
----------------------------------------
-- vsync処理
----------------------------------------
-- vsync呼び出し
function shader_vsync()
	local z  = flg.shader
	local sw = {
		raster = function(id, v) shader_rastervsync(id, v) end,		-- ラスタースクロール
		mosaic = function(id, v) shader_mosaicvsync(id, v) end,		-- モザイク
	}
	if z then
		for i, v in pairs(z) do 
			local md = v.shader
			if sw[md] then sw[md](i, v) end
		end
		if not flg.trans then flip() end	-- trans中は実行しない
	end
end
----------------------------------------
-- vsync削除
function shader_vsyncdelete(id)
	local z = flg.shader
	if z then
		if id then	shader_vsyncstop(id)
		else		flg.shader = nil end
	end
end
----------------------------------------
-- vsync停止
function shader_vsyncstop(id)
	if flg.shader then
		flg.shader[id] = nil
		local c = 0
		for i, nm in pairs(flg.shader) do c = c + 1 end
		if c == 0 then flg.shader = nil end
	end
end
----------------------------------------
-- 動的更新
----------------------------------------
-- ラスタースクロール
function shader_rasterinit(id, p)
	local es = p.ease
	if es == "out" then
		local z = flg.shader or {}
		local v = z[id]
		if v then shader_rasterstop(id, p) end
		return
	end

	local ag = p.angle or 0
	local iv = 360 * (p.inter or 4)
	local sz = (p.ssize or 5) / 1000

	local z = {"lyprop", shader="raster", id=(id), shaderconstant="angle,inter,size"}
	z.angle = shader_tostring(ag)		-- vsyncで渡す値(角度)
	z.inter = shader_tostring(iv)		-- うねうねの間隔
	z.size  = shader_tostring(sz)		-- うねうねのサイズ

	-- ease
	if es and sz > 0 then
		local tm = p.sfade or p.time or init.bg_fade
		local ad = string.format(ex.digit, (sz / tm))
		z.ease = es				-- ease
		z.sadd = ad				-- サイズ加算値
		z.smax = sz				-- サイズ最大値
		z.snow = e:now()
		z.size = "0"
	end

	-- 保存
	if not flg.shader then flg.shader = {} end
	flg.shader[id] = z
end
----------------------------------------
-- ラスタースクロール停止
function shader_rasterstop(id, p)
	local z  = flg.shader[id]
	local tm = p.sfade or p.time or init.bg_fade
	local sz = tn(z.size)
	local ad = string.format(ex.digit, (sz / tm))
	z.ease = "out"			-- ease
	z.sadd = ad				-- サイズ加算値
	z.smax = sz				-- サイズ最大値
	z.snow = e:now()
end
----------------------------------------
-- ラスタースクロール / vsync
function shader_rastervsync(id, v)
	tag(v)

	local n = v.angle + 1
	if n > 360 then n = 0 end
	flg.shader[id].angle = shader_tostring(n)

	-- ease
	local es = v.ease
	if es then
		local n = e:now() - v.snow
		local s = es == "in" and n * v.sadd or v.smax - n * v.sadd
		local r = nil
		if s <= 0 or getSkip(true) then
			flg.shader[id] = nil
		elseif s >= v.smax then
			s = v.smax
			flg.shader[id].ease = nil
			flg.shader[id].sadd = nil
			flg.shader[id].smax = nil
			flg.shader[id].snow = nil
			flg.shader[id].size = shader_tostring(s)
		else
			flg.shader[id].size = shader_tostring(s)
		end
	end
end
----------------------------------------
--
----------------------------------------
-- モザイク
function shader_mosaicinit(id, p)
	shader_vsyncstop(id)	-- 停止しておく
	local m  = ex.mosaic
	local es = p.ease
	local t  = es and m[es]
	local mx = t and #t
	local sz = p.ssize or 1
	if sz < 0 then sz = 0 elseif mx and sz > mx then sz = mx end

	-- 単発
	if not t or not mx then
		shader_mosaiciview("in", sz, id)

	-- skip
	elseif getSkip(true) then
		shader_mosaiciview(es, t[mx], id)

	-- vsync
	else
		local z  = { shader="mosaic", id=(id), style=(es), ct=1, mx=(mx) }
		local tm = p.sfade or p.time or init.bg_fade
		local ad = tm / mx
		z.add = ad
		z.now = e:now()

		-- 初回
		shader_mosaiciview(es, 1, id)

		-- 保存
		if not flg.shader then flg.shader = {} end
		flg.shader[id] = z
	end
end
----------------------------------------
-- モザイク / vsync
function shader_mosaicvsync(id, p)
	local ad = p.now + p.add
	local tm = e:now()
	if ad <= tm then
		local id = p.id
		local ct = p.ct
		local mx = p.mx
		ct = ct + 1
		if ct <= mx then
			local st = p.style
			flg.shader[id].ct  = ct
			flg.shader[id].now = e:now()
			shader_mosaiciview(p.style, ct, id)
		else
			shader_vsyncstop(id)	-- 停止しておく
		end
	end
end
----------------------------------------
-- モザイク実行
function shader_mosaiciview(st, no, id)
	local m  = ex.mosaic
	local t  = m[st]
	local sz = t[no]
	if sz and sz > 0 then
		local z  = {"lyprop", shader="mosaic", id=(id), shaderconstant="size,ratio"}
		local ra = string.format(ex.digit, (game.width / game.height))
		z.size  = shader_tostring(sz)		-- vsyncで渡す値(サイズ)
		z.ratio = shader_tostring(ra)		-- 縦横比
		tag(z)
	else
		shader_psstop(id)
	end
end
----------------------------------------
