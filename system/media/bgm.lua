----------------------------------------
-- BGM
----------------------------------------
local bgmsys = {}
----------------------------------------
-- bgm filename
function getplaybgmfile(name)
	local s = scr.bgm
	local r = nil
	if name or s and s.file then
		-- タグ名から判定
		local n = name or s.name
		local v = csv.extra_bgm[n]
		if v then
--			if v[1] ~= -1 then r = v[2] end
			r = n

		-- ファイル名から判定
		elseif s.file then
			r = s.file
			if r:sub(-2) == "_a" then r = r:sub(1, -3) end
		end
	end
	return r
end
----------------------------------------
-- bgm
function bgm(p)
	-- 登録のみ
	if p.unlock == 1 then
		bgm_unlock(p)

	-- 停止
	elseif tn(p.stop) == 1 then
		bgm_stop(p)

	-- 再生
	else
		bgm_play(p)
	end
end
----------------------------------------
-- BGM再生
function bgm_play(p)
	local s     = scr.bgm
	local name	= p.file or p["0"]					-- name
	local file	= name								-- file
	local time	= p.time or 0						-- time
	local loop	= p.loop or 1						-- loop
	local ptime	= p.ptime or 0						-- pan time
--	local pan	= sesys_pan(p.pan or 0)				-- pan	三桁 / 左-100 中0 右100
	local pan	= p.pan or s.pan or 0
	local panz	= sesys_pan(pan)					-- pan 左-1000 中0 右1000
	local vol	= p.vol or 100						-- vol 三桁

	-- time変換
	if getSkip() then
		time  = 0
		ptime = 0
	end

	-- gain変換
	local gain = bgmsys.getvolume(vol)				-- gain 四桁

	----------------------------------------
	-- volume変更
	local evol = function()
		if s.vol ~= vol then
			tag{"sfade", gain=(gain), time=(time)}
			scr.bgm.vol = vol
		end
	end

	-- pan変更
	local epan = function()
		if s.pan ~= pan then
			local px = sesys_1000(panz, "pan")
			tag{"span", pan=(px), time=(ptime)}
			scr.bgm.pan = pan
		end
	end

	----------------------------------------
	-- ファイル名変換
	if not csv.extra_bgm[name] then
		message(name, "は登録されていないファイルです")
		return
	else
		file = csv.extra_bgm[name][2]
	end

	-- 再生中
	if file == s.file then
--		message("BGM再生", name, "は既に再生されています")
		evol()
		epan()
		return
	end

	----------------------------------------
	-- 再生
	message("BGM再生", name)

	local cf = s.file
	if cf then	e:tag{"sxfade", file=(':bgm/'..file..game.soundext), time=(time), loop=(loop), gain=(gain), buffer=(sesys_getbuffer("bgm"))}
	else		e:tag{"splay",  file=(':bgm/'..file..game.soundext), time=(time), loop=(loop), gain=(gain), buffer=(sesys_getbuffer("bgm"))} end
	epan()

	-- 保存
	local vf = s.vofade		-- ボイス再生フラグは継続しておく
	scr.bgm = { name=(name), file=(file), vol=(vol), pan=(pan), loop=(loop), now=(e:now()), vofade=(vf) }

	-- 再生したBGMをunlock
	bgm_unlock(p)

	-- 曲名
	if not p.sys then set_notification("bgm", p.file) end
end
----------------------------------------
-- BGM開放
function bgm_unlock(p)
	local nm = p.file or p["0"]
	local no = init.game_bgmsetcut
	if no and nm:sub(1, 3) == "bgm" then nm = nm:sub(1, no) end		-- アレンジ版登録
	if not gscr.bgm[nm] and p.lock ~= 1 then
		message("通知", nm, "を登録しました")
		gscr.bgm[nm] = true
	end
end
----------------------------------------
-- BGM停止
function bgm_stop(p, flag)
	local time	= p.time or init.bgm_fade	-- time
	local wait	= p.wait or 0				-- wait
	if getSkip() then time = 0 end

	message("BGM停止", "time:", time)
	e:tag{"sstop", time=(time)}

	if not flag then
		-- waitがあったら指定時間待つ
		if wait > 0 then
			eqwait(time)
			eqtag{"sstop", time="0"}
		end

		-- 保存データの削除
		scr.bgm = {}
	end
