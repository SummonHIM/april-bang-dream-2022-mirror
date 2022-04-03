---------------------------------------
-- ボタン制御 / Ver.3
----------------------------------------
btn = nil
----------------------------------------
-- ■ボタン処理
----------------------------------------
-- csvからボタンを生成する
function csvbtn3(name, defid, param)
	if not param then message("警告", "ボタンID", name, "が登録されていません") end
	local id = defid.."."
	local ps = get_psswap()		-- PS enter 0:○ 1:×
	local fpath	= param[1] ~= "" and param[1] or game.path.ui

	-- スタック／初期化
	if not btn then btn = {} end
--	if not scr.btnfunc then scr.btnfunc = {} end
	btn[name] = { id=(id), p=(param), dis={}, key={} }
	btn.name = name
	btn.cursor = nil
	btn.group  = nil
--	btn.renew  = nil	-- 更新フラグ

	-- uiの初期化
	if name ~= "adv" then lydel2(defid) end

	----------------------------------------
	-- ボタン画像個別設定
	local sw = {
		-- x slider
		xslider = function(ix, p)
			local x = repercent(loadBtnData(p.def), p.w - p.p2)	-- スライダーの初期値 0-100
			lyc2{ id=(ix..'.10'), x=(x), file=(fpath..p.p1), draggable="1", dragarea=(p.area)}
			lyevent{ id=(ix..".10"), name=(name), key=(p.name), drag="slider_dragX", dragin="slider_dragin", dragout="slider_dragout"}
		end,

		-- y slider
		yslider = function(ix, p)
			local y = repercent(loadBtnData(p.def), p.h - p.p2)	-- スライダーの初期値 0-100
			lyc2{ id=(ix..'.10'), y=(y), file=(fpath..p.p1), draggable="1", dragarea=(p.area)}
			lyevent{ id=(ix..".10"), name=(name), key=(p.name), drag="slider_dragY", dragin="slider_dragin", dragout="slider_dragout"}
		end,

		-- checkbox
		check = function(ix, p)
--			local n = p.def and (name == 'conf' and conf[p.def] or sys[name] and sys[name][p.def] or 0)
			local n = loadBtnData(p.def)
			local f = tn(p.p1) or 0
			lyc2{ id=(ix..'.2'), file=(fpath..p.file), clip=(p.clip_c)}
			if n == f then
--				e:tag{"lyprop", id=(ix..".0"), clip=(p.clip_c)}
				e:tag{"lyprop", id=(ix..".2"), visible="0"}
			end
		end,

		-- トグル
		toggle = function(ix, p)
			local cf = p.def
			local p1 = tn(p.p1)
			local tg = loadBtnData(cf)
			if tg and tg == p1 then
				e:tag{"lyprop", id=(ix..".0"), clip=(p.clip_c)}
				setBtnStat(p.name, cf)	-- disable
			end
		end,
	}

	----------------------------------------
	-- ボタン画像共通設定
	local button = function(p, ex, f)
		local ix = id..p.id
		local px = fpath..p.file
		if p.clip then
			local fx = tn(p.flag)
			local cd = fx and fx >= 0 and fx
			lyc2{ id=(ix..'.0'), file=(px..ex), alpha="255", clip=(p["clip"..ex]), clickablethreshold=(cd)}
		else
			local c1,c2,c3 = 255,0,0
			if ex == '_c' then c1,c3 = 0,255 elseif ex == '_a' then c1,c2 = 0,255 end
			lyc2{ id=(ix..'.0'), file=(px      ), alpha=(c1)}
			lyc2{ id=(ix..'.1'), file=(px..'_a'), alpha=(c2)}
			if f then
			lyc2{ id=(ix..'.2'), file=(px..'_c'), alpha=(c3)}
			end
		end
		local cm = p.com
		if sw[cm] then sw[cm](ix, p) end				-- 個別のボタン設定を呼び出す
		e:tag{"lyprop", id=(ix), left=(p.x), top=(p.y)}
	end

	----------------------------------------
	-- csvを展開
	for k, p in pairs(param) do
		local fl = type(p) == "table"
		local cm = fl and p.com
		local ix = fl and p.id and id..p.id
		local px = fl and p.file and fpath..p.file
		if type(k) == 'string' and cm ~= 'work' then
			-- 画像設置
			local grph = {
				-- オブジェクト
				obj  = function(id)	lyc2{ id=(ix), file=(px), x=(p.x), y=(p.y), clip=(p.clip) } end,
				obj2 = function(id)	lyc2{ id=(ix), file=(px), x=(p.x), y=(p.y), clip=(p.clip), anchorx="0", xscale=(p.w.."00")} end,
				obj3 = function(id)	lyc2{ id=(ix), file=(px), x=(p.x), y=(p.y), clip=(p.clip), anchorx="0", anchory="0", xscale=(p.w.."00"), yscale=(p.h.."00")} end,
				objb = function(id)
					lyc2{ id=(ix..".0"), file=(px), clip=(p.clip) }
					tag{"lyprop", id=(ix), left=(p.x), top=(p.y) }
				end,
				objps = function(id)
					local fl = ps and px.."_x" or px
					lyc2{ id=(ix..".0"), file=(fl), x=(p.x), y=(p.y), clip=(p.clip) }
				end,

				-- box
				box = function(id)	lyc2{ id=(ix), width=(p.w), height=(p.h), color=("0"..p.p1), x=(p.x), y=(p.y)} end,

				-- move
				move = function(id)
					local x  = p.p1
					local y  = p.p2
					local al = p.flag
					local ov = p.over
					local ot = p.out
					lyc2{ id=(ix..".-1.1"), file=(px), x=(p.x), y=(p.y), clip=(p.clip) }
					tag{"lyprop", id=(ix), left=(x), top=(y)}
					if p.p3 then
						lyc2{ id=(ix..".-1.0"), file=(fpath..p.p3), x=(p.x), y=(p.y), alpha="0", clickablethreshold=(al)}
						if ov or ot then lyevent{ base=(ix), id=(ix..".-1.0"), over=(ov), out=(ot), name=(name), x=(x), y=(y)} end
					else
						if al then tag{"lyprop", id=(ix..".-1.1"), clickablethreshold=(al)} end
						if ov or ot then lyevent{ base=(ix), id=(ix..".-1.1"), over=(ov), out=(ot), name=(name), x=(x), y=(y)} end
					end
				end,

				-- key / 何もしない
				key = function() end
			}
			if grph[cm] then grph[cm](id)
			else
				-- ボタン
				button(p, '')
				if cm == "mark" then
					lyevent{ id=(ix..'.0'), click="btn_click", name=(name), key=(k)}
				else
					local sl = p.p3 == "se_silent" and 1	-- アクティブ音なし簡易設定
					lyevent{ id=(ix..'.0'), click="btn_click", over="btn_over", out="btn_out", name=(name), key=(k), se=(sl)}
				end
			end

			-- キーの登録
			local ky = p.key
			if ky then
