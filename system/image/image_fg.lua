----------------------------------------
-- 立ち絵制御
----------------------------------------
function readfgImage(id, p, flag)
	readImage(id, p, flag)
end
----------------------------------------
-- fg
----------------------------------------
-- fg
function image_fg(p)
	local mode = tn(p.mode or 3)
	local sync = tn(p.sync or 0)
	local ch = p.ch

	----------------------------------------
	-- mode保存
	if not scr.img.mwf then scr.img.mwf = {} end
	if ch then scr.img.mwf[ch] = mode end

	----------------------------------------
	-- face
	if mode == 1 or mode == 3 then
		if ch then
			if not scr.face then scr.face = {} end
			scr.face[ch] = p
		end

		-- mode1は立ち絵を消す
		if mode == 1 and scr.img.fg and scr.img.fg[ch] then
			if sync == 1 then
				pushTag{ fgdel, p }
				popTag()
			else
				image_store('fgdel', p)
			end
		end
	elseif ch and scr.face then
		scr.face[ch] = nil
	end

	----------------------------------------
	-- 立ち絵表示
	if mode >= 2 then
		-- すぐに表示する
		if sync == 1 then
--			pushTag{ stackImageCache, p }		-- キャッシュデータ解析
			pushTag{ fg, p }
			popTag()

		-- cacheしておく
		else
--			stackImageCache(p)
			image_store('fg', p)
		end

	----------------------------------------
	-- 消去
	elseif mode == -1 then
		faceparamdel(ch)
		if sync == 1 then
			pushTag{ fgdel, p }
			popTag()
		else
			image_store('fgdel', p)
		end

	----------------------------------------
	-- 全消去
	elseif mode == -2 then
		scr.face = nil
		if sync == 1 then
			pushTag{ fgdelall, p }
			popTag()
		else
			image_store('fgdelall', p)
		end
	end
end
----------------------------------------
-- delay fg
function delay_fg(p)
	local mode = tn(p.mode or 3)
	if mode > 1 then fg(p)
	elseif mode ==  1 then	-- mode=1で立ち絵消去するとクイックジャンプで復帰してしまうのでダミー措置(いずれ修正を)
	elseif mode == -1 then fgdel(p)
	elseif mode == -2 then fgdelall(p)
	else error_message(mode..'は不明な立ち絵指定です') end
end
----------------------------------------
-- fg / exskip
function exskip_fg(p)
	local ch = p.ch
	local md = tn(p.mode)
	if ch and (md == 1 or md == 3) then
		if not scr.face then scr.face = {} end
		scr.face[ch] = p
	end
end
----------------------------------------
-- fg
function fg(p, flag)
	local id  = getImageID('fg', p)
	local idx = addImageID(id, 'base')

	----------------------------------------
	-- fgframe補正
	local ch = p.ch
	local xx = 0
	if scr.img.fgf[ch] then
		xx  = scr.img.fgf[ch].fx - game.centerx
		id  = scr.img.fgf[ch].idx..'.fg'
		idx = addImageID(id, 'base')
		scr.img.fgf[ch].fgid = tn(p.id)
	end

	----------------------------------------
	-- face再保存
	local mode = tn(p.mode)
	if ch and mode == 3 then
		if not scr.face then scr.face = {} end
		scr.face[ch] = p
	end

	----------------------------------------
	-- レイヤー削除
	local d = scr.img.fg[ch]
	if d and (p.resize or d.id ~= id) then
		-- 同一キャラのサイズ変更
		lydel2(d.id)
	else
		-- 同レイヤーに別キャラがいた場合の検出
		for nm, v in pairs(scr.img.fg) do
			if ch ~= nm and id == v.id then
				lydel2(v.id)
				break
			end
		end
	end

	----------------------------------------
	-- base設置
	if p.file then
