----------------------------------------
-- SE System / 全管理
----------------------------------------
local sesys = {}
----------------------------------------
local extag = {
	"id",		-- 0～9を指定します。
	"time",		-- フェード時間を指定します。再生時はフェードイン、停止時はフェードアウトとなります。
	"vol",		-- 音量を指定します。0～100の範囲となります。
	"pan",		-- パンを指定します。L:-100～0～100:Rの範囲となます。
	"ptime",	-- パンが有効になるまでの時間です。
	"loop",		-- 1を指定するとループ再生します。初期値は単発です。
	"count",	-- 繰り返し数を指定します。
--	"stop",		-- 1を指定するとseを停止します。
	"sync",		-- 1を指定するとse再生終了を待機します。
}
----------------------------------------
-- sesys reset
function sesys_reset()
	scr.sesys = {
		buff  = {},		-- 管理バッファ
		voice = {},		-- ボイス制御
		count = 0,		-- カウンタ
	}
	scr.voice = {
		stack	= {},		-- 発生中のボイスタグ
	}
	scr.vo = nil	-- vo
--	if not flag then scr.lvo = {} end	-- bgv

	-- 初期化
	local m = game.se_track
	for i=1, m do
		tag{"sestop", id=(i)}
		tag{"var", name=("s.segain."..i), data="950"}		-- 使用するチャネルは1000で埋めておく
	end
end
----------------------------------------
-- 再生管理
function sesys_play(mode, file, p)
	----------------------------------------
	-- debug / ファイルの存在確認
	if debug_flag and not isFile(file) then
		sysmessage("error", file, "は存在しません") 
		return
	end

	----------------------------------------
	-- idが埋まっているときは再生せず抜ける
	local id = tn(p.lkid) or sesys.getid() if not id then return end
	local s  = scr.sesys.buff[id] or {}

	----------------------------------------
	-- 取得
	local sync = tn(p.sync)	== 1			-- sync
	local loop = tn(p.loop or 0)			-- loop
	local skbl = p.skippable				-- skippable
	if loop == 1 then skbl = 0 end

	-- skip中の処理分岐
	local skip = getSkip()
	local tbl  = { sysse=1, sysvo=1 }		-- skipで抜けないものをリスト化
	if not tbl[mode] then
		local flag = not p.lkid and file == s.file
		if skip and loop == 0 and not flag then return end
	end

	----------------------------------------
	-- 音量
	local z    = init.secat or {}
	local ch   = p.ch
	local vol  = p.vol or s.vol or 100
	local cat  = p.cat
	local gain = 100

	-- カテゴリ音量
	if cat and z[cat] then
		local n1 = conf["fl_"..cat]
		local n2 = conf[cat] or 100
		if n1 == 0 then
			gain = 0
		else
			-- base音量が指定されていた場合、そちらも参照する
			local ba = z[cat].base or "none"
			if ba ~= "none" and conf[ba] then
				local n3 = conf["fl_"..ba]
				if n3 == 0 then
					gain = 0
				else
					gain = sesys.getvol(cat, conf[ba], vol)	-- conf[cat] / conf[base]から音量算出 / 10倍する
				end

			-- base音量なし
			else
				gain = sesys.getvol(cat, vol)				-- conf[cat]から音量算出 / 10倍する
			end
		end

	-- 音声
	elseif mode == "voice" then
		if not ch then return end
		local vc = csv.voice[ch]
		local cx = vc and vc.mob or ch						-- mob変換
		local n1 = conf["fl_"..cx]
		local n2 = conf[cx]
		if n1 == 0 then
			gain = 0
		else
			if vc and vc.vol then
				gain = sesys.getvol(mode, n2, vol, vc.vol)	-- conf[mode]から音量算出
			else
				gain = sesys.getvol(mode, n2, vol)			-- conf[mode]から音量算出
			end
		end

	-- lvo
	elseif mode == "lvo" then
		if not ch then return end
		local lv = init.game_bgvvolume == "on"
		local n1 = lv and conf["fl_lvo"..ch] or conf["fl_"..ch]
		local n2 = lv and conf["lvo"   ..ch] or conf[ch]
		if n1 == 0 then
			gain = 0
		else
			gain = sesys.getvol(mode, n2, vol)	-- conf[mode]から音量算出 / 10倍する
		end

	-- se
	elseif mode == "se" then
		local id = p.id
		local md = mode
		local ss = init.sevol or {}				-- conf.seから書き換える
		if ss[id] then md = ss[id] end
		gain = sesys.getvol(md, vol)			-- conf[mode]から音量算出 / 10倍する
	else
		gain = sesys.getvol(mode, vol)			-- conf[mode]から音量算出 / 10倍する
	end