--			if p.key and cm:sub(1, 3) ~= "obj" then
				local rep = p.file == 'repeat'		-- リピート
				btn[name].key[ky] = { name=(p.name), exec=(p.exec), rep=(rep) }	-- キー名に状態を保存
			end
		end
	end

	----------------------------------------
	-- single check / 他のボタンに影響を与えるので最後に処理する
	for k, p in pairs(param) do
		if type(p) == "table" and p.com == 'single' then setBtnStat(k, "single") end
	end

	-- 座標補正
	if game.crop and tn(defid) == 500 then
		tag{"lyprop", id=(defid), top=(game.crop)}
	end

	-- キー再設定
	if name ~= 'adv' then setonpush_ui() end
end
----------------------------------------
-- ボタン自動active
function button_autoactive()
	local tb = { btn=1, check=1, toggle=1, xslider=1, yslider=1 }
	local nm = btn.name
	local p  = btn[nm]
	if game.os == "windows" and p then
		local m = e:getMousePoint()
		local x = m.x
		local y = m.y
		local b  = {}	-- ボタン名を格納しておく
		local z  = {}	-- ボタン名にidを割り当て
		for k, v in pairs(p.p) do
			local cm = type(v) == 'table' and v.com
			if cm and tb[cm] and not p.dis[k] then
				local w = v.w + v.x
				local h = v.h + v.y
				if x > v.x and y > v.y and x < w and y < h then
					table.insert(b, k)
					z[k] = v.id
				end
			end
		end

		-- ボタン数を見る
		local nm = b[1]		-- ひとつめのボタン名を入れておく
		local mx = #b
		if mx == 1 then
			btn_active2(nm)
			flip()
		elseif mx > 1 then
			local ix = ""
			for bt, id in pairs(z) do
				if ix < id then
					nm = bt		-- ボタン名更新
					ix = id		-- 手前のidを保存
				end
			end
			btn_active2(nm)
			flip()
		end
	end
