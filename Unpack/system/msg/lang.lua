----------------------------------------
-- 多言語
----------------------------------------
-- lang初期化
function lang_confreset(def)
	set_language("main", def or get_language())
	set_language("sub" , init.game_sublang)
	set_language("ui"  , init.game_uilang)
end
----------------------------------------
-- 多言語書き込み
function set_language(nm, ln)
	local sw = {

	-- 主言語
	main = function()
		conf.language = ln

		-- ui言語を主言語と同期する
		if init.game_uilangsync == "on" then conf.ui_lang = ln end
	end,

	-- 副言語
	sub = function()
		if ln == "none" then ln = nil end
		conf.sub_lang = ln
	end,

	-- ui言語
	ui = function()
		if init.game_uilangsync ~= "on" then conf.ui_lang = ln end
	end,
	}
	if sw[nm] then sw[nm](ln) end

	-- uipath書き換え
	set_uipath()
end
----------------------------------------
-- 主言語取得
function get_language(flag)
	local r = flag and conf and conf.language or (init.steam == "on" and init.steam_language or init.game_language) or "ja"
	if debug_flag and deb.lang then r = deb.lang end	-- debug / 言語切替
	return r
end
----------------------------------------
function get_sub_lang()	return conf.sub_lang end
function get_ui_lang()	return conf.ui_lang or "ja" end
----------------------------------------
-- 
----------------------------------------
function lang_ja() adv_putlang("ja") end	-- 日本語
function lang_en() adv_putlang("en") end	-- 英語
function lang_cn() adv_putlang("cn") end	-- 簡体字
function lang_tw() adv_putlang("tw") end	-- 繁体字
----------------------------------------
-- 言語変更 / キー選択
function adv_putlang(nm)
	local flag = init.game_sublangview == "on" and flg.alt
	adv_setlang(nm, flag)
end
----------------------------------------
-- 言語変更 / 書き換え
function adv_setlang(nm, flag)
	local ln = get_language(true)	-- 主言語
	local sb = get_sub_lang()		-- 副言語
	local r  = flag and sb or ln	-- flagが立っていたら副言語書き換え
	local v  = init.lang

	-- 入れ替え
	if nm ~= r and v[nm] then
		se_ok()

		-- 主言語
		if not flag then
			message("通知", "主言語", r, "→", nm)
			set_language("main", nm)
			if nm == sb then set_language("sub", r) end

		-- 副言語
		else
			message("通知", "副言語", r, "→", nm)
			set_language("sub" , nm)
			if nm == ln then set_language("main", r) end
		end
		lang_redraw()				-- 再描画
		asyssave()

	-- 副言語非表示
	elseif flag and nm == sb then
		message("通知", "副言語非表示")
		set_language("sub" , nil)
		lang_redraw()				-- 再描画
		asyssave()
	end
end
----------------------------------------
-- 言語入れ替え
function lang_change()
	local ln = get_language(true)	-- 主言語
	local sb = get_sub_lang()		-- 副言語
	local fl = init.game_sublangview == "on"
	if fl and sb and ln~= sb then
		se_ok()
		set_language("main", sb)
		set_language("sub" , ln)
		lang_redraw()				-- 再描画
	end
end
----------------------------------------
-- 再描画
function lang_redraw()
	-- font読み直し
	font_init()

	-- ボタン設置
	if init.game_uilangsync == "on" then
		init_advmw(true)
	end

	----------------------------------------
	local fl = true

	-- 選択肢
	if scr.select then
		estag("init")
		estag{"select_resetimage"}		-- 一旦消す
		estag{"select_view"}			-- 再描画
		estag{"select_event", true}		-- lyevent割り当て
		estag()
		fl = nil

	-- line
	elseif scr.line then
		local bl = scr.ip.block
		local v  = ast[bl].text
		if v.linemode then
			msgcheck("sys")			-- msg sys
			fl = nil
		end
		mwline_textredraw()			-- 再描画
	end

	-- 本編
	if fl then
		adv_cls4(true)
		mw_redraw(true)
		flip()
	end
end
----------------------------------------
