----------------------------------------
-- キャッシュ
----------------------------------------
-- キャッシュ設定を取得
function checkCacheSize()
-- large  : 全ファイル
-- middle : 定期的に開放する
-- small  : 最小限
-- none   : キャッシュしない
	local r = conf.cachemode or init.system.autocache	-- cache mode : none/small/middle/large
	if conf.cachemax == 0 then r = nil end				-- max file
	if r == "none" then r = nil end						-- none
	if flg.exskip  then r = nil end						-- debugskip
	if checkWasm() then r = nil end						-- wasmは無効
	return r
end
----------------------------------------
-- キャッシュファイル数をセット
function setCacheMax()
	local r = init.system.cachemax or 500
	local c = conf.cachelevel or 100
	if c <= 0 then r = 0 elseif c < 100 then r = repercent(c, r) end
	conf.cachemax = r
end
----------------------------------------
-- cache stackにセット
function setImageStack(px)
	if checkCacheSize() then
		if not cachebuff then cachebuff = { img={}, cnt={} } end
		if cachebuff.img[px] then return end			-- 既に載ってる

		-- 最大値を超えたら載せない
		local z = true
		local f = flg.cachefiles or 0
		local m = conf.cachemax or init.system.cachemax or 500
		if m <= f then z = nil end

		-- cache
		if z then
--			message("cache", px)
			local c = flg.cachecount or 0
			flg.cachecount = c + 1
			flg.cachefiles = f + 1
			cachebuff.img[px] = true
			table.insert(cachebuff.cnt, px)
			e:bindSurfaceAsync(px)
		elseif debug_flag then
			message("通知", "cacheに乗り切りませんでした", px)
		end
	end
end
----------------------------------------
-- cache stackを削除
function delImageStack(flag)
	local sz = checkCacheSize()
	if sz and (not flag or flag == "all" or sz ~= "large") then
		e:clearSurfaceLoadQueue()		-- 読み込み停止
		local c = cachebuff and cachebuff.cnt or {}
		local m = #c
		if m > 0 then
			-- 逆順で開放
			for i=m, 1, -1 do
--				message("del", i, c[i])
				e:unbindSurface(c[i])
			end
			message("通知", "■■cacheを削除しました■■", m, "files")
		end
		cachebuff = nil
		flg.cachecount = nil
		flg.cachefiles = nil

		-- emote
		if emote then emote.cachereset() end

		-- autocache
		if flag == "all" or flag and sz ~= "large" then
			autocache()
		end
	end
end
----------------------------------------
-- game data cache / キャッシュ待ち
--[[
function waitImageCache()
	local sz = checkCacheSize()
	if sz and sl ~= "large" then
		local c = flg.cachecount or 0
		if c > 0 then
			flg.imageCacheStart = true	-- ローディング待機フラグを立てる
			e:setScriptStatus(4)		-- STOP_NO_INPUTステータスに遷移
		end
	end
	flg.cachecount = nil
end
]]
----------------------------------------
-- game data cache / stack
function stackImageCache(p)
	local sz = checkCacheSize()
	if sz then
		local nm   = p[1]
		local path = p.path
		local file = anyCheck(p)
		if not path or not file then return end

		----------------------------------------
		-- ipt
		local sw = {

		--------------------------------
		-- 2048px分割
		cut = function()
			for i, v in ipairs(ipt) do
				setImageStack(path..v.file)
			end
		end,

		--------------------------------
		-- 差分
		diff = function()
			setImageStack(path..ipt.base[1])
			for i, v in ipairs(ipt) do
				setImageStack(path..v.file)
			end
		end,

		--------------------------------
		-- 全画面アニメーション
		anime_full = function(p)
			for i, v in ipairs(ipt) do
				if v[1] then setImageStack(path..v[1]) end
			end
		end,

		}

		----------------------------------------
		-- read