end
----------------------------------------
-- ボタン処理終了
function delbtn(name, p)
	if btn[name] then
		-- scr.btnfuncから削除しておく
		if scr.btnfunc then
			for n, v in pairs(btn[name].p) do
				scr.btnfunc[name.."|"..n] = nil
			end
		end

		-- 消す
		local id = p or btn[name].id:sub(1, -2)
		lydel2(id)
		btn[name] = nil
	else
		error_message(name..'は登録されていませんでした')
		e:tag{"lydel", id="500"}
	end
	btn.name  = nil
	btn.group = nil
	btn.rep   = nil
	btn.cursor= nil

	-- configセーブフラグ
	local tbl = { csub=1, dlg=1 }
	if not tbl[name] then btn.renew = nil end

	-- カーソルキーを元に戻す
	delonpush_ui()
end
----------------------------------------
-- 
----------------------------------------
-- click
function btn_clickex(e, p)
	local bt = btn and btn.cursor
	local ky = p.key
	flg.btnclick = ky
	if bt and bt ~= ky then
		btn_out( e, { key=bt })
		btn_over(e, { key=ky })
	end
end
----------------------------------------
-- click
function btn_click(e, param)
--	local nm = param.key or btn.cursor
	local nm = btn.cursor
	if nm and get_gamemode('ui2', nm) then
		if param.click then
			----------------------------------------
			-- 無効なボタンなら何もしない
			if getBtnStat(nm) then return end

			----------------------------------------
			-- 押されたボタンをアクティブ色にする
			-- out
			if btn.cursor then
				local id = getBtnID(btn.cursor)..".0"
				btn_out(e, { id=(id), key=(btn.cursor) })
			end
			-- over
			param.se = true
			btn.cursor = nm
			btn_over(e, param)
		end

		----------------------------------------
		-- ボタン実行
		local p = getBtnInfo(btn.cursor)
		if p.exec then
			call_lua(param, p.exec)
		else
			-- ボタンを自動的に判別する
			btn_change(param)
		end
	end
end
----------------------------------------
function btn_over(e, param)
	local key = param.key
	if get_gamemode('ui2', key) then
		if not param.se then se_active() end

		-- 別のボタンがあれば消去
		local bt = btn.cursor
		if bt and bt ~= param.key then btn_out(e, { key=(bt), se=(param.se), flip=(param.flip)}) end

		local p = getBtnInfo(key)
		local id = p.idx
		if p.com == "single" then
			local df = loadBtnData(p.def) == 1
			local p2 = p.p2 ~= "1"
			local c  = p2 and (df and p.clip_d or p.clip_a) or df and p.clip_a or p.clip_d
			e:tag{"lyprop", id=(id..".0"), clip=(c)}

		elseif p.clip then
			e:tag{"lyprop", id=(id..".0"), clip=(p.clip_a)}
--			btn_yoyo(key, true)
		else
			e:tag{"lyprop", id=(id..'.0'), alpha=0}
			e:tag{"lyprop", id=(id..'.1'), alpha=255}
		end

		uihelp_over(p)
		if p.over then e:tag{"calllua", ["function"]=(p.over), name=(key)} end
		if not param.flip then flip() end

		btn.cursor = key
		btn.group  = btn.name
		if not flg.dlg and param.type then btn_actcursor() end	-- マウス操作のときはアクティブ情報を削除
	end
