----------------------------------------
-- 選択肢
----------------------------------------
-- 選択肢割り振り
function exselect(p)
	-- 初期化
	if not scr.select then
		message("通知", "選択肢を初期化します")
		scr.select = { idx={} }
	end

	-- 登録
	local tx = p.text
	if tx then	select_text(p)			-- textがあれば追加
	else		select_start(p) end		-- 実行
end
----------------------------------------
-- 選択肢のボタンテキストを設定する
function select_text(p)
	local tbl = {
		file  = p.file,
		label = p.label,
		text  = p.text,
		exp   = p.exp,
		pre   = p.pre,
	}

	-- cond
	if p.cond then tbl.cond = p.cond end

	-- 代入
	table.insert(scr.select, tbl)
end
----------------------------------------
-- 選択肢を初期化する
function select_start(p)
	local name = p.name or scr.ip.file
	local mode = p.mode
	local asel = tn(p.auto or 0)
	scr.select.name = name
	scr.select.mode = mode

	----------------------------------------
	-- anime
	local an = p.anime
	if an then
		local fl = an..".ipt"
		local px = isFile(":ui/mw/"..fl) and ":ui/mw/"..fl or isFile(fl) and fl
		if px then
			e:include(px)
			scr.select.anime = tcopy(ipt)
			ipt = nil
		else
			message("注意", an, "は不明なアニメ指定です")
		end
	end

	----------------------------------------
	-- 時限設定
	if mode == "timed" then
		local a = scr.select.anime or {}
		scr.select.timed = p.wait or a.wait or 3000
	end

	----------------------------------------
	delImageStack()		-- cache delete

	----------------------------------------
	-- 拡張選択肢
	if mode == "ex" then
		local r = select_extendCheck(p.func)	-- 拡張選択肢使用可確認
		if r then
			estag("init")
			estag{"msgoff"}						-- 念のため[msgoff]しておく
			estag{"exskip_stop"}				-- debugskip停止
			estag{"select_init"}				-- 選択肢設定
			estag{"select_extendinit", p}		-- 拡張選択肢設定
			estag()
		else
			error_message("拡張選択肢の呼び出しに失敗しました")
		end

	----------------------------------------
	-- yes/no選択肢
	elseif mode == "yesno" then
		scr.select.yesno = true
		estag("init")
		estag{"exskip_stop"}			-- debugskip停止
		estag{"select_init"}			-- 選択肢初期化
		estag{"msgon"}					-- 念のため[msgon]しておく
		estag{"select_autosave"}		-- autosave
		estag{"select_yesno"}			-- yesno選択肢表示
		estag()

	----------------------------------------
	-- 自動選択１
	elseif asel == 1 and conf.finish01 ~= 2 then
		scr.select.id = conf.finish01 + 1
		scr.select.autoselect = true
		estag("init")
		estag{"exskip_stop"}			-- debugskip停止
		estag{"select_clicknext"}
		estag()

	----------------------------------------
	-- 自動選択２
	elseif asel == 2 and conf.finish02 ~= 2 then
		scr.select.id = conf.finish02 + 1
		scr.select.autoselect = true
		estag("init")
		estag{"exskip_stop"}			-- debugskip停止
		estag{"select_clicknext"}
		estag()

	----------------------------------------
	-- 実行
	else
		local md = p.mode
		estag("init")
		estag{"exskip_stop"}					-- debugskip停止
		estag{"select_init"}
		if md == 'hide' or md == "timed" then 
			estag{"msgon", { mode="hide" }}		-- mw非表示 / 選択肢のみ入力許可
			scr.select.hide = true
		else
			if md == "sys" and game.pa then
				estag{"msgon", { mode="sys" }}	-- ボタンのみ表示モード
				scr.select.mwsys = true
			else
				estag{"msgon"}					-- 念のため[msgon]しておく
			end
			local bl = #log.stack
			if bl > 0 and md ~= 'nosave' then
				estag{"select_autosave"}		-- autosave
			end
		end
		estag{"select_view"}					-- 表示
		estag{"select_event"}					-- lyevent割り当て
		estag()
	end