--	if gain == 0 then return end				-- 抜けてしまうとconfig終了時にloopseが復帰できなくなる

	----------------------------------------
	-- pan
	local pan	= p.pan or s.pan or 0
	if mode == "voice" then pan = sesys.fgpan(pan, p) end
	local panz	= sesys_pan(pan)			-- pan 左-1000 中0 右1000
	local ptime	= p.ptime or 0				-- pan time
	local time	= p.time					-- time
	if skip then time = 0 ptime = 0 end

	----------------------------------------
	-- 既に同ファイル再生中
	if file == s.file then

		-- gain
		if p.vol then
			tag{"sefade", id=(id), gain=(gain), time=(time)}
			scr.sesys.buff[id].vol = vol

			if sync and time > 0 then eqwait(time) end
		end

		-- pan
		if p.pan then
			tag{"sepan", id=(id), pan=(pan), time=(ptime)}
			scr.sesys.buff[id].pan = pan

			if sync and ptime > 0 then eqwait(ptime) end
		end

	----------------------------------------
	-- ファイル再生
	else
		-- lip sync
		if mode == "voice" and emote then emote.readlipcsv(file, ch) end

--		message("再生", mode, file, id, skbl, gain)

		-- PS4は無音ファイルを一瞬置くことで安定する
		if game.os == "ps4" then tag{"seplay", id=(id), file=":sysse/ps4.ogg", gain=(gain), time="0"} end
		tag{"seplay", id=(id), file=(file), gain=(gain), time=(time or 0), loop=(loop), skippable=(skbl), buffer=(sesys_getbuffer(p))}
		if panz ~= 0 then tag{"sepan", id=(id),  pan=(panz), time=(ptime)} end

		-- syncセット
		local ns = p.nosave
		if sync and loop == 0 then
			eqwait{ se=(id) }
			eqtag{"sestop", id=(id)}

		-- exitok専用処理
		elseif ns == "exitok" then
			flg.sysvoid = id

		-- 保存
		elseif not ns then
			scr.sesys.buff[id] = {
				mode = mode,		-- 再生モード
				file = file,		-- 再生ファイル
				vol  = vol,			-- 音量
				pan  = pan,			-- パン
				loop = loop,		-- ループ情報
				id   = tn(p.id),	-- script ID
				lock = p.lock,		-- ボリュームコントロールoff
				ch   = p.ch,		-- キャラ
				nvol = gain,		-- 音量 / 現在値
				cat  = cat,			-- カテゴリ
			}

			-- 複数回再生count処理
			local ct = p.count
			if ct then
				if not flg.secount then flg.secount = {} end
				ct = ct - 1
				if ct > 0 then
					p.count = ct
					flg.secount[id] = p
					tag{"setonsoundfinish", fl=(file), id=(id), md=(mode), ct=(ct), handler="calllua", ["function"]="sesys_secount"}
				else
					flg.secount[id] = nil
					scr.sesys.buff[id] = nil
				end

			-- 再生後処理
			else
				-- 無音のときは実行しない
				if gain == 0 then

				elseif mode == "voice" then
					bgm_vofadeout()			-- bgm fadeout
					sesys.lvofadeout(p)		-- lvo fadeout
				elseif mode == "sysvo" then
					flg.sysvoid = id
				end

				-- 再生終了処理
				tag{"setonsoundfinish", id=(id), handler="calllua", ["function"]="sesys_voiceend"}
			end
		end
	end
end
----------------------------------------
-- 複数回再生count
function sesys_secount(e, p)
	local id = tn(p.id)
	local ct = tn(p.ct)
	local v  = flg.secount
	local s  = scr.sesys and scr.sesys.buff or {}
	if v and v[id] and s[id] then
		scr.sesys.buff[id].file = nil		-- 同名ファイルチェックを潰しておく
		sesys_play(p.md, p.fl, { lkid=(id), count=(ct) })
	end