end
----------------------------------------
function btn_out(e, param)
	local key = param.key
	if get_gamemode('ui2', key, true) then
		local p = getBtnInfo(key)
		local id = p.idx
		if not btn[btn.name].dis[p.name] then
			if p.com == "single" then
				local df = loadBtnData(p.def) == 1
				local p2 = p.p2 ~= "1"
				local c  = p2 and (df and p.clip_c or p.clip) or df and p.clip or p.clip_c
				e:tag{"lyprop", id=(id..'.0'), clip=(c)}

			elseif p.clip then
--				btn_yoyo(key)
				e:tag{"lyprop", id=(id..'.0'), clip=(p.clip)}
			else
--				local id = getBtnID(key)
				e:tag{"lyprop", id=(id..'.0'), alpha=255}
				e:tag{"lyprop", id=(id..'.1'), alpha=0}
			end

			if p.out then e:tag{"calllua", ["function"]=(p.out), name=(key)} end
			if key == btn.cursor then btn.cursor=nil btn.group=nil uihelp_out(p) end
			if not param.flip then flip() end
		end
	end
end
----------------------------------------
-- ボタン点滅
function btn_yoyo(nm, f)
	local p  = getBtnInfo(nm)
	local id = p.idx
	if f then
		tween{ id=(id), alpha="255,200", yoyo="-1", time="500"}
	else
		e:tag{"lytweendel", id=(id)}
		e:tag{"lyprop", id=(id), alpha="255"}
	end
end
----------------------------------------
-- ボタンをアクティブにする / name, dir, se, flip
function btn_active(...)
	-- param check
	local t = {...}
	local n, d, p = t[1], t[2], {}
	if type(n) == 'table' then
		p = n
		n = n[1]
	end

	-- disable check
	local name = btn.name
	if btn[name].dis[n] then
		local dw = btn[name].p[n][d]
		local t  = getBtnInfo(n)

		-- toggle
		if t.com == 'toggle' and getBtnStat(n) then
			dw = t.p2
		end
		btn_active(dw, d)

	else
		local id = getBtnID(n)..'.0'
		btn_over(e, { id=(id), name=(name), key=(n), se=(p.se), flip=(p.flip)})
	end
end
----------------------------------------
function btn_active2(name) btn_active{ name, se=true, flip=true } end
----------------------------------------
-- ボタンをノンアクティブにする
function btn_nonactive(name, fp)
	if name then
		local n  = btn.name
		local id = getBtnID(name)..'.0'
		btn_out(e, { id=(id), name=(n), key=(name), flip=(fp)})
	end
end
----------------------------------------
-- カーソル制御
----------------------------------------
-- LT
function btn_left(e, param)
	local n1 = btn.name
	local n2 = param.name
	local p  = btn[n1].p[n2]
	local bt = btn.cursor
	if bt then
		local v = getBtnInfo(bt)
		if v.lt then
			btn_nonactive(bt)
			btn_active(v.lt, 'lt')
			bt = v.lt
		end
	elseif p.def then
		btn_active(p.def, 'lt')
		bt = p.def
	end
	if bt and not flg.dlg then btn_actcursor(bt) end
end
----------------------------------------
-- RT
function btn_right(e, param)
	local n1 = btn.name
	local n2 = param.name
	local p  = btn[n1].p[n2]
	local bt = btn.cursor
	if bt then
		local v = getBtnInfo(bt)
		if v.rt then
			btn_nonactive(bt)
			btn_active(v.rt, 'rt')
			bt = v.rt
		end
	elseif p.def then
		btn_active(p.def, 'rt')
		bt = p.def
	end
	if bt and not flg.dlg then btn_actcursor(bt) end