--		lydel2(idx)

		----------------------------------------
		-- 座標mode
		local md   = init.system.fgmode == "csv"
		local head = p.head
		local path = p.path
		local ext  = game.fgext

		----------------------------------------
		-- body
		local file = patch_checkfg() and p.ex05 or p.file
		local px   = path..file..ext
		lyc2{ id=(idx..'.0'), file=(px)}

		-- 立ち位置補正
		local v  = md and fgpos[head]
		local z  = v  and v[file] or getfgfilepos(px)
		local ax = mulpos(p.ax) or z.ax or game.ax
		local ay = mulpos(p.ay) or z.ay or game.ay
		local d  = p.dir
		local rx = (d == "rxy" or d == "rx") and 1		-- 左右反転
		local ry = (d == "rxy" or d == "ry") and 1		-- 上下反転
		tag{"lyprop", id=(idx), left=(xx + z.x), top=(z.y)}
		tag{"lyprop", id=(addImageID(id, 'move')), anchorx=(ax), anchory=(ay), reversex=(rx), reversey=(ry)}
		tag{"lyprop", id=(addImageID(id, 'act' )), anchorx=(ax), anchory=(ay)}
		tag{"lyprop", id=(addImageID(id, 'act2')), anchorx=(ax), anchory=(ay)}

		----------------------------------------
		-- パーツ
		fganime_del(ch)
		for nm, id in pairs(init.fgid) do
			local ex = p[nm]
			local ix = idx..'.'..id
			if nm == "file" or id == "hide" then

			elseif not ex then
				lydel2(ix)

			else
				lydel2(ix)
				local pz = path..ex..ext
				local f  = v and v[ex] or getfgfilepos(pz)

				-- anime
				local a = f.ani
				if init.game_fganime == "on" and a then
					for i, v in ipairs(a) do
						local iz = ix.."."..i
						local al = i == 1 and 255 or 0
						lyc2{ id=(iz), file=(pz), clip=(v), alpha=(al)}
					end
					tag{"lyprop", id=(ix), left=(f.x - z.x), top=(f.y - z.y)}
					fganime_set(ch, id, ix, f)
				else
					lyc2{ id=(ix), file=(pz), x=(f.x - z.x), y=(f.y - z.y), clip=(f.clip)}
				end
			end
		end

		----------------------------------------
		-- 時間帯フィルタ
		shader_colortone(id, p)		-- シェーダー反映
--		if p.lymode then	 setColortone(idx, { mode=(p.lymode), color=(p.color) })
--		elseif scr.tone then setColortone(idx)
--		else				 setTimezone(idx, ch) end		

		-- lymask
		local ms = p.lymask
		if ms then tag{"lyprop", id=(id), intermediate_render="1", intermediate_render_mask=(":mask/"..ms)} end
	end

	----------------------------------------
	-- 表示tween
	image_postween(id, p, "fg_fade", flag)

	----------------------------------------
	-- 保存
	if not flag then
		scr.img.fg[ch] = { id=(id), p=(p) }
	end

	-- trans
	if tn(p.sync) == 1 then
		local tm = p.time or p.fade or init.fg_fade
		trans{ fade=(tm) }
	end
end
----------------------------------------
-- 立ち絵ファイルから座標を取得
function getfgfilepos(px)
	local r = { x=0, y=0 }
	if isFile(px) then
		local p = e:loadPngComments(px)
		local a = p and explode(",", p.comment)
		if p and a[1] == "pos" then
			r.x = tn(a[2])
			r.y = tn(a[3])

			-- anime
			if a[6] then
				local w = a[4]
				local h = a[5]
				local m = a[6]
				local c = 0
				local d = {}
				for i=1, m do
					local cl = "0,"..c..","..w..","..h
					d[i] = cl
					c = c + h + 1
				end

				-- 保存
				r.com  = a[7] or "ani"	-- アニメ動作
				r.clip = d[1]			-- 先頭clip
				r.ani  = d				-- アニメ全clip
			end
		end
	end
	return r
end
----------------------------------------
-- 立ち絵消去
function fgdel(p)
	local sync = tn(p.sync or 0)
	local ch = p.ch
	if scr.img.fg and scr.img.fg[ch] then
		local id = scr.img.fg[ch].id

		-- disp動作
		image_disp(id, p)

		-- delete
--		flip()
		lydel2(id)
		fganime_del(ch)
		scr.img.fg[ch] = nil
		scr.img.mwf[ch] = nil
		faceparamdel(ch)

		-- trans
		if sync == 1 then trans(p) end
	end