end
----------------------------------------
-- タグ再生共通
function sesys_playtag(mode, file, d, p)
	local t = d or {}
	if p then
		for i, nm in ipairs(extag) do
			if p[nm] then t[nm] = p[nm] end
		end
	end
	t.sync = d and d.wait or p and p.wait or t.sync
	sesys_play(mode, file, t)
end
----------------------------------------
-- 
----------------------------------------
-- SE再開
function sesys_resume()
	local s = scr.sesys.buff
	scr.sesys.buff = {}
	for i, v in pairs(s) do
		local lp = v.loop
		if lp == 1 then
			sesys_play(v.mode, v.file, { ch=(v.ch), id=(v.id), vol=(v.vol), pan=(v.pan), loop=(lp), cat=(v.cat) })
		end
	end
end
----------------------------------------
-- 停止 / 終了
----------------------------------------
-- ボイス再生終了
function sesys_voiceend(e, p) sesys_endclear(tn(p.id)) end
----------------------------------------
-- 再生終了処理
function sesys_endclear(id)
	local o  = scr.sesys.buff[id]	if not o then return end
	local md = o.mode

	----------------------------------------
	-- データ削除
	scr.sesys.buff[id] = nil

	-- sysvo
	local s = flg.sysvoid
	if s and s == id then flg.sysvoid = nil end

	----------------------------------------
	-- voice処理
	if md == "voice" then
		local s = scr.sesys.buff
		local c = 0
		for i, v in pairs(s) do
			if v.mode == "voice" then
				if emote then emote.lipstop(v) end
				c = c + 1
			end
		end

		-- bgm音量を戻す
		if c == 0 then
			bgm_vofadein()		-- bgm fadein
			sesys.lvofadein(o)	-- lvo fadein
		end
	end
end
----------------------------------------
-- 停止処理
function sesys_stop(tbl)
	local t  = type(tbl)
	local p  = t == "table" and tbl or t == "string" and { mode=(tbl) } or t == "number" and { time=(tbl) } or {}
	local tm = getSkip() and o or p.time or 0
	local md = p.mode or "all"
	local ch = p.ch			-- voice char
	local sx = p.id			-- se id

	-- emote / lipsync停止
	if emote and md == "pause" then emote.lipskip() end

	-- 停止時に[delonsoundfinish]を実行しておく
	local stopse = function(id, tm, sync)
		tag{"delonsoundfinish", id=(id)}
		if sync then
			eqtag{"wait", se=(id), input="1"}
			eqtag{"sestop", id=(id), time=(tm)}
		else
			tag{"sestop", id=(id), time=(tm)}
		end
	end

	-- 振り分け
	local sw = {

		----------------------------------------
		-- all stop
		all = function(id)
			stopse(id, tm)
			sesys_endclear(id)
		end,

		----------------------------------------
		-- sysse/sysvo以外を全部止める
		system = function(id, v)
			local md = v.mode
			if md ~= "sysse" and md ~= "sysvo" then
				stopse(id, tm)
				sesys_endclear(id)
			end
		end,

		----------------------------------------
		-- pause
		pause = function(id, v)
			local md = v.mode
			if md ~= "sysse" then
				stopse(id, tm)
			end
			if v.loop ~= 1 then sesys_endclear(id) end
		end,

		----------------------------------------
		-- se
		se = function(id, v, sync)
			if v.mode == "se" then
				local ix = v.id
				if sx then
					if sx == ix or sx == -1 then
						stopse(id, tm, sync)
						sesys_endclear(id)
					end
				else
					stopse(id, tm, sync)
					sesys_endclear(id)
				end
			end	
		end,

		----------------------------------------
		-- sysse
		sysse = function(id, v, sync)
			if v.mode == "sysse" then
				local ix = v.id
				if sx then
					if sx == ix then
						stopse(id, tm, sync)
						sesys_endclear(id)
					end
				else
					stopse(id, tm, sync)
					sesys_endclear(id)
				end
			end	
		end,

		----------------------------------------
		-- voice
		voice = function(id, v, sync)
			if v.mode == "voice" then
				local cx = v.ch
				if ch then
					if ch == cx then
						stopse(id, tm, sync)
						sesys_endclear(id)
					end
				else
					stopse(id, tm, sync)
					sesys_endclear(id)
				end
			end
		end,

		----------------------------------------
		-- lvo
		lvo = function(id, v, sync)
			if v.mode == "lvo" then
				local cx = v.ch
				if ch then
					if ch == cx then
						stopse(id, tm, sync)
						sesys_endclear(id)
					end
				else
					stopse(id, tm, sync)
					sesys_endclear(id)
				end
			end
		end,

		----------------------------------------
		-- sysse
		sysse = function(id, v, sync)
			if v.mode == "sysse" then
				stopse(id, tm, sync)
				sesys_endclear(id)
			end
		end,

		----------------------------------------
		-- sysvo
		sysvo = function(id, v, sync)
			if v.mode == "sysvo" then
				stopse(id, tm, sync)
				sesys_endclear(id)
			end
		end,
	}

	----------------------------------------
	-- ループして止める
	local s = scr and scr.sesys and scr.sesys.buff
	if s then
		for i, v in pairs(s) do
			local sync = p.loop ~= -1 and p.sync == 1 and not getSkip()
			if sw[md] then sw[md](i, v, sync) end
		end
	end

	----------------------------------------
	-- lip sync stop
	if emote and (md == "voice" or md == "all") then
		emote.lipskip()
	end
