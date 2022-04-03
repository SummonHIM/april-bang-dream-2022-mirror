----------------------------------------
-- delay制御
----------------------------------------
-- 下準備
function delay_check()
	scr.sli = {}
	local n = scr.ip.block or 1
	local p = ast[n].delay
	if p then

		----------------------------------------
		-- sliを読みに行く
		local s = scr.vo
		if s then
			for i, v in pairs(s) do
				local c = v.ch
				local t = c and csv.voice[v.ch]
				local f = t.path..v.file..'.ogg.sli'
				local r = opensli(t.path..v.file)
				if r then
					scr.sli.time = r
					scr.sli.file = v.file
					scr.sli.id   = sesys_getvoiceid(c)
					break
				end
			end

			-- sliが無ければ適当な数値を代入しておく
			if not scr.sli.time then
				scr.sli.time = {}
				local m = table.maxn(s)
				for i=1, m do scr.sli.time[i] = i * 1000 end
			end

		----------------------------------------
		-- 音声なし
		else
			scr.sli.now  = e:now()
			scr.sli.time = {}
			local i = 1
			for nm, v in pairs(p) do
				if type(nm) == 'string' then
					scr.sli.time[i] = (i-1) * 1000
				else
					scr.sli.time[i] = nm
				end
				i = i + 1
			end
		end

		----------------------------------------
		-- timeでソート
		local r = {}
		local t = scr.sli.time
		for nm, v in pairs(p) do
			if type(nm) == 'string' then
				local n = tn(nm:sub(3))
				if t[n] then
					r[t[n]] = nm
				else
					error_message(nm.."が登録されていませんでした")
				end
			else
				r[nm] = nm
			end
		end
		table.sort(scr.sli.time)
		scr.sli.turn  = r
		scr.sli.count = 1

		flg.delay = true
		delay_wait()
		local label = 'delay'..table.maxn(scr.sli.time)
		e:enqueueTag{"call", file="system/script.asb", label=(label)}
	end
end
----------------------------------------
-- delay wait
function delay_wait()
	local c = scr.sli.count
	local t = scr.sli.time
	local m = table.maxn(t)
	if c <= m and not getSkip() then
		local id = scr.sli.id
		local time = t[c]

		-- オートモード時に音声待機なしの場合はwaitを入れない
		if flg.automode and conf.autostop == 0 then

		-- 音声待機
		elseif id then
			eqwait{ se=(id), time=(time) }

		-- 数値待機
		elseif scr.sli.now then
			local tm = time - (e:now() - scr.sli.now)
			if tm < 0 then tm = 0 end
			eqwait{ time=(tm) }
		end
	end
end
----------------------------------------
-- delay実行
function delay_run(e, p)
	local c    = scr.sli.count
	local ttbl = scr.sli.time[c]
	local name = scr.sli.turn[ttbl]

	local n = scr.ip.block or 1
	local v = ast[n].delay
	local t = v[name]
	if t then
		local getTime = function(p, name) return p.time or init[name] or name end
		local time = nil
		for i, tg in pairs(t) do
			local nm = tg[1]
			local sw = {

			-- bg
			bg = function(p)
				image_view(p, true)
				time = getTime(p, 'bg_fade')
			end,

			-- cgdel
			cgdel = function(p)
				cgdel_main(p, true)
				time = getTime(p, 'bg_fade')
			end,

			-- fg
			fg = function(p)
				-- face
				local fa = scr.mwface
				if fa then
					local c = p.ch
					local z = csv.voice[fa]			-- 喋ってるキャラstrから情報を取得
					local d = csv.voice.name[c]		-- mobキャラdelay変換(csv)確認
					local c = d.exch or c			-- mobキャラdelay変換(csv)があれば優先、無ければスクリプトのキャラ名を使う
					if z[1] == c then mw_face(p) flip() end
				end
				delay_fg(p)
				time = getTime(p, 'fg_fade')
			end,
			fgf = function(p)	delay_fgf(p)	time = getTime(p, 'fg_fade') end,	-- fgf
			fgact = function(p)	fgact(p) end,										-- fg act

			quake = function(p)	quake(p) end,										-- quake

			se = function(p)	sesys_se(p) end,									-- se
			bgm = function(p)	bgm(p) end,											-- bgm

			}
			if sw[nm] then
				sw[nm](tg)
				storeQJumpStack(nm, tg, name)
			else error_message(nm..'はdelayで実行できません') end
		end
		if time and flg.delay ~= 'skip' then trans{ fade=(time) } end
	end

	-- 次へ
	scr.sli.count = c + 1
end
----------------------------------------
-- delay終了
function delay_end()
	scr.sli = nil
	if flg.delay ~= 'skip' then flg.delay = nil end
end
----------------------------------------
-- delayをクリックで飛ばしたときの停止処理
function delay_skipstop()
	if flg.delay == 'skip' then
		e:tag{"exec", command="skip", mode="0"}

		-- lip sync
		if emote then emote.lipskip() end
	end
	flg.delay = nil
end
----------------------------------------