--		if not cachebuff then cachebuff = {} end
--		local c  = cachebuff
		local px = path..file
		if nm == "bg" then
			if file == "black" then

			elseif e:isFileExists(px..'.ipt') then
				ipt = nil
				e:include(px..'.ipt')
				local md = ipt and ipt.mode
				if md and sw[md] then sw[md](p) end
			else
				setImageStack(px)
			end

		elseif nm == "fg" then
			if emote then emote.fgcache(p) return end
			local tbl = init.fgid
			local ext = game.fgext
			local m = tn(p.mode) or 0

			-- body
			if m >= 2 then
				setImageStack(path..file..ext)

				-- face
				if sz ~= "small" then
					for v, i in pairs(tbl) do
						if v ~= "file" and p[v] then
							setImageStack(path..p[v]..ext)
						end
					end
				end
			end

			-- mw face
			if sz ~= "small" and (m == 1 or m == 3) then
				local px = path:gsub(":fg/", ":fa/"):gsub("/[lsm]/", "/")
				setImageStack(px..file..ext)

				for i, v in ipairs(tbl) do
					if p[v] then
						if v == "face" then	setImageStack(path..p[v]..ext)
						else				setImageStack(px  ..p[v]..ext) end
					end
				end
			end

		elseif nm == "fgf" then
			setImageStack(file)
		else
			dump(p)
		end
	end
end
----------------------------------------
-- 自動キャッシュ
----------------------------------------
function autocache(flag)
	----------------------------------------
	-- cacheと停止の確認
	local breakflag = nil
	local sw = {
		select  = function() breakflag = true end,
		gotitle = function() breakflag = true end,
		excall  = function() breakflag = true end,
		exreturn= function() breakflag = true end,

		cacheclear = function(v)
			local md = v.mode
			if md or sz ~= "large" then breakflag = true end
		end,

		bg = function(v) stackImageCache(v) end,
		fg = function(v) stackImageCache(v) end,
		fgf= function(v)
			local b = v.bg
			if b then
				stackImageCache{"fgf", path="", file=(b)}
			end
		end,
	}

	----------------------------------------
	local sz = checkCacheSize()
	if sz and not flg.exskip and conf.cache > 0 then
		if debug_flag then debugcachetime = e:now() end

		----------------------------------------
		-- キャッシュを空にしておく
		if flag then
			delImageStack()
			if emote then emote.cachereset() end
		end

		----------------------------------------
		-- 現在位置から読み込んでいく
		local bl = scr.ip.block
		local ct = scr.ip.count or 1

		-- labelからの読み込みを一応補正
		if ct > 1 then
			ct = ct + 1
			if not ast[bl][ct] then
				bl = ast[bl].linknext
				ct = 1
			end
		end

		-- loop
		while ast[bl] do
			-- block内を検索
			for k, v in ipairs(ast[bl]) do
				local nm = v[1]
				if ct > 1 and ct > k then

				elseif sw[nm] then
					sw[nm](v)
					if breakflag then break end
				end
			end
			ct = 1

			-- delay
			local d = ast[bl].delay
			if not breakflag and d then
				for k, v in pairs(d) do
					for j, z in ipairs(v) do
						local nm = z[1]
						if sw[nm] then
							sw[nm](z)
							if breakflag then break end
						end
					end
					if breakflag then break end
				end
			end

			-- 次へ
			bl = ast[bl].linknext
		end
	end
end
----------------------------------------
-- 自動キャッシュリフレッシュ
function refresh_autocache(p)
	local md = p.mode

	-- クリアのみ
	if md == "clear" then
		delImageStack()

	-- all
	elseif md == "all" then
		estag("init")
		estag{"delImageStack", "all"}
		estag{"gotoScriptCacheWait"}
		estag()

	-- 再読込
	else
		estag("init")
		estag{"delImageStack", "change"}
		estag{"gotoScriptCacheWait"}
		estag()
	end
end
----------------------------------------
-- vita cache待ち
function gotoScriptCacheWait()
	if game.os == "vita" then
		local time = init.vita_cachewait or 1
		eqtag{"wait", time=(time), input="0"}
	end