end
----------------------------------------
-- 
----------------------------------------
-- panチェック
function sesys_pan(pan)
	local r = pan
	if type(r) == "string" then
		-- pan l c r
		local a = string.lower(r:sub(1, 1))
		if		r == 'c' then r = 0
		elseif	r == 'l' then r = -1000
		elseif	r == 'r' then r = 1000
		elseif	a == 'l' then a = r:sub(2) r = a * -10
		elseif	a == 'r' then a = r:sub(2) r = a *  10
		else	r = r * 10 end
	else
		r = r * 10
	end

	-- 釣果判定
	if r < -1000 then r = -1000 elseif r > 1000 then r = 1000 end
	return r
end
----------------------------------------
-- gain/pan 三桁→四桁変換
function sesys_1000(n, nm)
	local r = tn(n or 0)
	if r == 0 then
	elseif nm == "pan"  and r < -100 then r = -1000
	elseif nm == "gain" and r <    0 then r = 0
	elseif r > 100  then	r = 1000
	else					r = math.ceil(r * 10) end
	return r
end
----------------------------------------
-- タグ実行
----------------------------------------
-- se
function sesys_se(p)
	-- 停止
	if tn(p.stop) == 1 then
		sesys_stop{ mode="se", time=(p.time), id=(p.id), sync=(p.sync) }

	-- 再生
	else
		local id	= p.id or 1
		local file	= p.file
		if csv.se and csv.se[file] then file = csv.se[file] end		-- ファイル名変換

		-- 継続処理
		if p.cont == 1 then
			local v = sesys.getplaystat("se", id)
			if v then
				p.lkid = v.lkid
			else
				message("error", id, "は再生されていないSEです")
				return
			end

		-- 停止しておく
		else
			sesys_stop{ mode="se", time="0", id=(p.id) }
		end
		p.id = id

		-- 再生
		local path = ":se/"..file..game.soundext
		sesys_play("se", path, p)
	end
end
----------------------------------------
-- bgv
function sesys_lvo(p)
	if init.game_enablebgv == "on" then
		local time	= p.time or 0
		local ch	= p.ch
		local hd, v	= sesys.getVoiceName(ch)
		local st	= tn(p.stop) ~= 1
		if v then
			-- 停止
			sesys_stop{ mode="lvo", time=(time), ch=(ch) }

			-- 再生
			if st then
				local path = ":bgv/"..p.file..game.soundext
				if not p.loop then p.loop = 1 end
				sesys_play("lvo", path, p)
			end
		else
			message("エラー", ch, "不明なキャラです")
		end
	end
end
----------------------------------------
-- 音声を積む
function sesys_vostack(p)
	if not scr.vo then scr.vo = {} end
	for i, v in pairs(p) do table.insert(scr.vo, v) end
end
----------------------------------------
-- 積んだ音声を回す
function sesys_voloop()
	if scr.vo then
		-- クリックで音声停止されてなかったら止める
		if conf.voiceskip == 0 or conf.autostop == 0 then
			sesys_stop("voice")
			scr.voice.stack = {}	-- voiceバッファクリア
		end

		for i, v in pairs(scr.vo) do sesys_voplay(v) end
	end
