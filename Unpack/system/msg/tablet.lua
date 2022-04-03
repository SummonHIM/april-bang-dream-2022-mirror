----------------------------------------
-- タブレットUI
----------------------------------------
local ostable = {
	windows	= true,
	android = true,
	ios		= true,
--	switch	= true,
	wasm    = true,
}
----------------------------------------
-- 初期化
function tab_reset()
	gscr.tablet = {}
	local v = lang.ui_adv or lang.ui_adv01
	local p = v and v.tblt
	local b = p and (tn(p.p3) or (p.x + p.w)) or 36
	local w = game.width
	local x = w - b
	local y = 0
	local z = init.tablet_zoom
	local a = init.tablet_alpha
	gscr.tablet.w = p and p.w or w
	gscr.tablet.x = x
	gscr.tablet.y = y
	gscr.tablet.z = z
	gscr.tablet.a = a
	gscr.tablet.b = b
end
----------------------------------------
-- 
function tabletCheck(nm)
	return nm == "ui" and getTabletID("check") and conf.tabletui == 1
end
----------------------------------------
-- mw check
function mw_tablet()
	local id = getTabletID()
	if not id then

	elseif not tabletCheck("ui") then
		tag{"lyprop", id=(id), visible="0"}
		tag{"lyprop", id=(getBtnID("tb_mask")), visible="0"}
	else
		if not gscr.tablet then tab_reset() end

		-- zoom
		local g  = gscr.tablet
		local p  = getTabletPos("zoom")
		local al = repercent(g.a, 255)
		local zm = g.z * 2
		local x  = g.x
		local y  = g.y
		tag{"lyprop", id=(id), left=(x), top=(y), anchorx=(p.ax), anchory=(p.ay), xscale=(zm), yscale=(zm), alpha=(al), visible="1"}

		-- BG alpha
--		local p  = getTabletPos()
		local bx = p.w - g.b
		local ix = getBtnID("tb_bg")
		local al = 255	-- (x > 0 and bx <= x or x < 0 and -bx >= x) and 0 or 255
		tag{"lyprop", id=(ix), alpha=(al)}
		gscr.tablet.bga = al

		-- drag
		local id = getBtnID("tb_mask")
		local al = 0
		tag{"lyprop", id=(id), left=(x), top=(y), anchorx=(p.ax), anchory=(p.ay), xscale=(zm), yscale=(zm), alpha=(al), visible="1"}
		tag{"lyprop", id=(id), draggable="1", clickablethreshold="128"}

		-- lock
		if init.tablet_uilock ~= "on" then
			lyevent{ id=(id), name="tablet", key=(1), drag="tab_drag", dragin="tab_dragin", dragout="tab_dragout", over="tab_over", out="tab_out" }
		end
	end
end
----------------------------------------
-- id取得
function getTabletID(nm)
	local r = nil
	if ostable[game.os] then
		r = init.mwtabid
		if r and nm then r = r.."."..nm end
	end
	return r
end
----------------------------------------
-- pos取得
function getTabletPos(cm)
	local id = getBtnID("tb_mask")
	tag{"var", name="t.ly", system="get_layer_info", id=(id), style="map"}
	local p  = {
		x  = tn(e:var("t.ly.left")),	-- 左上座標
		y  = tn(e:var("t.ly.top")),		-- 
		w  = tn(e:var("t.ly.width")),	-- 幅
		h  = tn(e:var("t.ly.height")),	-- 高さ
	}
	p.ax = math.floor(p.w / 2)			-- 中心
	p.ay = math.floor(p.h / 2)

	-- zoom計算をする
	if cm then
		local g  = gscr.tablet
		local zm = g.z * 0.02
		p.zx = math.floor(p.ax * zm) - p.ax		-- 左上のはみ出し量
		p.zy = math.floor(p.ay * zm) - p.ay
		p.zw = math.floor(p.w * zm)				-- zoom後のサイズ
		p.zh = math.floor(p.h * zm)
	end
	return p
end
----------------------------------------
-- 
----------------------------------------
function tab_left()
	local g  = gscr.tablet
	local p  = getTabletPos("zoom")
	local id = getTabletID()
	local ix = getBtnID("tb_mask")
	local ia = getBtnID("tb_bg")
	local tm = init.tablet_movetime
	local zm = g.z * 0.02
	local bx = p.w - g.b
	local x  = p.x
	tag{"lytweendel", id=(id)}
	tag{"lytweendel", id=(ix)}
	tag{"lytweendel", id=(ia)}

	-- 等倍
	if zm == 1 then
		local x2 = x > 0 and 0 or -bx
		systween{ id=(id), x=(x..","..x2), time=(tm) }
		systween{ id=(ix), x=(x..","..x2), time=(tm) }
		gscr.tablet.x = x2