end
----------------------------------------
-- 全消去
function fgdelall(p)
	local sync = tn(p and p.sync or 0)
	if scr.img.fg then
		for i, v in pairs(scr.img.fg) do
			local id = v.id 
			if id then
				image_disp(id, p)	-- disp動作
				lydel2(id)			-- 消去
			end
		end
		fganime_del()
		scr.img.fg = {}
		scr.img.mwf = {}
		if sync == 1 then trans(p) end
	end
	scr.face = nil
end
----------------------------------------
-- mw faceパラメータ
function faceparamdel(ch)
	if scr.face then
		if ch then
			scr.face[ch] = nil
--			if ch == "mob" then
---				scr.face["MOB男"] = nil
--				scr.face["MOB女"] = nil
--				scr.face["MOB他"] = nil
--			end	
		else
			scr.face = nil
		end
	end
end
----------------------------------------
-- fgframe / 画面分割
----------------------------------------
-- fgf
function image_fgf(p)
	local sync = tn(p.sync or 0)
	local mode = tn(p.mode or 1)

	-- 立ち絵表示
	if mode >= 1 then
		-- すぐに表示する
		if sync == 1 then
			local time = p.time or init.fg_fade
			pushTag{ fgf, p }
			pushTag{ trans, { fade=time } }
			popTag()

		else
			image_store('fgf', p)
		end

	----------------------------------------
	-- 消去
	elseif mode == -1 then
		if sync == 1 then
			local time = p.time or init.fg_fade
			pushTag{ fgfdel, p }
			pushTag{ trans, { fade=time } }
			popTag()
		else
			image_store('fgfdel', p)
		end
	end
end
----------------------------------------
-- delay fgf
function delay_fgf(p)
	local mode = tn(p.mode or 1)
	if mode >= 1 then fgf(p)
	elseif mode == -1 then fgfdel(p) end
end
----------------------------------------
-- fgf id
function get_fgfid(p)
	local nm = p.frame or "frame_rt"
	local t = csv.fgframe[nm]
	local r = nm
	if t then
		local no  = p.id or t.id or 1
		local md  = t.mode or "normal"
		if md ~= "normal" then r = r..no end
	else
		sysmessage("エラー", nm, "は不明な frame 指定です")
	end
	return nm, r