end
----------------------------------------
-- UIキャッシュ
----------------------------------------
-- ■ 起動時に１回だけ読み込まれる / ui先読み
function system_cache()
	local c = not checkWasm() and csv.cache and csv.cache.system
	local f = loadingsystemcache
	if c and not f then
		for i, path in ipairs(c) do
			local s = getCachePath(path)
--			message("cache", s)
			e:bindSurfaceAsync(s)
		end
		loadingsystemcache = true
	end
end
----------------------------------------
-- システムキャッシュを削除
function system_cachedelete()
	local c = not checkWasm() and csv.cache and csv.cache.system
	local f = loadingsystemcache
	if c and f then
		e:clearSurfaceLoadQueue()		-- 読み込み停止
		for i, path in ipairs(c) do
			local s = getCachePath(path)
--			message("cache", s)
			e:unbindSurface(s)
		end
		loadingsystemcache = nil
	end
end
----------------------------------------
-- ■ タイトル画面用ui先読み
function title_cache()
	local c = not checkWasm() and csv.cache and csv.cache.title
	if c and not titlecache then
		message("通知", "title ui cache")
		for i, path in ipairs(c) do
			local s = getCachePath(path)
			debmessage("cache", s)
			e:bindSurface(s)
			titlecache = true
		end
	end
end
----------------------------------------
-- title cacheを削除
function title_cachedelete()
	extra_cache()
	local c = not checkWasm() and csv.cache and csv.cache.title
	if c and titlecache then
		message("通知", "title ui cacheを削除しました")
		for i, path in ipairs(c) do
			local s = getCachePath(path)
			debmessage("cache", s)
			e:unbindSurface(s)
		end
		titlecache = nil
	end
end
----------------------------------------
-- title cache完了を待つ
function title_cachewait()
	flg.imageCacheStart = true	-- ローディング待機フラグを立てる
	e:setScriptStatus(4)		-- STOP_NO_INPUTステータスに遷移
end
----------------------------------------
-- パス変換
function getCachePath(path)
	return path:gsub("<ui>", game.path.ui)
end
----------------------------------------
--
----------------------------------------
-- extra cache
function extra_cache(flag)
	local v = not checkWasm() and csv.cache and csv.cache.extra
	if v then
		if flag then
			-- 読み込み
			if not exCacheTable then exCacheTable = {} end
			local p = exCacheTable
			local r = nil
			for i, s in ipairs(v) do
				if not p[s] then
					local px = getCachePath(s)
--					message("cache", s)
					e:bindSurfaceAsync(px)
					exCacheTable[s] = px
					r = true
				end
			end
			if r then message("通知", "extra ui cache") end
		elseif exCacheTable then
			-- 削除
			message("通知", "extra ui cacheを削除しました")
			e:clearSurfaceLoadQueue()		-- 読み込み停止
			local p = exCacheTable
			for i, nm in pairs(p) do
--				message("del", nm)
				e:unbindSurface(nm)
			end
			exCacheTable = nil
		end
	end
end
----------------------------------------
-- font cache
----------------------------------------
function font_cache()
	local path = get_uipath()..(init.fcache_path or "")
	if not fontcacheflag and isFile(path..'index.dat') then
		message("通知", 'フォントをキャッシュします')
		e:restoreFontCache(path)
		fontcacheflag = true
	end

	base_fontcache()
end
----------------------------------------
-- font本体を読み込んでおく
function base_fontcache()
--	message("通知", 'フォント本体をキャッシュします')
	local mx = init.fontmax or 10
	for i=1, mx do
		local name = "font"..string.format("%02d", i)
		if init[name] then
			local id = "basefont."..name
--			message("cache", name, init[name])
			e:tag{"chgmsg", id=(id), layered="1"}
			e:tag{"font", face=(get_fontface(name)), size="12", left="0", top="0", width="400", height="80"}
			e:tag{"print", data="　"}
			e:tag{"/chgmsg"}
			e:tag{"lyprop", id=(id), top="-200"}
		end
	end
end
----------------------------------------