--[[
		-- BG alpha
		local al = g.bga
		if al == 0 and x >= bx then
			systween{ id=(ia), alpha="0,255", time="0" }
			gscr.tablet.bga = 255
		elseif al == 255 and x2 <= -bx then
			systween{ id=(ia), alpha="255,0", time=(tm) }
			gscr.tablet.bga = 0
		end
]]

	-- 大きい
	elseif zm > 1 then
		local n1 = p.zx
		local x2 = x > n1 and n1 or -n1
		systween{ id=(id), x=(x..","..x2), time=(tm) }
		systween{ id=(ix), x=(x..","..x2), time=(tm) }
		gscr.tablet.x = x2

	-- 小さい
	else
		local n1 = -p.zx
		local n2 = p.zx
		local n3 = math.floor((p.zw - p.zx) - g.b * zm)
		local x2 = x > n1 and n1 or x > n2 and n2 or -n3
		systween{ id=(id), x=(x..","..x2), time=(tm) }
		systween{ id=(ix), x=(x..","..x2), time=(tm) }
		gscr.tablet.x = x2
	end

	-- wait
	tab_scrollinit()
	estag("init")
	estag{"wait", time=(tm), input="0"}		-- 必ずエンジンのwaitを使用
	estag{"tab_scrollexit", {id,ix}}
	estag()
end
----------------------------------------
function tab_right()
	local g  = gscr.tablet
	local p  = getTabletPos("zoom")
	local id = getTabletID()
	local ix = getBtnID("tb_mask")
	local ia = getBtnID("tb_bg")
	local tm = init.tablet_movetime
	local zm = g.z * 0.02
	local bx = p.w - g.b
	local x  = p.x
	tag{"lytweendel", id=(id)}
	tag{"lytweendel", id=(ix)}
	tag{"lytweendel", id=(ia)}

	-- 等倍
	if zm == 1 then
		local x2 = x < 0 and 0 or bx
		systween{ id=(id), x=(x..","..x2), time=(tm) }
		systween{ id=(ix), x=(x..","..x2), time=(tm) }
		gscr.tablet.x = x2
--[[
		-- BG alpha
		local al = g.bga
		if al == 0 and x <= -bx then
			systween{ id=(ia), alpha="0,255", time="0" }
			gscr.tablet.bga = 255
		elseif al == 255 and x2 >= bx then
			systween{ id=(ia), alpha="255,0", time=(tm) }
			gscr.tablet.bga = 0
		end
]]

	-- 大きい
	elseif zm > 1 then
		local n1 = p.zx
		local x2 = x < -n1 and -n1 or n1
		systween{ id=(id), x=(x..","..x2), time=(tm) }
		systween{ id=(ix), x=(x..","..x2), time=(tm) }
		gscr.tablet.x = x2

	-- 小さい
	else
		local n1 = p.zx
		local n2 = -p.zx
		local n3 = math.floor((p.zw - p.zx) - g.b * zm)
		local x2 = x < n1 and n1 or x < n2 and n2 or n3
		systween{ id=(id), x=(x..","..x2), time=(tm) }
		systween{ id=(ix), x=(x..","..x2), time=(tm) }
		gscr.tablet.x = x2
	end

	-- wait
	tab_scrollinit()
	estag("init")
	estag{"wait", time=(tm), input="0"}		-- 必ずエンジンのwaitを使用
	estag{"tab_scrollexit",  {id, ix}}
	estag()
end
----------------------------------------
function tab_scrollinit()
	local bt = btn.cursor
	if bt then btn_nonactive(bt) end
	if game.os == "windows" then
		flg.nonactive = true		-- active se抑制
	end
end
----------------------------------------
function tab_scrollexit(p)
	if game.os == "windows" then
		tag{"lytweendel", id=(p[1])}
		tag{"lytweendel", id=(p[2])}
		flg.nonactive = nil
	end
	asyssave()
end
----------------------------------------
-- 
----------------------------------------
function tab_over()
	if flg.advdragin then flg.advdrag = true end
end
----------------------------------------
function tab_out()  flg.advdrag = nil end
----------------------------------------
function tab_drag()
	if get_gamemode('ui2', "tb_mask") then
		local p  = getTabletPos()
		local id = getTabletID()
		tag{"lyprop", id=(id), left=(p.x), top=(p.y)}
		flip()
	end
end
----------------------------------------
function tab_dragin()
	if get_gamemode('ui2', "tb_mask") then
		flg.nonactive = true
		flg.advdragin = true

		-- BG alpha
		local g  = gscr.tablet
		if g.bga == 0 then
			local id = getBtnID("tb_bg")
			tag{"lytweendel", id=(id)}
			tag{"lyprop", id=(id), alpha="255"}
			gscr.tablet.bga = 255
			flip()
		end
	end