end
----------------------------------------
-- UP
function btn_up(e, param)
	local n1 = btn.name
	local n2 = param.name
	local p  = btn[n1].p[n2]
	local bt = btn.cursor
	if bt then
		local v = getBtnInfo(bt)
		if v.up then
			btn_nonactive(bt)
			btn_active(v.up, 'up')
			bt = v.up
		end
	elseif p.def then
		btn_active(p.def, 'up')
		bt = p.def
	end
	if bt and not flg.dlg then btn_actcursor(bt) end
end
----------------------------------------
-- DW
function btn_down(e, param)
	local n1 = btn.name
	local n2 = param.name
	local p  = btn[n1].p[n2]
	local bt = btn.cursor
	if bt then
		local v = getBtnInfo(bt)
		if v.dw then
			btn_nonactive(bt)
			btn_active(v.dw, 'dw')
			bt = v.dw
		end
	elseif p.def then
		btn_active(p.def, 'dw')
		bt = p.def
	end
	if bt and not flg.dlg then btn_actcursor(bt) end
end
----------------------------------------
-- LT/RT/UP/DWカーソル位置を保存
function btn_actcursor(bt)
	local name = btn.name
	if not flg.dlg and bt ~= -1 then
		if bt then	btn[name].actcursor = bt
		else		btn[name].actcursor = nil end

	-- 復帰
	elseif bt == -1 then
		local bt = btn[name].actcursor
		if bt then btn_active2(bt) end
	end
end
----------------------------------------
-- 現在の値を取得
function getbtn_actcursor()
	local r = nil
	local name = btn.name
	if btn[name] and btn[name].actcursor then r = btn[name].actcursor end
	return r
end
----------------------------------------
-- ボタン処理
----------------------------------------
-- ボタンの処理を自動判定
function btn_change(p)
	local bt = btn.cursor
	if bt and get_gamemode('ui2', bt) then
		se_ok()
		local t = getBtnInfo(bt)
		local sw = {
			mark	= function(p)	config_markclick(bt) end,						-- config専用
			check   = function(p)	check_change(bt) end,							-- checkbox
			single  = function(p)	single_change(bt) btn_active2(bt) flip() end,	-- singleボタン(アクティブにして返す)
			toggle  = function(p)	toggle_change(bt) end,							-- トグルボタン
			xslider = function(p)	sliderX(p) end,									-- 横スライダー
			yslider = function(p)	sliderY(p) end,									-- 縦スライダー
		}
		if t.com and sw[t.com] then
			sw[t.com](p)
		else
			sysmessage(bt, "には何も登録されていません", t.com)
		end
	end
end
----------------------------------------
-- チェックボックス入れ替え
function check_change(name)
	if get_gamemode('ui2', name) then
		local v = getBtnInfo(name)
		local p = loadBtnData(v.def)
		local f = tn(v.p1) or 0
--		if p == 0 then	p = 1 e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)}
--		else			p = 0 e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip)} end
		if p == f then	e:tag{"lyprop", id=(v.idx..".2"), visible="1"}
		else			e:tag{"lyprop", id=(v.idx..".2"), visible="0"} end
		p = p == 0 and 1 or 0
		saveBtnData(v.def, p)

		-- p4に関数名があれば呼び出し
		if v.p4 then e:tag{"calllua", ["function"]=(v.p4), name=(name)} end
		flip()
	end
end
----------------------------------------
-- シングルボタン入れ替え
function single_change(name)
	if get_gamemode('ui2', name) then
		local v = getBtnInfo(name)
		local p = loadBtnData(v.def) == 0 and 1 or 0
		saveBtnData(v.def, p)
		setBtnStat(name, "single")

		-- p4に関数名があれば呼び出し
		if v.p4 then e:tag{"calllua", ["function"]=(v.p4), name=(name)} end
		flip()
	end
end
----------------------------------------
-- トグル入れ替え
function toggle_change(name)
	if get_gamemode('ui2', name) then
		local t = getBtnInfo(name)
		local part = t.p2
		local save = nil
		if getBtnStat(name) then
			setBtnStat(name, nil)	-- 自分 enable
			setBtnStat(part, t.def)	-- 相棒 disable
			btn_clip(name, 'clip_a')
			btn_clip(part, 'clip_c')
