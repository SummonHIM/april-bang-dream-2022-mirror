----------------------------------------
-- artemis tag 短縮/拡張
----------------------------------------
function tag(p)
	if p.eq then e:enqueueTag(p)
	else		 e:tag(p) end
end
----------------------------------------
function eqtag(p) e:enqueueTag(p) end
----------------------------------------
-- デバッグメッセージ関数
----------------------------------------
-- ■ 実行ファイルをcaptionに表示
function setCaption()
	if debug_flag then debug_caption() end
end
----------------------------------------
-- デバッグ用メッセージ。コンソールに表示
function sysmessage(...) if debug_flag then debug_message(1, ...) end end
function message(...)	 if debug_flag then debug_message(2, ...) end end
function debmessage(...) if debug_flag then debug_message(3, ...) end end
----------------------------------------
-- debugフォルダがなくても表示できるもの／e:debug()を本文中に残さないようにする
function debugprint(text)
	if init.debug == "on" then e:debug{ data=(text), raw=true, level=2 } end
end
----------------------------------------
function print_r(...)
	if debug_flag then print_table(...) end
end
----------------------------------------
-- エラー
function error_message(...)
	if debug_flag then debug_errormessage(...) end
end
----------------------------------------
-- 汎用関数
----------------------------------------
function game_run()		e:setScriptStatus(0) end	-- RUN
function game_click()	e:setScriptStatus(1) end	-- WAIT_CLICK
--function game_trans()	e:setScriptStatus(2) end	-- WAIT_TRANS
function game_stop()	e:setScriptStatus(3) end	-- STOP
----------------------------------------
function tn(n) return tonumber(n) end
function ts(n) return tostring(n) end
----------------------------------------
function reset() e:tag{"reset"} end
----------------------------------------
-- ■ fullscreen on
function fullscreen_on()
	local md = game.os
	local cw = conf.window
	if md == "windows" then
		e:tag{"var", name="t.screen", system="fullscreen"}
		local s = e:var("t.screen")
		if cw == 1 and s == "0" then e:tag{"exec", command="fullscreen"} end
	elseif md == "wasm" then
		if cw == 1 and wasm then wasm.exec("setScreenFull") end
	end
end
----------------------------------------
-- ■ fullscreen off
function fullscreen_off()
	local md = game.os
	local cw = conf.window
	if md == "windows" then
		e:tag{"var", name="t.screen", system="fullscreen"}
		local s = e:var("t.screen")
		if cw == 0 and s == "1" then e:tag{"exec", command="fullscreen"} end
		setWindowsScreenSize()			-- windows size
	elseif md == "wasm" then
		if cw == 0 and wasm then wasm.exec("setScreenWindow") end
	end
end
----------------------------------------
-- ■ mouse autohide
function mouse_autohide()
	if game.trueos == "windows" then
		local s = conf.cursor or -1
		if s == -1 then		e:tag{"mouse", hide="0", autohide="0"}
		elseif s == 0 then	e:tag{"mouse", hide="1", autohide="0"}
		else				e:tag{"mouse", hide="0", autohide=(s)} end
	end
end
----------------------------------------
-- ■ mouse reset
function mouse_reset()
	if game.trueos == "windows" then
		local m = e:getMousePoint()
		eqtag{"mouse", left=(game.width), top=(game.height)}
		eqwait()
		eqtag{"mouse", left=(m.x), top=(m.y)}
	end
end
----------------------------------------
-- ■ get_langsystem
function get_langsystem(nm)
	local r = nil
	local s = getLangHelp("system")
	if s and s[nm] then r = s[nm] end
	return r
end
----------------------------------------
-- ■ get_gamever
function get_gamever()
	local r = ""
	local t = get_langsystem("gamever")
	if t then
		r = t
	else
		local z = init.system or {}
		local s = z.game_ver or init["game_ver_"..game.os]
		if s then r = s end
	end
	return r
end
----------------------------------------
-- ■ get_gametitle
function get_gametitle()
	local r = ""
	local t = get_langsystem("gametitle")
	if t then
		r = t
		local tr = get_langsystem("gametitle_trial")
		if getTrial() and tr then r = r..tr end
	else
		r = getTrial() and init.game_trialtitle or init.game_title or ""
	end
	return r