end
----------------------------------------
-- fgf
function fgf(p)
	local fr, nm = get_fgfid(p)
	local ft = csv.fgframe or {}
	local t  = ft[fr]
	if t then
		local lv  = p.lv or t.lv or 10
		local no  = p.id or t.id or 1
		local md  = t.mode or "normal"					-- bg mode / normal,float,anime
		local id  = getImageID('fgf', { lv=lv, id=no })	-- base id
		local idp = addImageID(id, 'pos')				-- pos id
		local idm = addImageID(id, 'move')				-- move id
		local idx = addImageID(id, 'base')				-- base id

		----------------------------------------
		-- 背景
		local idz = idx..'.0'
		local file = p.bg   or 'frame_bg'
		local path = p.bgpx or p.bg and ":bg/" or ":cg/"
		if file == "frame_bg" then path = ":fgf/" end

		local zm = p.bz
		readImage(idz, { path=(path), file=(file:gsub(":bg/", "")), style=(p.style), dir=(p.dir) })
		tag{"lyprop", id=(idz), left=(mulpos(p.bx)), top=(mulpos(p.by))}
		tag{"lyprop", id=(idz), anchorx=(game.centerx), anchory=(game.centery), xscale=(zm), yscale=(zm)}

		----------------------------------------
		-- cg
		lydel2(idx..".bc")		-- cg奥
		lydel2(idx..".fr")		-- cg手前
		if p.cg then
			local ix = p.cgback == 1 and idx..".bc" or idx..".fr"
			local cx = p.cg
			local px = ":cg/"
			if cx:find("/") then
				local s = ""
				for v in cx:gfind("(.+)/") do s = s..v end
				px = s.."/"
				cx = cx:sub(#px + 1)
			end
			readImage(ix, { path=(px), file=(cx), style=(p.style), dir=(p.dir), movie=(p.movie), loop=(p.loop) })

			-- pos
			local x = mulpos((t.fx or 0) + (p.cgx or 0) + (p.cgbx or 0))
			local y = mulpos((t.fy or 0) + (p.cgy or 0) + (p.cgby or 0))
			tag{"lyprop", id=(ix), left=(x), top=(y)}
		end

		----------------------------------------
		-- mask
		tag{"lyprop", id=(idx), intermediate_render="1", intermediate_render_mask=(':mask/'..p.frame)}

		----------------------------------------
		-- 枠 / maskしない
		local iw = addImageID(id, 'act2')..".n"
		local px = ':fgf/'..fr
		if md == "ogv" then
			local px = ":ani/"..fr..".ogv"
			local mx = t.loop or 1
			tag{"video" , id=(iw), file=(px), loop=(mx)}

		elseif md == "anime" then
			local mx = t.loop or 2
			local tm = t.time or 100
			local w  = t.fx * 2
			local h  = t.fy * 2
			tag{"anime",	 id=(iw), mode="init", file=(px), clip=("0,0,"..w..","..h)}
			for i=1, mx do
				tag{"anime", id=(iw), mode="add",  file=(px), clip=("0,"..(i*h)..","..w..","..h), time=(i * tm)}
			end
			tag{"anime",	 id=(iw), mode="end",  time=(mx * tm)}

		elseif md == "rotate" then
			local tbl = {
				{  360,  -1, nil, "none",  10000 },		-- 
				{ -360,  -1, nil, "none",  10000 },		-- 
				{  360, nil,  -1, "inout", 10000 },		-- 
				{ -360, nil,  -1, "inout", 10000 },		-- 
				{  180, nil,  -1, "inout", 5000  },		-- 
				{ -180, nil,  -1, "inout", 5000  },		-- 
				{   90, nil,  -1, "inout", 5000  },		-- 
				{  -90, nil,  -1, "inout", 5000  },		-- 
			}
			local mx = p.dir  or t.loop or 1
			local v  = tbl[mx] or {}
			local r  = p.r    or v[1] or 360
			local lp = p.loop or v[2] or nil
			local yo = p.yoyo or v[3] or nil
			local es = p.ease or v[4] or "none"
			local tm = p.speed or t.time or v[5] or 5000
			local ax = mulpos(t.fx)
			local ay = mulpos(t.fy)
			lyc2{ id=(iw), file=(px), anchorx=(ax), anchory=(ay) }
			tween{ id=(iw), rotate=("0,"..r), time=(tm), yoyo=(yo), loop=(lp), ease=(es) }

		else
			lyc2{ id=(iw), file=(px) }
		end

		----------------------------------------
		-- pos / 全体
		if md ~= "normal" then
			local x = mulpos((p.basex or 0) + (t.x or 0) - t.fx)	-- xは中央合わせ
			local y = mulpos((p.basey or 0) + (t.y or 0))			-- yは上から
			tag{"lyprop", id=(id), left=(x), top=(y)}
		end
		local ax = mulpos(t.fx)
		local ay = mulpos(t.fy)
		tag{"lyprop", id=(idm), anchorx=(ax), anchory=(ay)}
		tag{"lyprop", id=(addImageID(id, 'act')), anchorx=(ax), anchory=(ay)}

		----------------------------------------
		-- tween
		local v = ft[p.disp or 'none']
		if v then
			local time = getTweenTime(p.time, init.fg_fade)
			if v.x  then tween{id=(idm), x=(mulpos(v.x)..',0'), time=(time) } end
			if v.y  then tween{id=(idm), y=(mulpos(v.y)..',0'), time=(time) } end
			if v.r  then tween{id=(idm), rotate=((v.r)..',0'), time=(time) } end
			if v.z1 then tween{id=(idm), xscale='0,100' , time=(time) } end
			if v.z2 then
				time = math.floor(time / 2)
				tag{"tweenset"}
				tween{id=(idm), yscale='0,5'	 , time=(time) }
				tween{id=(idm), yscale='5,100', time=(time) }
				tag{"/tweenset"}
				tween{id=(idm), xscale='0,100', time=(time) }
			end
		end

		----------------------------------------
		-- 保存
		if not scr.img.fgf then scr.img.fgf = {} end
		local ch = p.ch
		local zn = p.notone == 1 and "0xffffff" or p.zone
		scr.img.fgf[nm] = { id=(id), ch=(ch) }
		if ch then scr.img.fgf[ch] = { id=(id), idx=(idx), fx=(mulpos(t.fx)), zone=(zn) } end

		-- trans
		if sync == 1 then trans(p) end
	end
end
----------------------------------------
-- fgfdel
function fgfdel(p)
	if not scr.img.fgf then scr.img.fgf = {} end
	local fr, nm = get_fgfid(p)
	local ft = csv.fgframe or {}
	local s  = scr.img.fgf or {}
	local t  = ft[fr]
	if t and s[nm] then
		local id  = s[nm].id							-- id
		local idm = addImageID(id, 'move')				-- move id
		local time = getTweenTime(p.time, init.fg_fade)

		-- tween
		local v = ft[p.disp or 'none']
		if v then
--			tag{"lyprop", id=(idm), anchorx=(mulpos(t.fx)), anchory=(mulpos(t.fy))}
			if v.x  then tween{id=(idm), x=('0,'..mulpos(v.x)), time=(time) } end
			if v.y  then tween{id=(idm), y=('0,'..mulpos(v.y)), time=(time) } end
			if v.r  then tween{id=(idm), rotate=('0,'..(v.r)), time=(time) } end
			if v.z1 then tween{id=(idm), xscale='100,0' , time=(time) } end
			if v.z2 then
				local t2 = math.floor(time / 2)
				tag{"tweenset"}
				tween{id=(idm), yscale='100,5',	time=(t2) }
				tween{id=(idm), yscale='5,0',	time=(t2) }
				tag{"/tweenset"}
				tween{id=(idm), xscale='100,0', time=(t2), delay=(t2) }
			end
		end

		-- 保存
		local ch = s[nm].ch
		if ch then
			local z = scr.img or {}
			fganime_del(ch)
			if z.mwf then scr.img.mwf[ch] = nil end
			if z.fg  then scr.img.fg[ch]  = nil end
			scr.img.fgf[ch] = nil
		end
		scr.img.fgf[nm] = nil

		lydel2(id)
	else
		sysmessage("エラー", fr, "は設置されていない frame です")
	end
end
----------------------------------------
-- frame action
function tag_fgfact(p)
	local sync = tn(p.sync or 0)
	if sync == 1 then fgfact(p)			-- すぐに実行する
	else image_store('fgfact', p) end	-- スタック
end
----------------------------------------
function fgfact(p)
	if not scr.img.fgf then scr.img.fgf = {} end
	local fr, nm = get_fgfid(p)
	local s  = scr.img.fgf or {}
	if s[nm] then
		local ft = csv.fgframe or {}
		local t  = ft[fr]
		local v  = tcopy(p)
		v.lv = p.lv or t.lv or 10
		v.no = p.id or t.id or 1
		image_act(s[nm].id, v)
	else
		sysmessage("エラー", fr, "は設置されていない frame です")
	end
end
----------------------------------------
-- 立ち絵アニメ
----------------------------------------
function fganime_vsync()
	local tm = init.game_fganime_time	-- アニメーション間隔
	local wa = init.game_fganime_wait	-- アニメーション時間

	----------------------------------------
	local sw = {

	-- 往復ani
	ani = function(ch, p)
		local mx = p.max
		local n1 = p.now or 0
		local n2 = e:now()
		local oc = p.count
		local c  = (oc or mx) + 1
		local f  = nil
		if c > mx and n1 <= n2 then
			f = tm + e:random() % tm + e:now()
			c = 1
		elseif n1 <= n2 then
			f = wa + e:now()
		end

		-- 更新
		if f then
			scr.fgani[ch].count = c
			scr.fgani[ch].now   = f
			for no, id in pairs(p.id) do
				local ix = id.."."
				local t  = p.t
				local c1 = oc and t[oc]
				local c2 = t[c]
				if not oc then
					tag{"lytween", id=(ix..c2), param="alpha", time="0", from="254", to="255"}
				elseif c1 ~= c2 then
					tag{"lytween", id=(ix..c1), param="alpha", time="0", from="1"  , to="0"  }
					tag{"lytween", id=(ix..c2), param="alpha", time="0", from="254", to="255"}
				end
			end
		end
	end
	}

	----------------------------------------
	local a = scr.fgani
	if a then
		for ch, v in pairs(a) do
			local cm = v.com
			if sw[cm] then sw[cm](ch, v) end
		end
	end
end
----------------------------------------
function fganime_set(ch, no, id, p)
	if init.game_fganime == "on" then
		if not scr.fgani then scr.fgani = {} end
		if not scr.fgani[ch] then
			scr.fgani[ch] = { id={} }
		end

		-- 算出
		local t  = {}
		local cm = p.com			-- アニメ動作
		local mx = #p.ani			-- アニメ枚数
		for i=1, mx do table.insert(t, i) end

		-- ani(往復)
		if cm == "ani" then
			for i=mx-1, 1, -1 do table.insert(t, i) end
		end
		scr.fgani[ch].id[no]= id	-- id
		scr.fgani[ch].com 	= cm	-- command
		scr.fgani[ch].max 	= #t	-- アニメ枚数
		scr.fgani[ch].t   	= t		-- アニメ順番
	end
end
----------------------------------------
function fganime_del(ch)
	if init.game_fganime == "on" and scr.fgani then
		if ch then
			scr.fgani[ch] = nil
		else
			scr.fgani = nil
		end
	end
end
----------------------------------------
-- 立ち絵アクション
----------------------------------------
-- 
function tag_fgact(p)
	local sn = tn(p.sync or 0)
	local ic = p.act

	-- すぐに実行する
	if sn == 1 then
		fgact(p)

	-- icon
	elseif ic == "icon" then
		if scr.img.buff then
			estag("init")
			estag{"image_loop"}		-- 先に画像を表示してしまう
			estag{"fgact", p}
			estag()
		else
			fgact(p)
		end

	-- スタック
	else
		image_store('fgact', p)
	end
end
----------------------------------------
function fgact(p)
	if not scr.img.fg then scr.img.fg = {} end
	local ch = p.ch or ""
	local v  = scr.img.fg[ch]
	if v then image_act(v.id, p) end
end
----------------------------------------
-- face
----------------------------------------
function mwf(p)
	-- 消去
	if p.del then
--		mw_facedel()
		scr.faceflag = "del"

	-- 表示
	else
		local ch = p.ch
		if ch then
			if not scr.face then scr.face = {} end
			scr.face[ch] = p
			scr.faceflag = ch
		end
	end
end
----------------------------------------
-- 音声のあるキャラのみmwに出す
function faceview(p)
	local ch = scr.faceflag or getNameChar(p)
	local v  = scr.face and scr.face[ch] or {}
	local nm = scr.faceflag or v.mw and ch or p.vo and p.vo[1] and p.vo[1].ch
	if nm == "del" then
		mw_facedel()

	-- floatでは表示しない
	elseif nm and not getFloatFlag() then 
		-- 表示
		if v then
			mw_face(v)
			scr.mwface = nm
		end

	-- 枠
	elseif scr.mwframe then
--		tag{"lyprop", id=(game.mwid..".mw.bb"), alpha="0"}
	end
	scr.faceflag = nil
end
----------------------------------------
-- MW face
function mw_face(p)
	local id = getMWID("face")
	lydel2(id)
	scr.mwfropen = nil

	----------------------------------------
	-- mwface 0:off 1:on 2:立ち絵があればoff
	local mw = init.mwface == "on" and true
	local c  = conf.mwface or 1
	if c == 0 then
		mw = nil
	else
		-- 立ち絵が出てるときにmwfaceを出さない判定
		local s  = scr.img.mwf or {}
		local ch = p.ch
		if ch and s[ch] == 3 and c == 2 then mw = nil end
	end

	----------------------------------------
	-- 表示
	local mode = p.mode
	if mw and (mode == 1 or mode == 3) then
		local v = getMWFaceFile(p)
		setMWFaceFile(v, "face", id)
		scr.mwfropen = true

		-- 枠
		local w = scr.mwno or 1
		if w == 1 and scr.mwframe then
			local i1 = game.mwid..".mw.bb"
			tag{"lyprop", id=(i1), alpha="255"}
			if flg.exmsgon then
				local tm = init.mw_hidetime
				local v  = getBtnInfo("face01")
				tag{"lytweendel", id=(i1)}
				tween{ id=(i1), x=(-v.w..",0"), time=(tm) }
				flg.exmsgon = nil
			end
		end
	end
end
----------------------------------------
-- MW face 消去
function mw_facedel()
	if scr.mwface then
		local id = getMWID("face")
		if id then lydel2(id) end
		scr.mwface = nil
		scr.mwfropen = nil

		-- 枠
		if scr.mwframe then
			tag{"lyprop", id=(game.mwid..".mw.bb"), alpha="0"}
		end
	end
end
----------------------------------------
-- ファイル名を変換して返す
function getMWFaceFile(p, flag)
	local tbl  = init.fgid
	local file = (patch_checkfg() and p.ex05 or p.file):gsub("_[bnz][co12]", "_no")
	local head = file:sub(1, 7)
--	local head = file:gsub("_no", "_fa"):sub(1, 7) if p.head == "mob" then head = "mob" end
	local path = p.path:gsub(":fg", ":fa"):gsub("/[bnz][co12]/", "/fa/")
	local z    = md and fgpos[head]
	local r    = { path=(path) }
	for nm, id in pairs(tbl) do
		local fl = nm == "file" and file or p[nm]
		if fl then
			r[nm] = { file=(fl), id=(id) }
			if not flag then
				local v = z and z[fl] or {}
				if v then
					r[nm].x = v.x
					r[nm].y = v.y
				end
			end
		end
	end
	return r
end
----------------------------------------
-- 変換したファイルから描画
function setMWFaceFile(p, nm, id)
	if not p or not p.file then return end
	local md   = init.system.fgmode == "csv"
	local idb  = id..".0"
	local path = p.path
	local head = md and (p.file.file:sub(1, 7)):gsub("_[bnz][co12]", "_fa")
	local z    = md and fgpos[head]
	local ext  = game.fgext
	local mw   = csv.mw[nm]
	local addx = mw.clip_a or 0
	local addy = mw.clip_c or 0
	for fl, v in pairs(p) do
		if fl ~= "path" then
			local idx = idb.."."..v.id
			local fx  = v.file
			local px  = path..fx..ext
			local n   = md and z[fx] or getfgfilepos(px)
			local x   = n.x + addx
			local y   = n.y + addy
			lyc2{ id=(idx), file=(px), x=(x), y=(y)}
		end
	end

	----------------------------------------
	-- 合成とmask
	----------------------------------------

	-- ui / mwface
	if nm then
		local c = mw.clip	-- clip
		local z = mw.zoom	-- zoom
		if nm == "face" then
			local m = get_uipath().."mw/maskface.png"
			local f = flg.mwfacemask
			if not f then
				if isFile(m) then f = true else f = "none" end
				flg.mwfacemask = f
			end
			if f == "none" then
				tag{"lyprop", id=(id), left=(mw.x), top=(mw.y)}
			else
				tag{"lyprop", id=(id), left=(mw.x), top=(mw.y), intermediate_render="1", intermediate_render_mask=(m)}
			end

			-- faceにも色調を使用する
--			if init.game_mwtone == "on" then setColortone(idb) end
			if init.game_mwtone == "on" then shader_colortone(idb, p) end		-- シェーダー反映
		else
			local r = c and 1
			tag{"lyprop", id=(id), left=(mw.x), top=(mw.y), clip=(c), intermediate_render=(r)}				-- clipがない場合は中間合成しない
		end
		tag{"lyprop", id=(idb), intermediate_render="1", anchorx="0", anchory="0", xscale=(z), yscale=(z)}	-- ここの中間合成は必須
	end
end
----------------------------------------
-- ボイスを取得して立ち絵の表情を返す
function getBlogFace()
	local r = nil
	local v = scr.face
	if not v or init.game_backlogface ~= "on" then return r end

	-- text blockから名前を取り出す
	local b  = scr.ip.block
	local t  = ast[b].text
	local nm = getNameChar(t)		-- 話者名
	if nm and v[nm] then
		r = getMWFaceFile(v[nm])
	end
	return r
end
----------------------------------------
-- 裸立ち絵ルーチン
function fg_hadaka_img(ch, pr)
	local p = pr and pr.p
	fg(p, true)
end
----------------------------------------
-- 裸立ち絵ルーチン / mwface
function fg_hadaka_mwface()
	-- 条件を満たしていない場合MWは書き換えない
	local f = scr.mw.msg	-- MW
	local s = scr.select	-- 選択肢
	if s and (s.hide or s.mwsys) then f = nil end
	if f then
		local t  = getTextBlock()
		faceview(t)
	end
end
----------------------------------------