end
----------------------------------------
-- 積んだ音声を再生
function sesys_voplay(p, replay)
	local file	= p.file or p.voice	or p["0"]	-- file

	-- 情報取得
	local head, v = sesys.getVoiceName(p.ch)
	if not v then return end

	-- path
	local path = file
	if replay ~= "conf" then path = v.path..file..game.soundext end

	-- debug
	if debug_flag then
		local g = init.game_voicecheck
		if not isFile(path) then
			if g == "return" then
				message("通知", file, "がありませんでした")
				return
			elseif g == "dialog" then
				tag_dialog({ title="voice error", message=(file.."がありません")})
				return
			end
		end
	end

	-- 再生
	sesys_play("voice", path, p)

	-- リプレイ時は記録しない
	if not replay then

		-- 再生した音声タグをスタック
		table.insert(scr.voice.stack, p)
	end
end
----------------------------------------
-- ボイスリプレイ
function sesys_voreplay(p)
	if p then
		sesys_stop("voice")
		for i, v in pairs(p) do sesys_voplay(v, true) end
	end
end
----------------------------------------
-- ボイス停止
function sesys_vostop(p)
	sesys_stop{ mode="voice", time=(p.time), sync=(p.sync) }
end
----------------------------------------
-- オートモード用ID取得
function sesys_getvoauto()
	local r = nil
	local s = scr.sesys.buff
	for i, v in pairs(s) do
		if v.mode == "voice" then
			if not r then r = i else r = r .. ","..i end
		end
	end
	return r
end
----------------------------------------
-- config slider
function sesys_voslider(nm)
	local cat = init.secat or {}
	local tbl = { voice=2, sysse=1, sysvo=1, se=1, lvo=-1, bgmvo=-1 }
	local s  = scr.sesys.buff
	local c  = tbl[nm]
	for id, v in pairs(s) do
		local md = v.mode
		local ba = v.cat and cat[v.cat] and cat[v.cat].base or "none"

		-- voice
		if md == "voice" then
			-- char voice
			if not c and nm == v.ch then
				local nz = conf["fl_"..nm]
				local vl = nz == 0 and 0 or sesys.getvol("voice", conf[nm], v.vol)
				tag{"sefade", id=(id), gain=(vl), time=(0)}

			-- voice master
			elseif c == 2 then
				local vl = sesys.getvol("voice", conf[v.ch], v.vol)
				tag{"sefade", id=(id), gain=(vl), time=(0)}
			end

		-- volume
		elseif c == 1 and nm == md then
			local vl = sesys.getvol(md, v.vol)
			tag{"sefade", id=(id), gain=(vl), time=(0)}

		-- cat
		elseif ba ~= "none" and nm == v.cat then
			if conf[ba] then
				local vl = 0
				if conf["fl_"..ba] ~= 0 then
					vl = sesys.getvol(nm, conf[ba], v.vol)	-- conf[cat] / conf[base]から音量算出 / 10倍する
				end
				tag{"sefade", id=(id), gain=(vl), time=(0)}
			end
		end
	end
end
----------------------------------------
-- config slider / char
function sesys_vochar(ch)
	local id = sesys_getvoiceid(ch)
	if id then
		local nz = conf["fl_"..ch]
		local vl = nz == 0 and 0 or sesys.getvol("voice", conf[ch])
		tag{"sefade", id=(id), gain=(vl), time=(0)}
	end
end
----------------------------------------
-- chからボイスid取得
function sesys_getvoiceid(ch)
	local r = nil
	local s = scr.sesys.buff
	if ch and s then
		for id, v in pairs(s) do
			local md = v.mode
			if md == "voice" and ch == v.ch then
				r = id
				break
			end
		end
	end
	return r
end
----------------------------------------
-- 音量スライダー
function sesys_volume(mode, id, p)
	local vl = p.vol or s.vol or 100
	local ix = p.id
	local md = p.mode
	local ss = init.sevol or {}				-- conf.seから書き換える
	if ss[ix] then md = ss[ix] end
	local ga = sesys.getvol(md, vl)			-- conf[mode]から音量算出 / 10倍する
	tag{"sefade", id=(id), gain=(ga), time=(0)}