end
----------------------------------------
-- ■ set_caption
function set_caption(n)
	if not n and debug_flag then
		debug_caption()
	elseif game.trueos == "windows" then
		local tx = get_gametitle()
		local v  = get_gamever()
		if init.game_ver == "on" and v then tx = tx.." - Ver"..v end

		local tt = sv.changesavetitle()
		if init.game_titlebar == "on" and tt then tx = tx.." 『"..(tt).."』" end

		if type(n) == "string" then tx = tx..n end
		e:tag{"caption", data=(tx)}
	end
end
----------------------------------------
-- ■ utf8 to sjis
function code_sjis(n)
	return e:convertEncoding({ from="utf8", to="sjis", source=(n) })
end
----------------------------------------
-- ■ sjis to utf8
function code_utf8(n)
	return e:convertEncoding({ from="sjis", to="utf8", source=(n) })
end
----------------------------------------
-- ■ system pathをsjisにして返す
function getspath(n)
	return code_sjis(e:var(n))
end
----------------------------------------
-- ■ getver関数
function getver(n, f)
	local r = f and e:var(n) or tn(e:var(n))
	return r
end
----------------------------------------
-- ■ getScale関数 / 倍率変換
function getScale(n)
	if n and game.scale then n = math.floor(n * game.scale) end
	return n
end
----------------------------------------
-- ■ getSkip関数 / スキップ状態を確認
function getSkip(ef)
	local ret = flg.exskip or flg.skip
	if ef and conf.effect == 0 then ret = true end
	if not ret then
		local s = tn(e:var("s.status.controlskip"))
		if s == 1 then ret = true end
	end
	return ret
end
----------------------------------------
-- ■ 現在時刻をunixtimeで返す
function get_unixtime()
	local r = nil
	e:tag{"var", name="t.ux", system="delete"}
	e:tag{"var", name="t.ux", system="date"}
	local y = tn(e:var("t.ux.year"))
	local m = tn(e:var("t.ux.month"))
	local d = tn(e:var("t.ux.day"))
	local h = tn(e:var("t.ux.hour"))
	local t = tn(e:var("t.ux.minute"))
	local s = tn(e:var("t.ux.second"))
	local r = { y, m, d, h, t, s }
	return r
end
----------------------------------------
-- ■ unixtimeをformatに従って返す
function get_osdate(form, p)
	local r = form
	local n = type(p)
	if n == "table" then
		-- 年
		if r:find("%%Y") then r = r:gsub('%%Y', string.format("%04d", p[1])) end
		if r:find("%%y") then r = r:gsub('%%y', ts(p[1]):sub(3)) end

		-- 月
		if r:find("%%m") then r = r:gsub('%%m', string.format("%02d", p[2])) end

		-- 日
		if r:find("%%d") then r = r:gsub('%%d', string.format("%02d", p[3])) end
		if r:find("%%e") then r = r:gsub('%%e', p[3]) end

		-- 時
		if r:find("%%H") then r = r:gsub('%%H', string.format("%02d", p[4])) end
		if r:find("%%k") then r = r:gsub('%%k', p[4]) end

		-- 分
		if r:find("%%M") then r = r:gsub('%%M', string.format("%02d", p[5])) end

		-- 秒
		if r:find("%%S") then r = r:gsub('%%S', string.format("%02d", p[6])) end
	elseif n == "number" then
		r = os.date(form, p)
	else
		r = "none"
	end
	return r
end
----------------------------------------
-- ■ get_psswap関数 / 	PS専用 0:○ 1:×
function get_psswap()
	local r = nil
	if game.ps and (deb and deb.swap or e:var("s.enterbuttonassign") == "1") then r = true end
	return r
end
----------------------------------------
-- ■ rand関数 / 0～no-1 のランダム値を返す
function rand(no)
	return e:random() % no