--			btn_yoyo(name, true)
--			btn_yoyo(part)
			btn.cursor = name
		else
--			btn_yoyo(name)
--			btn_yoyo(part, true)
			btn_clip(name, 'clip_c')
			btn_clip(part, 'clip_a')
			setBtnStat(name, t.def)	-- 自分 disable
			setBtnStat(part, nil)	-- 相棒 enable
			btn.cursor = part
		end
		flip()

		-- 保存
		if t.def and t.p1 then saveBtnData(t.def, tn(t.p1)) end

		-- 入れ替え
		local t = getBtnInfo(btn.cursor)
		if t.over then e:tag{"calllua", ["function"]=(t.over), name=(t.name)} flip() end
		if t.p4   then e:tag{"calllua", ["function"]=(t.p4)  , name=(t.name)} flip() end
	end
end
----------------------------------------
-- btn color
function btn_clip(name, clip)
	local v = getBtnInfo(name)
	e:tag{"lyprop", id=(v.idx..'.0'), clip=(v[clip])}
end
----------------------------------------
-- 横スライダー
----------------------------------------
-- 横スライダー／分岐
function sliderX(p)
	local bt = btn.cursor
	if p.click or tn(p.key) == 1 then slider_clickX(e, p)
	elseif bt then xslider_add(bt, 10)
	end
end
----------------------------------------
-- 横スライダー／クリック処理
function slider_clickX(e, param)
	local name = param.btn or param.key
	if get_gamemode('ui2', name) and not flg.sliderdrag then
		local tbl = getBtnInfo(name)
		local pos = e:getMousePoint()
		local pin = math.floor(tbl.p2/2)

		-- 座標算出
		local x = pos.x - tbl.x - pin
		local m = tbl.w - tbl.p2
		local p = percent(x, m)

		-- pin移動
		local id = tbl.idx..".10"
		if p < 0 then x,p = 0,0 elseif p > 100 then x,p = m,100 end
		e:tag{"lyprop", id=(id), left=(x)}
--		e:tag{"lydrag", id=(id)}

		-- 保存
		local old = nil
		if tbl.def then old = saveBtnData(tbl.def, p) end

		-- p4に関数名があれば呼び出し
		if tbl.p4 then e:tag{"calllua", ["function"]=(tbl.p4), name=(name), p=(p), old=(old)} end
		flip()
	end
end
----------------------------------------
-- 横スライダー／ドラッグ処理
function slider_dragX(e, param)
	local name = param.key
	if get_gamemode('ui2', name) then
		local id  = param.id
		local tbl = getBtnInfo(name)

		-- get_layer_info
		e:tag{"var", name="t.ly", system="get_layer_info", id=(id)}
		local x = tonumber(e:var("t.ly.left"))
		local m = tbl.w - tbl.p2
		local p = percent(x, m)

		-- 保存
		local old = nil
		if tbl.def then old = saveBtnData(tbl.def, p) end

		-- p4に関数名があれば呼び出し
		if tbl.p4 then e:tag{"calllua", ["function"]=(tbl.p4), name=(name), p=(p), old=(old)} end
		flip()
	end
end
----------------------------------------
-- 横スライダー／加算処理
function xslider_add(name, sub)
	if get_gamemode('ui2', name) then
		local t = getBtnInfo(name)
		local id  = getBtnID(name)..".10"
		local add = conf[t.def]
		add = add + sub
		if add > 100 then add = 100
		elseif add < 0 then add = 0 end

		-- 保存
		if t.def then saveBtnData(t.def, add) end

		local p = repercent(add, t.w - t.p2)
		e:tag{"lyprop", id=(id), left=(p)}

		-- p4に関数名があれば呼び出し
		if t.p4 then e:tag{"calllua", ["function"]=(t.p4), name=(name), p=(p)} end
		flip()
	end
end
----------------------------------------
-- 横スライダー／ピン位置を移動する
function xslider_pin(name, num)
	if get_gamemode('ui2', name) then
		local t  = getBtnInfo(name)
		local id = t.idx..".10"
		local p  = repercent(num, t.w - t.p2)
		e:tag{"lyprop", id=(id), left=(p)}
	end
