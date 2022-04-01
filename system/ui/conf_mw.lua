----------------------------------------
-- mw config / pico設定
----------------------------------------
-- メニューを開く
function mwconf_init()
	message("通知", "設定画面を開きました")
	se_ok()
	sysvo("config_open")

	flg.ui = {}
	flg.config = { cache=conf.cache }
	local g = gscr.tablet
	if g then
		local a = percent(g.a - 25, 75)
		local z = percent(g.z - 25, 75)
		conf.tab_alpha = a
		conf.tab_zoom  = z
	end
--	set_langnum()		-- 言語を番号に変換

	mwconf_view()
	uiopenanime("mwconf")
end
----------------------------------------
-- ボタン描画
function mwconf_view()
	csvbtn3("conf", "500", lang.ui_conf_mw)
--	set_uihelp("500.z.help", "uihelp")
end
----------------------------------------
function mwconf_reset()
--	del_uihelp()			-- ui help
	delbtn('conf')
	flg.config = nil
	flg.ui = nil
end
----------------------------------------
function mwconf_close()
	ReturnStack()
	se_cancel()
	sysvo("return")

	message("通知", "設定画面を閉じました")

	adv_cls4(true)
	estag("init")
	estag{"uicloseanime", "mwconf"}
	estag{"mwconf_reset"}
	estag{"flip"}
	estag{"conf_reload"}
	estag{"mw_redraw"}
	estag{"reload_ui"}
	estag()
end
----------------------------------------
-- tablet ui制御
----------------------------------------
function mwconf_tablet(e, p)
	local id = getTabletID()
	local g  = gscr.tablet
	if g and id then
		local ga = repercent(conf.tab_alpha, 75) + 25
		local gz = repercent(conf.tab_zoom , 75) + 25
		gscr.tablet.a = ga
		gscr.tablet.z = gz
		mwconf_tabletview()
	end
end
----------------------------------------
-- resetボタン
function mwconf_tabletreset()
	local id = getTabletID()
	if id then
		tab_reset()

		-- conf反映
		local g = gscr.tablet
		conf.tabletui = 1
		conf.tab_alpha = percent(g.a - 25, 75)
		conf.tab_zoom  = percent(g.z - 25, 75)

		mwconf_tabletview()
		mwconf_view()
		flip()
	end
end
----------------------------------------
-- 適用
function mwconf_tabletview()
	local id = getTabletID()
	local g  = gscr.tablet
	if g and id then
		if tabletCheck("ui") then
			local al = repercent(g.a, 255)
			local x  = g.x
			local y  = g.y
			local zm = g.z * 2
			tag{"lyprop", id=(id), left=(x), top=(y), xscale=(zm), yscale=(zm), alpha=(al), visible="1"}
		else
			tag{"lyprop", id=(id), visible="0"}
		end
		flip()
	end
end
----------------------------------------