end
----------------------------------------
-- ■ percent関数 / numがmaxの何％か算出
function percent(num, max)
	local r = 0
	if num and max then r = math.ceil(100 * num / max)
	else message("エラー", "numもしくはmaxの値が不正です num:"..type(num).." max:"..type(max)) end
	return r
end
----------------------------------------
-- ■ repercent関数 / perから算出
function repercent(per, max)
	local r = 0
	if per and max then r = math.floor(per * max / 100)
	else message("エラー", "perもしくはmaxの値が不正です per:"..type(per).." max:"..type(max)) end
	return r
end
----------------------------------------
-- ■ addsubloop関数 / 加減算超過
function addsubloop(num, add, min, max, flag)
	local a = add < 0 and -add or add	-- 正変換
	local c = max / a					-- しきい値
	local r = num + add
	if not flag and a == 1 then			-- 1ずつ加減算
			if r < min	then r = max
		elseif r > max	then r = min end
	elseif flag or c <= 1 then			-- しきい値1以下
			if r < min	then r = min
		elseif r > max	then r = max end
	elseif add > 0 and r == max + add then r = min
	elseif add < 0 and r == min + add then r = max
	elseif r < min		then r = min
	elseif r > max		then r = max
	end
	return r
end
----------------------------------------
-- ■ NumToGrph関数 / 数値を桁ごとに分解(２桁)
function NumToGrph(num)
	local ah = math.floor(num / 10)
	local al = num % 10
	return { ah, al }
end
----------------------------------------
-- ■ NumToGrph関数 / 数値を桁ごとに分解(３桁)
function NumToGrph3(num)
	local dl = 0
	if num >= 100 then
		dl  = math.floor(num / 100)
		num = num % 100
	end
	local ah = math.floor(num / 10)
	local al = num % 10
	return { dl, ah, al }
end
----------------------------------------
-- ■ tcopy関数
function tcopy(old)
	local t = {}
	if old then 
		for k,v in pairs(old) do t[k] = v end
	end
	return t
end
----------------------------------------
-- ■ tcopy2関数
function tcopy2(old)
	local t = {}
	if old then
		for k,v in pairs(old) do
			if type(v) == 'table' then	t[k] = tcopy2(v)
			else						t[k] = v end
		end
	end
	return t
end
----------------------------------------
-- ■ split関数
function split(str, delim)
    -- Eliminate bad cases...
	if not str then
		return {}
    elseif not str:find(delim) then
        return { str }
    end

    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local lastPos
    for part, pos in string.gfind(str, pat) do
        table.insert(result, part)
        lastPos = pos
    end
    table.insert(result, string.sub(str, lastPos))
    return result
end
----------------------------------------
-- ■ string.sub to utf-8関数
function utf8sub(tx, no)
	local c = no * 3
	local r = tx:sub(1, c)

	-- 最後の文字をチェック
	local m = r:len()
	local s = r:sub(-3)
	local s1 = string.byte(s:sub(1, 1))
	local s2 = string.byte(s:sub(2, 2))
	local s3 = string.byte(s:sub(3, 3))
	-- １バイト文字　0x00-0x7F
	-- ２バイト文字　0xC0-0xDF
	-- ３バイト文字　0xE0-0xE3(0xEF)
	-- ４バイト文字　0xF0～
	if s1 >= 0xf0 then		r = r:sub(1, -4)		-- １バイトめが４バイト以上の文字は切る
	elseif s2 >= 0xe0 then	r = r:sub(1, -3)		-- ２バイトめが３バイト以上の文字は切る
	elseif s3 >= 0xc0 then	r = r:sub(1, -2) end	-- ３バイトめが２バイト以上の文字は切る
	return r
end
----------------------------------------
-- ■ mb_substr関数
function mb_substr(s, c1, c2)
	return utf_substr(s, c2)