end
----------------------------------------
-- old
----------------------------------------
-- BGM fade
function bgm_fade(param)
	local time	= param.time or init.bgm_fade			-- time
	local gain	= bgmsys.getvolume(param.vol or 100)	-- gain
	if getSkip() then time = 0 end

	message("通知", "BGMの音量を", gain, "に変更します")
	e:tag{"sfade", time=(time), gain=(gain)}

	-- 保存
	scr.bgm.vol = gain
end
----------------------------------------
-- BGM pan
--[[
function bgm_pan(param)
	local time	= param.time or init.bgm_fade	-- time
	local pan	= sound_pan( param.pan or 0  )	-- pan	左-1000 中0 右1000
	if getSkip() then time = 0 end

	message("通知", "BGMのpanを", pan, "に変更します")
	e:tag{"span", time=(time), pan=(pan)}

	-- 保存
	scr.bgm.pan = pan
end
]]
----------------------------------------
-- 
----------------------------------------
-- BGM / ボイス再生中に音量を下げる
function bgmVoiceFadeIn()
	local f = conf.fl_bgmvo
	local v = f == 0 and 0 or conf.bgmvoice
	if v and conf.fl_bgmvo == 1 and v < 100 and not getSkip() then
		local c = 1	-- (scr.bgmfade or 0) + 1
		scr.bgmfade = c
		if c == 1 then
			local time = init.bgm_voicein
			e:tag{"sfade", time=(time), gain=(v.."0")}
		end
	end
end
----------------------------------------
-- BGM / ボイス再生終了で音量を戻す
function bgmVoiceFadeOut()
	local c = scr.bgmfade
	if c then
		c = 0	--c - 1
		scr.bgmfade = c
		if c == 0 then
			local time = getSkip() and 0 or init.bgm_voiceout
			e:tag{"sfade", time=(time), gain="1000"}
			scr.bgmfade = nil
		end
	end
end
----------------------------------------
--
----------------------------------------
-- 音声再生時に呼ばれる
function bgm_vofadeout()
	local s  = scr.bgm
	local fl = s.vofade
	local ct = bgmsys.getvofade()		-- fade処理を行う
	if not fl and ct then
		scr.bgm.vofade = true
		local time = getSkip() and 0 or init.bgm_voicein
		local fade = bgmsys.getvolume()
		tag{"sfade", time=(time), gain=(fade)}
	end
end
----------------------------------------
-- 音声終了時に呼ばれる
function bgm_vofadein()
	local s  = scr.bgm
	local fl = s.vofade
	if fl then
		scr.bgm.vofade = nil
		local time = getSkip() and 0 or init.bgm_voiceout
		local fade = bgmsys.getvolume()
		tag{"sfade", time=(time), gain=(fade)}
	end
end
----------------------------------------
-- ファイル内関数
----------------------------------------
-- 音声再生時にフェード処理を行うかどうか
function bgmsys.getvofade()
	local r  = nil
	local ct = conf.fl_bgmvo			-- 1:音声再生時に音量を下げる
	if ct == 1 then
		local c1 = conf.fl_bgmvo		-- 音量を下げる / checkbox
		local c2 = conf.bgmvo			-- 音量を下げる / 減少率

		-- mute
		if c1 == 0 or c2 == 0 then
			 r = 0

		-- 100は何もしない
		elseif c2 < 100 then r = c2 end
	end
	return r
end
----------------------------------------
-- bgmsys volume
function bgmsys.getvolume(vol)
	local s = scr.bgm
	local r = vol or s.vol or 100

	-- ボイス再生中
	if s.vofade then
		local fo = bgmsys.getvofade()
		if fo == 100 then	
		elseif fo == 0 then	r = 0
		elseif fo then		r = r * fo / 100 end
	end
	return sesys_1000(r, "gain")	-- 三桁→四桁
end
----------------------------------------
