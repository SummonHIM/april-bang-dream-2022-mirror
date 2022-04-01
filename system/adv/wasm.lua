----------------------------------------
-- wasm
----------------------------------------
wasm = {}
----------------------------------------
-- wasmチェック
function wasm.checkTrue() return game.trueos == "wasm" end
function wasm.check()	  return game.os     == "wasm" end
function wasm.checkSync() return game.os     == "wasm" and init.game_wasmsync end
----------------------------------------
-- コマンド発行
function wasm.command(p)
	local r = nil
	if wasm.checkTrue() then
		local s = p:gsub("[\t\r\n ]", "")
		tag{"callnative", method=(s), result="t.wasmtemp"}
		r = e:var("t.wasmtemp")
	end
	return r
end
----------------------------------------
-- 初期化
function wasm.init()
	if wasm.checkTrue() then
		local pf = string.lower(wasm.command("navigator.platform;"))		-- OS名
		local ua = string.lower(wasm.command("navigator.userAgent;"))		-- UA
		local s2 = pf:sub(1, 2)
			if s2 == 'ma' then pf = 'mac'				-- Macintel / Mac
		elseif s2 == 'ip' then pf = 'ios'				-- iPhone / iPad / iPod touch一括判定
		elseif s2 == 'li' then pf = 'android' end		-- androidはLinux armになる
			if ua:find(' edg/')	  then ua = 'edge'		-- Edge  はSafariとChromeを含む(Chromium版)
		elseif ua:find('edge')	  then ua = 'edge'		-- Edge  はSafariとChromeを含む(旧)
		elseif ua:find('opera')	  then ua = 'opera'		-- Opera はSafariとChromeを含む(旧)
		elseif ua:find('opr')	  then ua = 'opera'		-- Opera はSafariとChromeを含む(新)
		elseif ua:find('chrome')  then ua = 'chrome'	-- ChromeはSafariを含む
		elseif ua:find('firefox') then ua = 'firefox'	-- firefoxは単独
		elseif ua:find('safari')  then ua = 'safari'	-- その他Safari
		elseif ua:find('webkit')  then ua = 'etc'		-- Safariが含まれないWebKit(多分動かない)
		else   ua = "etc" end
		game.wasm_os = pf
		game.wasm_ua = ua

		-- 動画制御用にapple判定フラグを付ける
		if pf == "ios" or pf == "mac" and ua == "safari" then
			game.apple = true
		end
	end
end
----------------------------------------
-- movie再生
----------------------------------------
-- wasm / movie音量
function wasm.movievol()
	if wasm.checkTrue() then
		local p = [[
			if (artemis_fullscreen_video !== null) {
				artemis_fullscreen_video.volume = #vol#;
				artemis_fullscreen_video.muted = false;
			}
		]]
		local v = e:var("s.videovol") / 1000
		local s = p:gsub("#vol#", v)
		wasm.command(s)
	end
end
----------------------------------------
-- wasm用処理 / apple
function wasm.movie_apple()
	if wasm.checkTrue() then
		-- 待機画像を表示してタップ待ち
		local px = get_uipath().."apple"
		lyc2{ id="wasm", file=(px)}
		flip()
		e:setEventHandler{ onInputEvent="wasm.movieevent" }
		e:setScriptStatus(4)	-- SYSTEM STOP
	end
end
----------------------------------------
-- 再生してイベント解除
function wasm.movieevent(e, p)
	local no = tn(p.type)
	local px = flg.movie_wasmpath
	if px and (no == 1 or no == 3) then
		e:setScriptStatus(0)	-- SYSTEM RUN
		e:setEventHandler{ onInputEvent="" }
		lydel2("wasm")
		flip()
		tag{"video", file=(px), skip="2"}	-- 再生
--		wasm.movievol()						-- 音量コントロール / iOSでは動作不定
		flg.movie_wasmpath = nil
	end
end
----------------------------------------
-- 停止
function wasm.movieend()
	if wasm.checkTrue() then
		local p = [[
			if (artemis_fullscreen_video !== null) {
				artemis_fullscreen_video.pause();
				artemis_fullscreen_video.src = '';
				artemis_fullscreen_video = null;
			}
		]]
		wasm.command(p)
	end
	flg.movie_wasmpath = nil	-- 念の為消しておく