--[[
	local r = s
	if r and r ~= "" and c1 then
		r = r:gsub(" +", " ")
		r = r:gsub("%$", "＄")
		r = r:gsub("!", "！")
		r = r:gsub("?", "？")
		local mx = #r					-- 現在の文字数
		local hd = c1 or 1				-- 先頭位置
		local ct = c2 and c2 * 2 or mx	-- カット文字数
		if ct < mx then
			local tx = code_sjis(r):sub(hd, ct)		-- 一旦sjisに変換して文字をカット

			-- 1byteずつ取り出して文字確認
			local f = nil
			for i=1, ct do
				local d = string.byte(tx:sub(i, i))
				if not d then

				-- 半角
				elseif d <= 0x7f then
					f = nil

				-- 第1バイト	0x81-0x9F / 0xE0-0xFC
				elseif not f and (d >= 0x81 and d <= 0x9F or d >= 0xE0 and d <= 0xFC) then
					f = true

				-- 第2バイト	0x40-0x7E / 0x80-0xFC
				elseif f and (d >= 0x40 and d <= 0x7E or d >= 0x80 and d <= 0xFC) then
					f = nil
				end
			end
			if f then tx = tx:sub(1, -2) end	-- 第1バイトで終了したらカット
			r = code_utf8(tx)
		end
	end
	return r
]]
end
----------------------------------------
-- ■ utf_substr関数 / 半角を1、全角を2として先頭からnumまで切り出す
function utf_substr(tx, num)
	local r = tx
	local m = #r
	if num and m > num then
		local c = 0
		local s = 1
		repeat
			local d = string.byte(tx:sub(s, s))
			if not d then
				break

			-- 1byte
			elseif d <= 0x7f then
				c = c + 1
				s = s + 1
				if c > num then s = s - 1 end

			-- 2byte
			elseif d >= 0x80 and d <= 0xdf then
				c = c + 2
				s = s + 2
				if c > num then s = s - 2 end

			-- 3byte
			elseif d >= 0xe0 and d <= 0xef then
				c = c + 2
				s = s + 3
				if c > num then s = s - 3 end

			-- 4byte
			elseif d >= 0xf0 and d <= 0xf7 then
				c = c + 2
				s = s + 4
				if c > num then s = s - 4 end

			-- 5byte
			elseif d >= 0xf8 and d <= 0xfb then
				c = c + 2
				s = s + 5
				if c > num then s = s - 5 end

			-- 6byte
			elseif d >= 0xfc and d <= 0xfd then
				c = c + 2
				s = s + 6
				if c > num then s = s - 6 end

			else
				message("通知", "文字分割を中止します")
				s = m
				break
			end
		until c >= num

		-- cut
		r = r:sub(1, s - 1)
	end
	return r
end
----------------------------------------
-- ■ explode関数
function explode(d, t)
	return split(t, d)
end
----------------------------------------
-- ■ implode関数
function implode(d, t, flag)
	local str = t and "" or nil
	if str then
		local c = true
		if flag then
			for k, v in pairs(t) do
				if c then str = str..k.."="..v
				else	  str = str..d..k.."="..v end
				c = nil
			end
		else
			for k, v in ipairs(t) do
				if c then str = str..v
				else	  str = str..d..v end
				c = nil
			end
		end
	end
	return str
end
----------------------------------------
-- ■ calltag関数
function calltag(p, func)
	local text = p[1] or "dialog"
	for k, v in pairs(p) do
		if k ~= 1 then text = text..","..k..","..v end
	end
--	e:tag{"var", name="t.tagtext", data=(text)}
--	if not func then
		tag{"tag", data=(text)}
--		e:tag{"call", file="system/ui.asb", label="calltag"}
--	else
--		e:tag{"var", name="t.tagcall", data=(func)}
--		e:tag{"call", file="system/ui.asb", label="calltag2"}
--	end
end
----------------------------------------
-- ■ tag_dialog
function tag_dialog(p, func, data)
	allkeyoff()
	allkeystopex = true
	estag("init")
	estag{"tag_dialogmain", p}
	estag{"tag_dialogexit"}
	if func then estag{func, data} end
	estag()