end
----------------------------------------
-- 縦スライダー
----------------------------------------
-- 縦スライダー／分岐
function sliderY(p)
	local bt = btn.cursor
	if p.click or tn(p.key) == 1 then slider_clickY(e, p)
	elseif bt then yslider_add(bt, 10)
	end
end
----------------------------------------
-- 縦スライダー／クリック処理
function slider_clickY(e, param)
	local name = param.btn or param.key
	if get_gamemode('ui2', name) and not flg.sliderdrag then
		local tbl = getBtnInfo(name)
		local pos	= e:getMousePoint()
		local piny	= math.floor(tbl.p2/2)

		-- 座標算出
		local y = pos.y - tbl.y - piny
		local m = tbl.h - tbl.p2
		local p = percent(y, m)

		-- pin移動
		local id = tbl.idx..".10"
		if p < 0 then y,p = 0,0 elseif p > 100 then y,p = m,100 end
		e:tag{"lyprop", id=(id), top=(y)}
--		e:tag{"lydrag", id=(id)}

		-- 保存
		local old = nil
		if tbl.def then old = saveBtnData(tbl.def, p) end

		-- p4に関数名があれば呼び出し
		if tbl.p4 then e:tag{"calllua", ["function"]=(tbl.p4), name=(name), p=(p), old=(old)} end
		flip()
	end
end
----------------------------------------
-- 縦スライダー／ドラッグ処理
function slider_dragY(e, param)
	local name = param.key
	if get_gamemode('ui2', name) then
		local id  = param.id
		local tbl = getBtnInfo(name)

		-- get_layer_info
		e:tag{"var", name="t.ly", system="get_layer_info", id=(id)}
		local y = tonumber(e:var("t.ly.top"))
		local m = tbl.h - tbl.p2
		local p = percent(y, m)

		-- 保存
		local old = nil
		if tbl.def then old = saveBtnData(tbl.def, p) end

		-- p4に関数名があれば呼び出し
		if tbl.p4 then e:tag{"calllua", ["function"]=(tbl.p4), name=(name), p=(p), old=(old)} end
		flip()
	end
end
----------------------------------------
-- draggable書き換え
function sliderdrag_stat(no)
	local nm = btn.name
	local id = btn[nm].id
	for k, p in pairs(btn[nm].p) do
		if type(p) == "table" and (p.com == 'xslider' or p.com == 'yslider') then
			e:tag{"lyprop", id=(id..p.id..'.10'), draggable=(no)}
		end
	end

	-- 1でボタン復帰
	if no == 1 then btn_actcursor(-1) end
end
----------------------------------------
function slider_dragin()  e:setUseMultiTouch(1) flg.sliderdrag = true end	-- スライダーdrag開始 / マルチタッチ解除
function slider_dragout() e:setUseMultiTouch(3) flg.sliderdrag = nil  end	-- スライダーdrag終了 / マルチタッチを3に制限
----------------------------------------
-- 
----------------------------------------
-- ボタンのp1を使用してietを呼び出す
function btn_calliet(e, p)
	local bt = p.btn
	local v  = getBtnInfo(bt)
	if v.p1 then
		local px = "system/extend/"..v.p1
		eqtag{"call", file=(px)}
	end
end
----------------------------------------
-- ボタンステータス変更 / 全体
function btnstat(i, m)
	local id	= i or "500"
	local mode	= m or "disable"
	e:tag{"lyevent", id=(id), type="click",    mode=(mode)}
	e:tag{"lyevent", id=(id), type="rollover", mode=(mode)}
	e:tag{"lyevent", id=(id), type="rollout",  mode=(mode)}
end
----------------------------------------
-- ボタンデータ保存
function saveBtnData(nm, dt)
	local name = btn.name
	local old  = nil
	if loadBtnData(nm) ~= dt then
--		message("save", name, nm, dt)
		if name == 'conf' then
			old = conf[nm]
			conf[nm] = dt
			btn.renew = true	-- 更新フラグ
		else
			old = sys[name][nm]
			sys[name][nm] = dt
		end
	end
	return old