end
----------------------------------------
function tab_dragout(e, p)
	flg.advdrag = nil
	flg.advdragin = nil
	flg.nonactive = nil
	flg.advdragstop = true
	if get_gamemode('ui2', "tb_mask", true) then
		tab_drag()
		local g  = gscr.tablet
		local p  = getTabletPos("zoom")
		local id = getTabletID()
		local ix = getBtnID("tb_mask")
		local ia = getBtnID("tb_bg")
		local tm = init.tablet_movetime
		local zm = g.z * 0.02
		local x  = p.x
		local y  = p.y
		tag{"lytweendel", id=(id)}
		tag{"lytweendel", id=(ix)}
		tag{"lytweendel", id=(ia)}
	
		-- 上下にはみ出た
		local ad = init.tablet_adarea or 0		-- 吸着範囲
		local n1 = p.zy
		local n2 = game.height - p.zy - p.h
		if y < n1 + ad or y > n2 - ad then
			local y2 = y < n1 + ad and n1 or n2
			systween{ id=(id), y=(y..","..y2), time=(tm) }
			systween{ id=(ix), y=(y..","..y2), time=(tm) }
			y = y2
		end

		-- 左右にはみ出た / 拡縮前のサイズで座標が返ってくる
		local ax = p.ax - math.floor(zm * p.ax)		-- 補正
		local zw = p.w - g.b						-- ハミダシ判定サイズ
		local zx = p.w - math.floor(zm * g.b) - ax	-- はみ出し後座標
		local xx = x - (-ax)						-- 拡縮後補正
		if xx < 0 then
			zw = -zw	-- 正負反転
			zx = -zx
		end

		local mw = zw * zm
		local lt = xx < 0 and xx < mw + ad	-- 左側(倍率をかけて判定)
		local rt = xx > 0 and xx > zw - ad	-- 右側(等倍で判定)
		if lt or rt then
			systween{ id=(ix), x=(x..","..zx), time=(tm) }
			systween{ id=(id), x=(x..","..zx), time=(tm) }
--			systween{ id=(ia), alpha="255,0" , time=(tm) }
--			gscr.tablet.bga = 0
			x = zx
		end

		gscr.tablet.x = x
		gscr.tablet.y = y
		asyssave()
	else
		tag{"lyprop", id=(p.id), left=(gscr.tablet.x), top=(gscr.tablet.y)}
		flip()
	end
end
----------------------------------------
-- tablet ui
----------------------------------------
function tab_menu() open_ui('tbui') end
----------------------------------------
function tbui_init()
	message("通知", "タブレット設定を開きました", a, z)
	if not gscr.tablet then tab_reset() end

--	ui_message("500.tx.1", {"tbnum", x=760, y=405 })
--	ui_message("500.tx.2", {"tbnum", x=760, y=462 })

	tbui_init2()
	uiopenanime("tablet")
end
----------------------------------------
function tbui_init2()
	local g = gscr.tablet
	local a = percent(g.a - 25, 75)
	local z = percent(g.z - 25, 75)
	sys.tbui = { alpha=(a), zoom=(z) }

	csvbtn3("tbui", "500", lang.ui_tablet)

	local p  = getBtnInfo("sample")
	local ax = math.floor(p.w / 2)
	local ay = math.floor(p.h / 2)
	local id = p.idx
	tag{"lyprop", id=(id), anchorx=(ax), anchory=(ay)}
	tbui_sample()

	set_uihelp("500.tx.help", "tbhelp")
end
----------------------------------------
function tbui_reset()
	del_uihelp()			-- ui help
--	ui_message("500.tx.1")
--	ui_message("500.tx.2")
	delbtn('tbui')			-- 削除
	sys.tbui = nil			-- ダミークリア

	-- はみ出し確認
	if flg.tabreset then
		local id = getTabletID()
		local v  = lang.ui_adv or lang.ui_adv01
		local g  = gscr.tablet
		local zm = g.z * 0.02

		-- 右側 50%:940,-30 1830x60
		local p  = v.tblt
		local ax = game.ax
		local x  = math.floor(ax + (ax - p.p3) * zm)

		-- 上側
		local p  = v.tb_bg
		local hh = p.h / 2
		local y  = math.floor(hh * zm - hh)

		-- save
		gscr.tablet.x = x
		gscr.tablet.y = y
	end
	flg.tabreset = nil
end
----------------------------------------
function tbui_close()
	message("通知", "タブレット設定を閉じました")
	se_cancel()

--	uicloseanime("tablet")
	estag("init")
	estag{"tbui_reset"}
	estag{"uitrans"}
	estag{"asyssave"}
	estag()
end
----------------------------------------
-- 
----------------------------------------
-- 初期値に戻す
function tbui_def()
	se_ok()
	tab_reset()
	tbui_init2()
	flip()
	flg.tabreset = true
end
----------------------------------------
--
function tbui_alpha(e, p)
	local n = repercent(p.p, 75) + 25
	gscr.tablet.a = n
	tbui_sample()
	flip()
end
----------------------------------------
--
function tbui_zoom(e, p)
	local n = repercent(p.p, 75) + 25
	gscr.tablet.z = n
	tbui_sample()
	flip()
end
----------------------------------------
--
function tbui_sample()
	local g  = gscr.tablet
	local al = repercent(g.a, 255)
	local zm = g.z * 2
	local id = getBtnID("sample")
	tag{"lyprop", id=(id), alpha=(al), xscale=(zm), yscale=(zm)}

--	ui_message("500.tx.1", g.z)
--	ui_message("500.tx.2", g.a)
end
----------------------------------------
function tab_dummy(e, p)
--	message("通知", "何も機能が割り当てられていません")
end
----------------------------------------