end
----------------------------------------
function tag_dialogmain(p)
	local z  = getLangHelp("dlgmes")
	local r  = {"dialog"}
	local sw = {
		title = function(dt)
			local tl = dt or getTrial() and init.game_trialtitle or init.game_title
			return z and tl and z[tl] or tl
		end,
		message = function(dt)
			return z and dt and z[dt] or dt
		end,
	}

	-- [num]処理
	local no = p.num
	p.num = nil

	-- loopして置換
	for nm, dt in pairs(p) do
		if sw[nm] then
			r[nm] = sw[nm](dt)
		else
			r[nm] = dt
		end
	end

	-- [num]置換
	if no then
		if r.title   then r.title   = r.title  :gsub("%[num%]", no) end
		if r.message then r.message = r.message:gsub("%[num%]", no) end
	end
	tag(r)
end
----------------------------------------
function tag_dialogexit()
	allkeyon()
	allkeystopex = nil
end
----------------------------------------
-- ■ maxn関数 / tableの中身をカウントする
function tmaxn(param)
	local count = 0
	for key, val in pairs(param) do count = count + 1 end
	return count
end
----------------------------------------
-- ■ RGB変換 / R,G,B→RGB
function getRGB(r, g, b)
	return DecToHex(r)..DecToHex(g)..DecToHex(b)
end
----------------------------------------
-- ■ dec to hex
function DecToHex(no)
	return string.format("%02X", no)
end
----------------------------------------
-- ■ tableJoin関数
function tableJoin(tbl)
	return tJoin(tbl, 1, "")
end
function tJoin(tbl, count, text)
	local ret = text
	for key, val in pairs(tbl) do
		local t = type(val)
		local d = "{"..count.."}"
		local r = true

		if t == "table" then
			ret = ret..key.."<>tbl".."<>{"..(count+1).."}"..tJoin(tbl[key], count+1, ret)

		elseif t == "nil" then
			ret = ret..key.."<>nil"

		elseif t == "number" then
			ret = ret..key.."<>num<>"..val

		elseif t == "string" then
			ret = ret..key.."<>str<>"..val

		elseif t == "boolean" then
			if val then	ret = ret..key.."<>bool<>true"
			else		ret = ret..key.."<>bool<>false" end

		elseif t == "function" then r = nil error_message("functionは結合未対応です")
		elseif t == "thread"   then r = nil error_message("threadは結合未対応です")
		elseif t == "userdata" then r = nil error_message("userdataは結合未対応です")
		end
		if r then ret = ret..d end
	end
	return ret
end
----------------------------------------
-- ■ tableSplit関数
function tableSplit(tbl, count)
	local ret = {}
	local c = count or 1
	local r = "{"..c.."}"
	local ax = split(tbl, r)
	for key, val in pairs(ax) do

message(key, val)

	end
	return ret
end
----------------------------------------
-- ■ table_to_string関数
function table_to_string(p, f)
	local s = tts(p, "", "_")
	if f then
		e:tag{"var", system="url_encode", name="t.tempurl", source=(s)}
		s = e:var("t.tempurl")
	end
	return s
end
function tts(p, r, px)
	for k, v in pairs(p) do
		local n = type(v)
		if type(k) == "number" then k = k.."{n}" end
			if n == "nil"	 then r = r..n.."{:}"..px.."{:}"..k.."{}"
		elseif n == "number" then r = r..n.."{:}"..px.."{:}"..k.."{:}"..v.."{}"
		elseif n == "string" then r = r..n.."{:}"..px.."{:}"..k.."{:}"..v.."{}"
		elseif n == "table"  then
			r = r..n.."{:}"..px.."{:}"..k.."{}"
			r = tts(v, r, px.."{/}"..k)
		end
	end
	return r
