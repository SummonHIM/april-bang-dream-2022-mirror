----------------------------------------
-- 動画再生
----------------------------------------
-- 初期化
function movie_init(p)
	scr.movie = p
	exskip_stop()			-- debugskip停止

	-- androidの場合はセーブする
	if game.trueos == "android" then
		e:tag{"var", name="save.systemtable", data=(pluto.persist({}, scr))}
	end

	-- 一旦asbを経由しておく
	e:tag{"call", file="system/script.asb", label="movie_play"}
end
----------------------------------------
-- auto/skip保存して停止
function movie_autoskip()
	if not getTitle() then
		autoskip_stop(true)
		autoskip_disable()
	end
end
----------------------------------------
-- ファイル名読み替え
function movie_getfilename(file)
	local v  = init.movie[file] or {}		-- movie設定
	local fx = v.file or file				-- 仮想ファイル
	if v.lang then
		local ln = get_language(true)		-- 多言語
		local s  = init.langadd[ln]
		if s then fx = fx..s end
	end
	return fx
end
----------------------------------------
-- 再生本体
function movie_play()
	local p    = scr.movie
	local file = p.file
	local v    = init.movie[file] or {}		-- movie設定
	local fx   = movie_getfilename(file)	-- ファイル名読み替え

	----------------------------------------
	-- 停止キー / 0:常に飛ばせない 1:常に飛ばせる 2:初回は飛ばせない
	local ct = p.cancel or v.skip or 2
	local sk = 0
	if ct == 2 and gscr.movie[file] then ct = 1 end
	if ct == 1 then
		local ky = getKeyString("CANCEL")
		if game.sp and init.game_mobilemovie == "on" then ky = "1,"..ky end
		tag{"keyconfig", role="1", keys=(ky)}
		sk = 2
	else
		tag{"keyconfig", role="1", keys=""}
	end

	message("通知", file, "を再生します", fx, ct)

	----------------------------------------
	-- movie登録
	if not gscr.movie[file] then gscr.movie[file] = true end

	-- bgm登録
	local s = v.bgm
	if s then
		for i, v in ipairs(s) do
			bgm_unlock{ file=(v) }
		end
	end

	-- ev登録
	local sc = csv.cgscroll or {}		-- mode設定
	local t  = sc[file] or {}
	if t[2] then evset{ file=(file), set=(t[2]) } end

	----------------------------------------
	-- 背景
	local b = p.bg
	if b then
		image_view({ path=":bg/", file=(b) }, true)
		flip()
	end

	----------------------------------------
	-- volume
	local ans = volume_count("movie", conf.master, (conf.movie or conf.bgm), (v.vol or init.config_moviemax or init.config_bgmmax))
	tag{"var", name="s.videovol", data=(ans)}

	----------------------------------------
	-- 再生
	local path = game.path.movie..fx..game.movieext

	----------------------------------------
	-- wasm
	if wasm and game.trueos == "wasm" then
		-- wasm再生 / apple
		if game.apple then
			flg.movie_wasmpath = path				-- urlで開く(相対パス)
			wasm.movie_apple()						-- iOSはeventで再生する
		else
			tag{"video", file=(path), skip="2"}		-- urlで開く(相対パス)
			wasm.movievol()							-- 音量コントロールを試みる
		end

	----------------------------------------
	-- 通常再生
	else
		movie_playfile{ file=(path), skip=(sk) }	-- 再生
	end
end
----------------------------------------
-- 再生
function movie_playfile(p)
	local t = nil
	if type(p) == "string" then t = {"video", file=(p), skip="2" } else t = tcopy(p) end
	if not t[1] then t[1] = "video" end

	-- windows / VMR再生モード
	if game.trueos == "windows" then t.mode = conf.winvmr end

	-- 再生
	tag(t)
end
----------------------------------------
-- 終了処理
function movie_play_exit()
	e:tag{"var", name="save.systemtable", system="delete"}	-- android用
	e:tag{"keyconfig", role="1", keys=""}
	e:tag{"lydel", id="2"}
	scr.movie = nil

	-- wasm終了処理
	if wasm then wasm.movieend() end

	if not getTitle() then
		autoskip_init()
		restart_autoskip()
	end
end
----------------------------------------
-- 
----------------------------------------
-- ogv
function ogv_play(id, p)
	local file = p.file
	local path = game.path.movie..file
	local loop = p.loop

	-- se
	local sefl = ":se/"..file..game.soundext
	if isFile(sefl) then
		
	end

	-- movie
	tag{"video", id=(id), file=(path..".ogv"), loop=(loop), eq=1}
end
----------------------------------------