end
----------------------------------------
-- サウンドバッファ
function sesys_getbuffer(p)
	local oz = game.os
	local r  = nil

	-- wasmは強制的に-1
	if oz == "wasm" then
		r = -1

	-- windowsは設定があれば返す
	elseif oz == "windows" then
		local t = type(p)
		if t == "table" then r = p.buffer end
		if not r then
			local md = t == "string" and init.sound_bgmbuffer or init.sound_buffer
			if md ~= "none" then r = md end
		end
	end
	return r
end
----------------------------------------
-- ファイル内関数
----------------------------------------
-- sesys id取得
function sesys.getid()
	local s = scr.sesys
	local m = game.se_track
	local c = s.count or 0
	local r = nil
	for i=1, m do
		local n = c + i
		if n > m then n = n - m end

		-- 空だったらそこを使う
		if not s.buff[n] then
			scr.sesys.count = n
			r = n
			break
		end
	end

	-- エラーチェック
	if debug_flag and not r then
		message("エラー", "■■■ SEチャネルが一杯です ■■■")
	end
	return r
end
----------------------------------------
-- sesys 再生中の情報取得
function sesys.getplaystat(nm, id)
	local s = scr.sesys.buff or {}
	local r = nil
	for i, v in pairs(s) do
		if nm == v.mode and id == v.id then
			v.lkid = i
			r = v
			break
		end
	end
	return r
end
----------------------------------------
-- volume計算
function sesys.getvol(mode, ...)
	local r = conf[mode]		-- ベース音量

	-- mute onの場合は0を返す
	if conf.fl_master == 0 or conf["fl_"..mode] == 0 then
		r = 0
	else
		local t = { ... }
		local m = #t
		for i, v in ipairs(t) do
			local n = t[i]

			-- vol:0 の場合は即時抜ける
			if n == 0 then
				r = 0
				break

			-- vol:100 は結果が変わらないので何もしない
			elseif n < 100 then
				r = r * n / 100
			end
		end

		-- 0 以外は端数を取って10倍
		if r ~= 0 then r = math.ceil(r * 10) end
	end
	return r
end
----------------------------------------
-- ボイスデータ取得
function sesys.getVoiceName(ch)
	local head = -1
	local v = csv.voice[ch]
	if v then
		head = ch
	elseif csv.voice.name[ch] then
		head = csv.voice.name[ch][1]
		v = csv.voice[head]
	end
	return head, v
end
----------------------------------------
-- lvo fadeout / 音声開始時に呼ばれる
function sesys.lvofadeout(p)
	local ch = p.ch
	local s  = scr.sesys.buff
	if init.game_enablebgv == "on" and ch then
		local tm = getSkip() and 0 or init.voice_fadeout
		for i, v in pairs(s) do
			if v.mode == "lvo" and ch == v.ch then
				tag{"sefade", id=(i), time=(time), gain="0"}
				break
			end
		end
	end
end
----------------------------------------
-- lvo fadein / 音声終了時に呼ばれる
function sesys.lvofadein(p)
	local ch = p.ch
	local s  = scr.sesys.buff
	if init.game_enablebgv == "on" and ch then
		local tm = getSkip() and 0 or init.voice_fadein
		for i, v in pairs(s) do
			if v.mode == "lvo" and ch == v.ch then
				tag{"sefade", id=(i), time=(time), gain=(v.nvol)}
				break
			end
		end
	end
end
----------------------------------------
-- 立ち絵位置によるpan制御
function sesys.fgpan(pan, p)
	local f = conf.voicepan or 0
	if f == 0 or flg.ui then return pan end

	local x  = 0
	local r  = pan
	local ch = p.ch
	local z  = csv.voice[ch] or {}
	local nm = z[1] or "none"

	-- 表示済みの立ち絵を見る
	local s  = scr.img.fg or {}
	if s[nm] then x = s[nm].p.x end

	-- 念の為現在のタグを見ておく
	local bl = scr.ip.block
	local z  = ast[bl]
	for i=1, #z do
		if z[i][1] == "fg" and z[i].ch == nm then
			x = z[i].x or x
			break
		end
	end

	-- 計算する
	if x ~= 0 then
		r = percent(x, game.ax) * 10
	end
	return r
end
----------------------------------------
-- 
----------------------------------------
-- 全停止
function allsound_stop(p)
	local time = p and p.time or init.bgm_fade
	local mode = p and p.mode
	bgm_stop{ time=(time) }
	sesys_stop{ mode=(mode), time=(time) }
end
----------------------------------------