end
----------------------------------------
-- ■ string_to_table関数
function string_to_table(n, f)
	local s = n
	if f then
		e:tag{"var", system="url_decode", name="t.tempurl", source=(s)}
		s = e:var("t.tempurl")
	end

	-- 分離
	local st = function(r, b)
		local px = b[2]
		local k  = b[3]
		local v  = b[4]
		if k:find("{n}")	then k = tn(k:gsub("{n}", "")) end
		if b[1] == "number" then v = tn(v) end
		if px and px:find("{/}") then
			local c = explode("{/}", b[2])
			for i=2, #c do
				if c[i]:find("{n}") then c[i] = tn(c[i]:gsub("{n}", "")) end
			end
			if c[2] and not r[c[2]]					  then r[c[2]] = {} end
			if c[3] and not r[c[2]][c[3]]			  then r[c[2]][c[3]] = {} end
			if c[4] and not r[c[2]][c[3]][c[4]]		  then r[c[2]][c[3]][c[4]] = {} end
			if c[5] and not r[c[2]][c[3]][c[4]][c[5]] then r[c[2]][c[3]][c[4]][c[5]] = {} end

			-- 保存
			if k and v then
					if c[5] then r[c[2]][c[3]][c[4]][c[5]][k] = v
				elseif c[4] then r[c[2]][c[3]][c[4]][k] = v
				elseif c[3] then r[c[2]][c[3]][k] = v
				elseif c[2] then r[c[2]][k] = v end
			end
		elseif k and v then
			r[k] = v
		end
		return r
	end

	-- loop
	local r = {}
	local a = explode("{}", s)
	for i, v in pairs(a) do
		local b = explode("{:}", v)
			if b[1] == "string" then r = st(r, b)
		elseif b[1] == "number" then r = st(r, b)
		elseif b[1] == "table"  then r = st(r, b)
		end
	end
	return r
end
----------------------------------------
-- ■ GetStack
function GetStack()
	local ss = e:getScriptStack()
	console("--------------------------------")
	for i=table.maxn(ss), 1, -1 do message(i, ss[i].file) end
	console("--------------------------------")
	return table.maxn(ss)
end
----------------------------------------
-- ■ ResetStack
function ResetStack()
	local ss = e:getScriptStack()
	for i=1, #ss-1 do tag{"return"} end
	estag("reset")	-- estagもリセットしておく
end
----------------------------------------
-- ■ releaseStack / handler開放
function releaseStack()
	local ss = e:getScriptStack()
	if #ss > 1 then
		local rc = ss[#ss-1].reservedCommands
		local p  = rc and rc[#rc] and rc[#rc].parameter
		if p and p.handler then
			e:tag{"return"}
			message("通知", p["function"], "のスタックを開放しました")
		end
	end
end
----------------------------------------
-- ■ StackCount
function StackCount(word)
	local count = 0
	local ss = e:getScriptStack()
	for i=table.maxn(ss), 1, -1 do 
		if string.find(ss[i].file, word) then count = count + 1 end
	end
	return count
end
----------------------------------------
-- ■ ReturnStack
function ReturnStack(file)
	local ss = e:getScriptStack()
	for i=table.maxn(ss), 1, -1 do
		if file and ss[i].file == file then e:tag{"return"}
		elseif		ss[i].file == ""   then e:tag{"return"}
		else break end
	end
end
----------------------------------------
-- system
----------------------------------------
-- wait
function wait(p, eq)
	if flg.skip then return end								-- skip中は実行しない
	if type(p) ~= "table" then p = { time=p } end			-- table以外ならtimeに代入
	if not p.se then p.time = p.time or p["0"] or 0 end		-- time がなければ 0

	-- input
	local tm = tn(p.time)
	local ip = p.input or 1									-- inputがなければ 1
	if flg.ui and tm == 0 then ip = 0 end					-- uiかつtime=0の場合はinput=0に設定しておく
	p.input = ip
	p.eq = p.eq or eq
	p[1] = "wait"
	tag(p)
end
----------------------------------------
function eqwait(p) wait(p, true) end
function tags.wait(e, p) eqwait(p) return 1 end
function tags.wtx(e, p)	 eqwait{ scenario="1" } return 1 end
function tags.wt0(e, p)	 eqwait{ time=(0), input="0" } return 1 end
----------------------------------------
-- system wait
function syswait(p)
	local v = {"wait"}
	if type(p) == 'table' then
		v.time  = p.time  or 0
		v.input = p.input or 1
	else
		v.input = p or 1
	end
	eqtag(v)
end
----------------------------------------
function wt(w) syswait(w) end
function tags.wt(e, p) syswait(p) return 1 end
----------------------------------------