end
----------------------------------------
-- 拡張選択肢 / 確認
function select_extendCheck(nm)	return exSelectTable and exSelectTable[nm] end
function select_extendinit(p)	select_extend("init", p) end
----------------------------------------
-- 拡張選択肢
function select_extend(ex, p)
	local r = true
	local s = scr.select
	local t = exSelectTable
	local nm = p and p.func or s and s.func
	if s and t and nm and t[nm] and t[nm][ex] then
		if ex == "init" then
			message("通知", "拡張選択肢モードに入ります。")
			scr.select.func = nm
--		else
--			message("通知", "拡張選択肢モード", ex)
		end
		_G[t[nm][ex]](p)
		r = nil
	end
	return r
end
----------------------------------------
-- 選択肢の初期化
function select_init()
	autoskip_stop(true)		-- auto/skip保存して停止
	glyph_del()				-- glyphを消す
	init_adv_btn()			-- mwbtn再設置
--	eqwait{ scenario="1" }	-- テキストの表示終了を待つ
	set_backlog_next()		-- 一旦保存しておく
	log.stack[#log.stack].select = -1	-- 番号は不定
end
----------------------------------------
-- autosave
function select_autosave()
	if init.game_selectsave == "on" then
		sv.autosave("selsave")
	end
end
----------------------------------------
-- 選択肢を表示する
function select_view()
	local s = scr.select
	local max  = #s
	local name = s.name

	-- 選択肢ボタン
	local c  = 0
	local t  = csv.mw.select					-- 画像情報
	local id = getMWID("select")				-- id base
	local cd = init.select_condtext				-- cond==0時に表示するテキスト
	local vs = init.game_selcond_hide == "on"	-- on:cond条件を満たしていなかったとき、選択肢を非表示にする
	local wh = split(t.clip, ',')
	local ax = math.floor(wh[3] / 2)
	local ay = math.floor(wh[4] / 2)
	local file = get_uipath()..t.file
	for i=1, max do
		local v = s[i]
		local f = v.cond and cond(v.cond) == 1 or not v.cond	-- condが無いか条件を満たす

--		message("通知", i, c, f, text, v.cond)

		if f or cd then
			local vsc = nil
			local ids  = id.."."..(c+1)..".0"
			local idx  = ids..".0"
			local clip = f and t.clip or t.clip_c
			scr.select.idx[i] = idx

			-- cond条件を満たしていない
			if not f then
				scr.select[i].disable = true

			-- ボタン有効
			else
				scr.select[i].disable = nil
				if vs then c = c + 1 end	-- 有効のみ加算
				vsc = true
			end

			-- 無効でも加算
			if not vs then c = c + 1 vsc = true end

			-- 画像設置
			if vsc then
				local ix = idx..'.0'
				local rr = select_premier(ix, v, 1, true)
				if not rr then
					lyc2{ id=(ix), file=(file), clip=(clip)}
					tag{"lyprop", id=(ids), left=(t.x)}
				end
				tag{"lyprop", id=(idx), anchorx=(ax), anchory=(ay)}
			end
		end
	end
	scr.select.max = c

	-- テキスト表示
	select_message()
	select_timed_view()		-- anime

	-- bg check
	local n = "selectbg"..c
	local b = csv.mw[n]
	if b then lyc2{ id=(id..'.0'), file=(game.path.ui..b.file), clip=(b.clip), x=(b.x), y=(b.y)} end

	-- 座標
	local y = math.ceil(t.h / 2)
	local z = init.select or {}
	if z[c] then
		for i=1, c do
			e:tag{"lyprop", id=(id.."."..i), top=(t.y + math.floor(y * z[c][i]))}
		end
	end
	scr.select.count = c

	-- カーソル動作書き換え
	setonpush_select()

	-- アニメーション
	local b = init.select_animebgin if _G[b] then _G[b]() end
	local z = init.select_animein
	local a = init.select_anime
	if a then
		local seltween = {
			lt = function(idx, t, d) tween{ id=(idx), x="0,0", time=(t), delay=(d)} end,
			rt = function(idx, t, d) tween{ id=(idx), x="0,0" , time=(t), delay=(d)} end,
			up = function(idx, t, d) tween{ id=(idx), y="0,0" , time=(t), delay=(d)} end,
			dw = function(idx, t, d) tween{ id=(idx), y="0,0", time=(t), delay=(d)} end,
			xs = function(idx, t, d) tween{ id=(idx), xscale="0,100", time=(t), delay=(d)} end,
			ys = function(idx, t, d) tween{ id=(idx), yscale="0,100", time=(t), delay=(d)} end,

			ro = function(idx, t, d) tween{ id=(idx), rotate="360,0", time=(t), delay=(d)} end,

			zs = function(idx, t, d)
				tween{ id=(idx), xscale="200,100", time=(t), delay=(d)}
				tween{ id=(idx), yscale="0,100"  , time=(t), delay=(d)}
			end,
			ro2 = function(idx, t, d)
				tween{ id=(idx), zoom="200,100", time=(t), delay=(d)}
				tween{ id=(idx), rotate="360,0", time=(t), delay=(d)}
			end,

			-- 拡張アニメ
			ex = function(idx, t, d)
				if _G[z] then _G[z](idx, t, d) end
			end,
		}
		local time	= init.select_time  or 200
		local delay = 0
		local alpha = init.select_alpha == "on"
		local wait	= time
		for i=1, c do
			local idx = id.."."..i..".0.0"
			local dl  = (i-1)*delay
			if alpha then tween{ id=(idx), alpha="0,255" , time=(time), delay=(dl)} end
			if seltween[a] then seltween[a](idx, time, dl) end
			wait = wait + delay
		end
		select_timed_open(time, wait)		-- anime
		flip()
		eqwait(wait)
		for i=1, c do
			local idx = id.."."..i..".0.0"
			eqtag{"lytweendel", id=(idx)}
		end
	else
		uitrans()
	end
end
----------------------------------------
-- lyevent割り当て
function select_event(flag)
	local s = scr.select
	if s then
		local c = #s
		for i=1, c do
			local idx = not s[i].disable and s.idx[i]
			if idx then lyevent{ id=(idx..'.0'), no=(i), name="select", key="CLICK", click="select_click", over="select_over", out="select_out"} end
		end
	end

	-- 入力待ち
	if not flag then eqtag{"jump", file="system/script.asb", label="select"} end

	-- anime event登録
	select_timed_event()
end
----------------------------------------
-- 
----------------------------------------
-- 選択肢終了
function select_reset()
	if scr.select then

		-- 画像消去
		local r = select_extend("reset")
		if r then select_resetimage() end
		scr.select = nil
		scr.btnfunc["select|CLICK"] = nil
		scr.p = nil
		delonpush_ui()		-- key戻し
		setMWFont(true)		-- glyph戻し
	end
end
----------------------------------------
-- 選択肢の画像を消去
function select_resetimage()
	if scr.select then
		local id  = getMWID("select")
		lydel2(id)

		-- 選択肢に表示したメッセージの消去
		local ca = lang.font.select_active	-- アクティブ文字色
		for i=1, #scr.select do
			local idx = id.."."..i..".0.0.2"
			e:tag{"chgmsg", id=(idx)}
			e:tag{"rp"}
			e:tag{"/chgmsg"}
			if ca then
				local idx = id.."."..i..".0.0.3"
				e:tag{"chgmsg", id=(idx)}
				e:tag{"rp"}
				e:tag{"/chgmsg"}
			end
			lydel2(idx)
		end

		-- select title
		local id = getMWID("selecttitle")
		if id then ui_message(id) end
	end
end
----------------------------------------
-- 
----------------------------------------
-- 選択肢決定
function select_click()
	local v  = scr.select
	local no = v.id
	if no and get_gamemode('adv') then
		se_select()
--		flg.btnstop = true		-- ボタン禁止
		allkeyoff()				-- 入力禁止
		autoskip_disable()		-- autoskip一旦停止
		scr.select.vsync = nil	-- vsync停止

		-- 決定色がある
		local id = getMWID("select")	-- id base
		local t  = csv.mw.select		-- 画像情報
--		if t.clip_c then
--			e:tag{"lyprop", id=(v.idx[no]..".0"), clip=(t.clip_c)}
--			flip()
--		end

		-- アニメーション
		local b = init.select_animebgout if _G[b] then _G[b]() end
		local z = init.select_animeout
		local a = init.select_anime
		if a then
			local seltween = {
				lt = function(idx, t, d) tween{ id=(idx), x="0,0", time=(t), delay=(d)} end,
				rt = function(idx, t, d) tween{ id=(idx), x="0,0" , time=(t), delay=(d)} end,
				up = function(idx, t, d) tween{ id=(idx), y="0,0" , time=(t), delay=(d)} end,
				dw = function(idx, t, d) tween{ id=(idx), y="0,0", time=(t), delay=(d)} end,
				xs = function(idx, t, d) tween{ id=(idx), xscale="100,0", time=(t), delay=(d)} end,
				ys = function(idx, t, d) tween{ id=(idx), yscale="100,0", time=(t), delay=(d)} end,
	
				ro = function(idx, t, d) tween{ id=(idx), rotate="0,-360", time=(t), delay=(d)} end,
	
				zs = function(idx, t, d)
					tween{ id=(idx), xscale="100,200", time=(t), delay=(d)}
					tween{ id=(idx), yscale="100,0"  , time=(t), delay=(d)}
				end,
				ro2 = function(idx, t, d)
					tween{ id=(idx), zoom="100,200", time=(t), delay=(d)}
					tween{ id=(idx), rotate="0,360", time=(t), delay=(d)}
				end,

				-- 拡張アニメ
				ex = function(idx, t, d)
					if _G[z] then _G[z](idx, t, d) end
				end,
			}
			local time	= init.select_time  or 200
			local delay = 0
			local alpha = init.select_alpha == "on"
			local wait	= time
			local max	= #v
			local c		= 0
			for i=1, max do
				local z = v[i] or {}
				if not z.disable and i ~= no then
					local idx = v.idx[i]
					if idx then
						local dl = c * delay
						if alpha then tween{ id=(idx), alpha="255,0", time=(time), delay=(dl)} end
						if seltween[a] then seltween[a](idx, time, dl) end
						if i < max then wait = wait + delay end
						c = c + 1
					end
				end
			end
			select_timed_close(time, wait)	-- anime
			flip()
			scr.select.wait = wait
		end

		-- script.asbを経由する
		btnstat(getMWID("select"))	-- キー連打を防ぐ
		eqtag{"jump", file="system/script.asb", label="select_exit"}
	end
end
----------------------------------------
-- 
function select_exittrans()
	local s = scr.select
	if s then
		local a = init.select_anime
		local w = s.wait
		local id = getMWID("select")

		-- mwを戻す
		if s.mwsys and game.pa then
			estag("init")
			estag{"eqwait", w}
			estag{"lydel", id=(id)}			-- 画像消去
			estag{"uitrans"}
			estag()

		-- アニメ停止
		elseif a then
			estag("init")
			estag{"eqwait", w}
			for i=1, #s.idx do
				local idx = s.idx[i]
				estag{"lytweendel", id=(idx)}
			end
			estag{"lydel", id=(id)}			-- 画像消去
			estag{"uitrans"}
			estag()

		-- 消去
		else
			lydel2(id)					-- 画像消去
			uitrans()
		end
	end
end
----------------------------------------
-- 事後処理
function select_clicknext()
	local s  = scr.select
	local no = s.id
	local t  = s[no] or {}
	local ln = get_language(true)			-- 多言語
	local bl = scr.ip.block
	local v  = ast[bl].select[ln]
	local tx = v[no]
	if no == -1 then
		tx = get_langsystem("select_timed") or ""	-- 時間超過
	elseif tx then
		tx = tx:gsub('　', '')
	end

	-- バックログの１画面分をクローズ
	if not s.hide then 
		if not s.autoselect then
			table.remove(log.stack, #log.stack)
		end
		set_backlog_next()
		log.stack[#log.stack].select = no	-- 番号を保存しておく
	end

	message("通知", "『", tx, "』が選択されました", label)

	-- 選択したボタンを既読にする
	if not getExtra() and init.select_save == 'on' and no > 0 then
		local name = s.name
		if not gscr.select then gscr.select = {} end
		if not gscr.select[name] then gscr.select[name] = {} end
		gscr.select[name][no] = 1
		asyssave()
	end

	-- exp処理
	if t.exp then set_eval(t.exp) end

	-- 事後処理
	exselback("selsave")	-- 前の選択肢に戻る、の情報をスタック / scr.select削除前に実行
	select_reset()			-- バッファクリア
	scr.ip.count = nil		-- カウンタリセット
	scr.flowposition = nil	-- フローチャート位置情報削除
	clickEnd(e)				-- click終了処理を通す
	init_adv_btn()			-- mwbtn再設置
	ResetStack()			-- stackを空にする

	-- mode=hideの場合はリセットしておく
	if s.hide then msg_reset() end

	-- 自動選択の場合はオートモード再開処理を実行しない
	local s = v.autoselect
	if not s then
		restart_autoskip()		-- auto/skip再開
		set_message_speed()		-- mspeed復帰
		allkeyon()				-- 入力許可
	end

	-- file/labelがある場合は飛ぶ
	if t.file or t.label then
		stack_eval()			-- 更新があったのでスタックしておく
		gotoScript{ file=(t.file), label=(t.label) }		-- スクリプトの呼び出し

	-- ない場合はフラグをセットして次の行へ
	else
		set_eval('f.s='..no)
		stack_eval()			-- 更新があったのでスタックしておく
		autocache()				-- 自動キャッシュ
		tag{"jump", file="system/script.asb", label="main"}
	end
end
----------------------------------------
-- 
----------------------------------------
-- プレミア選択肢
function select_premier(id, p, no, view)
	local r = nil
	local fx = p.pre
	local px = fx and get_uipath().."mw/"..fx..".ipt"
	if px and isFile(px) then
		ipt = nil
		e:include(px)
		local zz = ipt and ipt[no]
		if zz then
			if view then
				lyc2{ id=(id), file=(get_uipath()..zz[1]), clip=(zz.clip), x=(zz.x), y=(zz.y)}
			else
				tag{"lyprop", id=(id), clip=(zz.clip)}
			end
			r = true
		end
	end
	return r
end
----------------------------------------
-- 選択肢アクティブ
function select_over(e, p)
	if get_gamemode('adv') then
		if not p.se then se_active() end
		local s  = scr.select
		local no = tonumber(p.no)
		local ix = s.id
		if ix and ix ~= no then select_out(e, { no=(ix) }) end

		-- 画像
		local id = p.id or s.idx[no]..".0"
		local r = select_premier(id, s[no], 2)
		if not r then
			local t	= csv.mw.select		-- 画像情報
			tag{"lyprop", id=(id), clip=(t.clip_a)}
		end

		-- アクティブ文字色
		local ca = lang.font.select_active
		if ca then 		
			local idx = s.idx[no]
			tag{"lyprop", id=(idx..".2"), visible="0"}
			tag{"lyprop", id=(idx..".3"), visible="1"}
		end

		-- 拡張
		local nm = "user_selectover"
		if _G[nm] then _G[nm](p) end
		flip()
		scr.select.id = no
	end
end
----------------------------------------
-- 選択肢ノンアクティブ
function select_out(e, p)
	if get_gamemode('adv') then
		local s  = scr.select
		local no = tonumber(p.no)
		if scr.select.id == no then scr.select.id = nil end

		-- 画像
		local id = p.id or s.idx[no]..".0"
		local r = select_premier(id, s[no], 1)
		if not r then
			local t = csv.mw.select		-- 画像情報
			tag{"lyprop", id=(id), clip=(t.clip)}
		end

		-- アクティブ文字色
		local ca = lang.font.select_active
		if ca then 		
			local idx = s.idx[no]
			tag{"lyprop", id=(idx..".2"), visible="1"}
			tag{"lyprop", id=(idx..".3"), visible="0"}
		end

		-- 拡張
		local nm = "user_selectout"
		if _G[nm] then _G[nm](p) end
		flip()
	end
end
----------------------------------------
-- 選択肢／キー操作 ↑
function select_keyup()
	local s = scr.select
	local max = #s
	local key = s.id or max + 1

	-- 現在位置から１周する
	local c = key
	for i=1, max do
		local n = key - i
		if n < 1 then n = n + max end
		if not s[n].disable then
			c = n
			break
		end
	end

	-- カーソル移動
	if c ~= key then select_over(e, { no=(c) }) end
end
----------------------------------------
-- 選択肢／キー操作 ↓
function select_keydw()
	local s = scr.select
	local max = #s
	local key = s.id or 0

	-- 現在位置から１周する
	local c = key
	for i=1, max do
		local n = key + i
		if n > max then n = n - max end
		if not s[n].disable then
			c = n
			break
		end
	end

	-- カーソル移動
	if c ~= key then select_over(e, { no=(c) }) end
end
----------------------------------------
-- 選択肢テキスト描画
function select_message()
	local ln = get_language(true)
	local bl = scr.ip.block
	local s  = scr.select
	local v  = ast[bl] and ast[bl].select and ast[bl].select[ln]
	if not v then
		tag_dialog({ title="エラー", message=("選択肢のデータが異常です") }, "stop")
		return
	end

	----------------------------------------
	-- select title
	local t = csv.mw.selecttitle
	if t then
		local tx = v.text
		local id = getMWID("selecttitle")
		local fl = get_uipath()..t.file
		lydel2(id)
		lyc2{ id=(id..'.0'), file=(fl), clip=(t.clip)}
		if tx then ui_message((id..'.20'), { "select_title", text=(tx)}) end
		tag{"lyprop", id=(id), left=(t.x), top=(t.y)}

	-- text
	else
		-- 名前表示
		local nm = v.name
		if nm then message_name(nm) end

		-- 本文表示 / 既読判定
		local tx = v.text
		if tx then
			local ma = conf.mw_aread or 0
			local ar = getAread()
			local cx = not flg.ui and ar and ma == 1 and init.textaread_color

			-- text
			chgmsg_adv()
			tag{"scetween", mode="init", type="in"}
			tag{"scetween", mode="add" , type="in", param="alpha", ease="none", time="0", delay="0", diff="0"}
			tag{"rp"}
			if cx then tag{"font", color=("0"..cx)} end
			tag{"print", data=(tx)}
			if cx then tag{"/font"} end
			chgmsg_adv("close")
		end
	end

	----------------------------------------
	-- 選択肢書き換え
	local id = getMWID("select")				-- id base
	local gs = gscr.select[s.name] or {}		-- 既読情報
	local vs = init.game_selcond_hide == "on"	-- on:cond条件を満たしていなかったとき、選択肢を非表示にする
	local cd = init.select_condtext				-- cond==0時に表示するテキスト
	local ca = lang.font.select_active			-- アクティブ文字色
	local rd = conf.selcolor == 1
	local mx = #s
	local c  = 0
	for i=1, mx do
		local ids = id.."."..(c+1)..".0"
		local idx = ids..".0"
		local f   = not s[i].disable

		-- text
		local tn  = f and v[i] or vs and cd
		if tn then
			local slnm = rd and gs[i] == 1 and "select_aread" or "select"	-- font名
			ui_message((idx..'.2'), { slnm, text=(tn)})
			tag{"lyprop", id=(idx..'.2'), visible="1"}

			-- 有効のみ加算
			if f and vs then c = c + 1 end
		end

		-- active color
		if tn and ca then
			local ia = idx..'.3'
			ui_message((ia), { "select_active", text=(tn)})
			tag{"lyprop", id=(ia), visible="0"}
		end

		-- 無効でも加算
		if not vs then c = c + 1 end
	end
end
----------------------------------------
-- ボタン再設定
function select_refresh()
	local s  = scr.select
	if s and game.os == "windows" then
		local m = e:getMousePoint()
		local x = m.x
		local y = m.y
		local fl = true
		for i=1, #s do
			if not s[i].disable then
				local id = s.idx[i]
				tag{"var", name="t.ly", system="get_layer_info", id=(id:sub(1, -3))}
				local lx = tn(e:var("t.ly.left"))
				tag{"var", name="t.ly", system="get_layer_info", id=(id:sub(1, -5))}
				local ly = tn(e:var("t.ly.top"))
				tag{"var", name="t.ly", system="get_layer_info", id=(id..".0")}
				local lw = tn(e:var("t.ly.width" )) + lx
				local lh = tn(e:var("t.ly.height")) + ly

				-- 範囲内はactiveにする
				if x >= lx and x <= lw and y >= ly and y <= lh then
					select_over(e, { no=(i), se=true })
					fl = nil
					break
				end
			end
		end

		-- 範囲外はnonactive
		if fl and s.id then
			select_out(e, { no=(s.id) })
		end
	end
end
----------------------------------------
-- 時限選択肢
----------------------------------------
-- id取得
function select_timed_getid()
	local r  = nil
	local id = getMWID("select")				-- id base
	local a  = scr.select.anime or {}
	if a.id then r = id.."."..a.id end
	return r
end
----------------------------------------
-- 描画
function select_timed_view()
	local a  = scr.select.anime or {}

	-- base
	local bs = a.base
	if bs then
		bs.id = select_timed_getid()
		lyc2(bs)
	end

	-- 描画
	local nm = a.view
	if nm and _G[nm] then _G[nm]() end
end
----------------------------------------
-- 描画アニメ
function select_timed_open(time, wait)
	local a  = scr.select.anime
	local nm = a and (a.open or "user_selecttimed_open")
	if nm and _G[nm] then _G[nm](time, wait) end
end
----------------------------------------
-- 消去アニメ
function select_timed_close(time, wait)
	local a  = scr.select.anime
	local nm = a and (a.close or "user_selecttimed_close")
	if nm and _G[nm] then _G[nm](time, wait) end
end
----------------------------------------
-- vsync処理登録
function select_timed_event()
	local md = scr.select.mode
	local tm = scr.select.timed
	if md == "timed" and tm then
		scr.select.vsync = tm + e:now()
	end
end
----------------------------------------
-- vsync処理
function select_timed_vsync()
	local tm = scr.select.vsync
	if tm <= e:now() then
		scr.select.vsync = nil	-- vsync処理停止
		setexclick(150)			-- 間にキー処理を挟む
		tag{"setonpush", key=(150), handler="calllua", ["function"]="select_timed_vsyncexit"}
	end

	-- 関数処理
	local a  = scr.select.anime or {}
	local nm = a.vsync
	if nm and _G[nm] then _G[nm]() end
end
----------------------------------------
-- vsync / 時間経過
function select_timed_vsyncexit()
	tag{"delonpush", key=(150)}
	scr.select.id = -1
	select_click()
end
----------------------------------------
-- yes/no選択肢
----------------------------------------
function select_yesno(p)
	local s  = scr.select
	local ln = get_language(true)	-- 多言語

	-- mw
	local mwnm = s.mwnm
	local mwtx = s.mwtx
	if mwnm then message_name(mwnm) end
	if mwtx then
		chgmsg_adv()
		set_message_speed_tween(0)
		e:tag{"print", data=(mwtx[ln])}
		chgmsg_adv("close")
	end

	-- ボタン描画
	local tm = init.select_time or init.ui_fade

	-- 入力待ち
	estag("init")
	estag{"select_yesnoview"}
	estag{"uitrans", tm}
	estag{"jump", file="system/script.asb", label="select"}
	estag()
end
----------------------------------------
-- 再表示
function select_yesnoview()
	if init.select_yesno == "on" then
		local id = game.mwid..".yn"
		local s  = scr.select
		local c  = 0
		if s and s.yesno then c = 1 end
		tag{"lyprop", id=(id), visible=(c)}
		setonpush_select()
	end
end
----------------------------------------
function select_yesnoclick(e, p)
	local bt = p.btn
	local v  = scr.select
	if bt and get_gamemode('adv') then
		local v  = getBtnInfo(bt)
		local no = tn(v.p1)
		local tx = get_langsystem("yesno0"..no)

		message("通知", "『", tx, "』が選択されました", label)

		se_select()
		allkeyoff()			-- 入力禁止
		autoskip_disable()	-- autoskip一旦停止

		-- バックログの１画面分をクローズ
		set_backlog_next()
		log.stack[#log.stack].select = tx

		-- 事後処理
		exselback("selsave")	-- 前の選択肢に戻る、の情報をスタック / scr.select削除前に実行
		select_reset()			-- バッファクリア
		scr.ip.count = nil		-- カウンタリセット
		scr.flowposition = nil	-- フローチャート位置情報削除
		clickEnd(e)				-- click終了処理を通す
		ResetStack()			-- stackを空にする
		set_message_speed()		-- mspeed復帰

		set_eval('f.s='..no)
		stack_eval()			-- 更新があったのでスタックしておく

		-- 消去
		local tm = init.select_time or init.ui_fade
		init_adv_btn()			-- mwbtn再設置
		estag("init")
		estag{"uitrans", tm}
		estag{"autocache"}			-- 自動キャッシュ
		estag{"allkeyon"}			-- 入力許可
		estag{"restart_autoskip"}	-- auto/skip再開
		estag{"jump", file="system/script.asb", label="main"}
		estag()
	end
end
----------------------------------------
-- カーソル処理
function select_yesnobtn(nm)
	local bt = btn.cursor
	if bt then btn_out(e, { key=(bt) }) end

	-- active
		if nm == "lt" then btn_active("bt_yes")
	elseif nm == "rt" then btn_active("bt_no" ) end
end
----------------------------------------
-- 前の選択肢に戻る
----------------------------------------
-- bselポインタを返す
function getBselPoint()
	return init.game_selback == "on" and getVariStack("bselstack")
end
----------------------------------------
-- bsel管理
function exselback(p)
	if init.game_selback == "on" then
		local bp = getBselPoint()

		-- ファイル名を直接格納
		local v  = type(p) == "table" and p or {}
		local fl = v.file
		local lb = v.label
		if fl or lb then
			message("通知", fl, lb, "を保存しました")
			addVariStack("bselstack", { file=(fl), label=(lb) })
--			flg.eval = true

		-- 選択肢決定後
		elseif p == "selsave" and bp > 0 then
			local r = pluto.persist({}, log.stack[#log.stack])
			addVariStack("bselstack", r)
--			flg.eval = true
		end
	end
end
----------------------------------------
-- 実行
function goBackSelect()
	local v = loadVariStack("bselstack")
	local m = #v
	if m > 0 then
--		local vl = tcopy(log.vari)	-- 変数stackは残す
		reset_backlog()				-- backlogを初期化しておく
		local s = v[m]
		if type(s) == "string" then
--			log.vari = vl

			-- bsel stack巻き戻し
			local ls = pluto.unpersist({}, s)
			local no = ls.bsel
			if no then delBackSelect(no) end

			-- 変数を捨てる
			local vl = ls.eval
			if vl then get_stack_eval(vl) end

			-- logに書き込んで呼び出し
			table.insert(log.stack, ls)
			quickjumpui(#log.stack, "bsel")		-- quickjump
		elseif s then
			ResetStack()				-- スタックリセット
			notification_clear()		-- 通知消去
			scr.ip = nil				-- 念の為ipリセット

			-- 選択肢
			if scr.select then
				select_reset()			-- reset
				set_message_speed()		-- mspeed復帰
			end

			local time = init.ui_fade
			local s = flg.sysvoid
			estag("init")
			estag{"allsound_stop", { mode="system", time=(time) } }
			estag{"uimask_on"}			-- mask
			estag{"uitrans", time}
			if s then
				estag{"wait", se=(s), input="0"}	-- sysvo待機
			end
			estag{"adv_reset"}			-- adv reset
			estag{"autoskip_init"}		-- auto/skip reset
			estag{"init_adv_btn"}		-- ボタン再設定
			estag{"uimask_off"}			-- mask
			estag{"gotoScript", v[1]}
			estag()
		else
			message("注意", "これ以上戻れません")
		end
	end
end
----------------------------------------
-- bsel stack巻き戻し
function delBackSelect(no)
	if init.game_selback == "on" and no > 0 then
		local v = loadVariStack("bselstack")
		for i=#v, no+1, -1 do table.remove(v, i) end
		saveVariStack("bselstack", v)
	end
end
----------------------------------------
-- 次の選択肢に進む
----------------------------------------
function goNextSelect()
	local time = init.ui_fade

	allkeyoff()						-- 全キー無効化
	autoskip_ctrl()					-- ctrl無効化
	delImageStack()					-- cache開放

	-- 全音停止
	estag("init")
	local s = flg.sysvoid
	estag{"allsound_stop", { mode="system", time=(time) } }
	estag{"notification_clear"}				-- 通知消去

	-- 共通消去
	estag{"uimask_on"}						-- mask
	estag{"uitrans", time}
	if s then
		estag{"wait", se=(s), input="0"}	-- sysvo待機
	end
	estag{"adv_reset"}						-- adv reset
	estag{"wait", time="20", input="0"}
--	estag{"sesys_stop", "sysse"}			-- sysseを止めておく
	estag{"sesys_reset"}
	estag{"goNextSelectLoop"}
	estag()
end
----------------------------------------
-- debugSkip版
function goNextSelectLoop()
	scr.face = nil			-- mwfaceのテーブルが残っていると停止時にエラーが出るので削除
	flg.exskip = true
	mwline_exskip()			-- line初期化
	e:debugSkip{ index=99999 }
end
----------------------------------------