end
----------------------------------------
-- 
----------------------------------------
-- jsを実行する
function wasm.exec(name)
	local z = csv.wasmjs or {}
	if z[name] then
		wasm.command(z[name])
	else
		message("注意", name, "は不明なJavaScriptです")
	end
end
----------------------------------------
-- ボタンを押したら実行
function wasm_button(e, p)
	local bt = p.btn
	local v  = getBtnInfo(bt)
	if v.p1 then wasm.exec(v.p1) end
end
----------------------------------------
-- wasm cache
----------------------------------------
-- cache準備
function cache_wasmloading()
	local fl = scr.ip.file
	local ws = checkWasmsync()		-- wasmsync
	if fl and ws then
		message("通知", fl, "loading...")

		local px = ws..fl..".txt"
		tag{"file", command="wasm_sync", url=(px)}
		cache_wasmloadinggauge()
--		game_stop()
	end
end
----------------------------------------
-- お気に入りボイス
function cache_wasmfavo()
	local s  = gscr.wasmfave
	local ws = checkWasmsync()		-- wasmsync
	if ws and s and s ~= "" and s ~= "," then
		tag{"file", command="wasm_sync", baseurl=(ws), list=(s)}
		cache_wasmloadinggauge()
	end
end
----------------------------------------
-- cache gauge
function cache_wasmloadinggauge()
	local t = init.game_wasmbar or {}
	local w = t[1] or 400
	local h = t[2] or 20
	local c = t[3] or "xffffff"
	local x = math.floor((game.width  - w) / 2)
	local y = math.floor((game.height - h) / 2)
	local f = flg.wasmcache and 1 or 0
	lyc2{ id="wasm.0", file=(init.black), alpha="128", visible=(f)}
	lyc2{ id="wasm.1", width=(w), height=(h), color=("0"..c), clip=("0,0,1,"..h), x=(x), y=(y), visible="0"}
	ui_message("wasm.2", { 'wasm', text="Checking..." })
	flip()

	flg.wasmsync = { w=(w), h=(h) }
end
----------------------------------------
-- cache vsync
function cache_wasmvsync()
--	s.wasm_sync_status
--		0 実行完了
--		1 内部で使用
--		2 内部で使用
--		3 リストのダウンロード中
--		4 リストのダウンロードに失敗
--		5 ファイル群のダウンロード中
--		6 ファイル群のダウンロードに失敗
	local v  = flg.wasmsync
	local st = tn(e:var("s.wasm_sync_status"))
	local no = tn(e:var("s.wasm_sync_current"))
	local mx = tn(e:var("s.wasm_sync_total"))
--	ui_message("z", { 'notify', text=(" Loading... "..st.." "..no.."/"..mx) })

	-- 実行完了
	if st == 0 then
		ui_message("wasm.2")
		lydel2("wasm")
		flip()
		flg.wasmsync = nil
		flg.wasmcache = nil
--		game_run()

	-- 5 ファイル群のダウンロード中
	elseif st == 5 then
		if no ~= v.z then
			local w  = v.w
			local h  = v.h
			local n  = math.ceil(no / mx * w)
			tag{"lyprop", id="wasm.1", clip=("0,0,"..n..","..h), visible="1"}

--			local s = no.." / "..mx							-- ファイル数表示
			local s = math.ceil(no / mx * 100).." / 100"	-- パーセント表示
			ui_message("wasm.2", { 'wasm', text=(s) })
			flip()
			flg.wasmsync.z = no
		end

	-- 4 リストのダウンロードに失敗
	-- 6 ファイル群のダウンロードに失敗
	elseif st == 4 or st == 6 then
		flg.wasmsync = nil
		eqtag{"calllua", ["function"]="cache_wasmsyncerror"}
	end
end
----------------------------------------
function cache_wasmsyncerror()
	tag_dialog({ title="エラー", message="読み込み失敗\nリロードしますか？", varname="t.yn" }, "cache_wasmsyncerror2")
end
----------------------------------------
function cache_wasmsyncerror2()
	local yn = e:var("t.yn")
	if yn == "1" then
		cache_wasmloading()
	else
		tag{"lyprop", id="wasm.1", visible="0"}
		ui_message("wasm.2", { 'wasm', text="ブラウザを終了してください" })
		flip()
	end
end
----------------------------------------