end
----------------------------------------
-- ボタンデータ読み込み
function loadBtnData(name)
--	local name = btn.name
--	return name == 'conf' and conf[nm] or sys[name] and sys[name][nm]
	local r  = name
	local bn = btn.name
	if r:find(".", 1, true) then
		local a  = explode("%.", r)
		local md = a[1]
		local nm = a[2]
		local sw = {
			conf = function() return conf[nm] end,
			sys  = function() return  sys[nm] end,
			gscr = function() return gscr[nm] end,
			scr  = function() return  scr[nm] end,
		}
		if sw[md] then r = sw[md]() end
	elseif bn == "conf" then
		r = conf[name]
	elseif sys[bn] then
		r = sys[bn][name]
	end

	-- check
	if not r then
		r = 0
		message("注意", name, "は設定されていないパラメータです")
	end
	return r
end
----------------------------------------
-- 更新があったか確認する
function checkBtnData()
	return btn.renew
end
----------------------------------------
-- ボタン無効／有効切り替え
function setBtnStat(n, s)
	local name = btn.name
	local v    = getBtnInfo(n) or {}
	if btn[name] and v.name then

		----------------------------------------
		-- single
		if s == "single" then
			local d  = v.def and loadBtnData(v.def)
			local p1 = v.p1
			local p2 = v.p2 ~= "1"

			-- disable
			if p2 and d == 0 or not p2 and d == 1 then
				e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip)}
				if p1 then setBtnStat(p1, "c") end
			-- enable
			elseif p2 and d == 1 or not p2 and d == 0 then
				e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)}
				if p1 then setBtnStat(p1) end
			end

		----------------------------------------
		-- disable
		elseif s then
			btn[name].dis[n] = s
			-- ３番目使用
			if s == "c" then
				e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip_c)}

			-- ４番目使用
			elseif s == 'd' then
				local clip = ""
				if v.dir == "width" then clip = (v.cx + v.cw*3)..","..v.cy..","..v.cw..","..v.ch
				else					 clip = v.cx..","..(v.cy + v.ch*3)..","..v.cw..","..v.ch end
				e:tag{"lyprop", id=(v.idx..".0"), clip=(clip)}
			end
			if v.com == "xslider" or v.com == "yslider" then e:tag{"lyprop", id=(v.idx..".10"), visible="0"} end

		----------------------------------------
		-- enable
		else
			btn[name].dis[n] = nil
			e:tag{"lyprop", id=(v.idx..".0"), clip=(v.clip)}
			if v.com == "xslider" or v.com == "yslider" then e:tag{"lyprop", id=(v.idx..".10"), visible="1"} end
		end
	else
		sysmessage("エラー", n, "ボタンがありませんでした")
	end
end
----------------------------------------
-- ボタン無効／有効情報取得
function getBtnStat(n)
	local name = btn.name
	local p = nil
	if btn[name] then
		p = btn[name].dis[n]
	else
		sysmessage("エラー", n, "ボタンがありませんでした")
	end
	return p
end
----------------------------------------
-- ボタンの有無確認
function checkBtnExist(n)
	local r = nil
	local name = btn.name
	if btn[name] and btn[name].p[n] then r = true end
	return r
end
----------------------------------------
-- ボタン情報取得
function getBtnInfo(n)
	local name = btn.name
	local p = {}
	if btn[name] and btn[name].p[n] then
		p = btn[name].p[n]
		p.path= btn[name].p[1]
		p.idx = p.id and btn[name].id..p.id
		p.dis = btn[name].dis[n]
	else
		sysmessage("エラー", n, "ボタンがありませんでした")
	end
	return p
end
----------------------------------------
-- ボタンID取得
function getBtnID(n)
	local name = btn.name
	local p = "error"
	if btn[name] and btn[name].p[n] then
		p = btn[name].id..btn[name].p[n].id
	else
		sysmessage("エラー", n, "ボタンがありませんでした")
	end
	return p
end
----------------------------------------
