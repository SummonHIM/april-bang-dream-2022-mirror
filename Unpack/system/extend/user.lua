----------------------------------------
-- 拡張管理
----------------------------------------
usr = {}
----------------------------------------
--	e:include('system/extend/user/macro.lua')	-- マクロ再現用
--	e:include('system/extend/user/sm.lua')		-- sm / float
--	e:include('system/extend/staff/staff.lua')	-- staffroll
----------------------------------------
-- UIアニメーション
----------------------------------------
function uiopenanime(name)
	local tm = init.ui_fade
	local sw = {

	----------------------------------------
	-- dialog
	dialog = function()
		local tm = init.dlg_fade or init.ui_fade
		local y  = mulpos(-50)
		systween2{ id="600.1", y=(y..",0"), time=(tm)}
		systween2{ id="600", alpha="0,255", time=(tm)}
		flip()
	end,

	----------------------------------------
	-- pico設定
	mwconf = function()
		local v  = getBtnInfo("bg")
		local x  = -v.w
		systween2{ id="500.mn", x=(x..",0"), time=(tm)}
		estag("init")
		estag{"uitrans", tm}
		estag()
	end,
--[[
	----------------------------------------
	-- backlog
	blog = function()
		tag{"lyprop", id="500.z", visible="0"}
		estag("init")
		estag{"uitrans", { rule="rule_backlogon", fade="250" } }
		estag{"lyprop", id="500.z", visible="1"}
		estag{"uitrans"}
		estag()
	end,

	----------------------------------------
	-- save / load
	save = function()
		local s = flg.saveanime
		if not s then
			flg.saveanime = true
			local t1 = 150
			local t2 = 150
			local v  = getBtnInfo('logo')
			local y  = (-v.h)..","..(v.y)
			tag{"lyprop", id=(v.idx), visible="0"}
			tag{"lyprop", id="500.z", visible="0"}
			estag("init")
			estag{"systween", { id="500.2", time=(t2 + tm), delay=(t1), alpha="0,255"}}
			estag{"uitrans", { rule="rule_saveon", fade=(t1 + t2) }}
			estag{"systween", { id=(v.idx), y=(y), time=(tm)}}
			estag{"lyprop", id="500.z", visible="1"}
			estag{"lyprop", id=(v.idx), visible="1"}
			estag{"uitrans", tm}
			estag()
		else
			uitrans()
		end
	end,

	----------------------------------------
	-- favo
	favo = function()
		local t1 = 150
		local t2 = 150
		local v  = getBtnInfo('logo')
		local y  = (-v.h)..","..(v.y)
		tag{"lyprop", id=(v.idx), visible="0"}
		tag{"lyprop", id="500.z", visible="0"}
		estag("init")
		estag{"systween", { id="500.2", time=(t2 + tm), delay=(t1), alpha="0,255"}}
		estag{"uitrans", { rule="rule_favoon", fade=(t1 + t2) }}
		estag{"systween", { id=(v.idx), y=(y), time=(tm)}}
		estag{"lyprop", id="500.z", visible="1"}
		estag{"lyprop", id=(v.idx), visible="1"}
		estag{"uitrans", tm}
		estag()
	end,

	----------------------------------------
	-- config
	conf = function()
		tag{"lyprop", id="500.z", visible="0"}
		estag("init")
		estag{"uitrans", { rule="rule_confon", fade=(tm) }}
		estag{"lyprop", id="500.z", visible="1"}
		estag{"uitrans", tm}
		estag()
	end,

	----------------------------------------
	-- extra
	extra = function()
		local t2 = tm * 2
		local i1 = "500.z"				-- body
		local i2 = getBtnID("bg02")		-- black
		local i3 = "500.sy.1"			-- up
		local i4 = "500.sy.2"			-- dw
		local v1 = getBtnInfo("bg03")	-- up info
		local v2 = getBtnInfo("bg04")	-- dw info
		tag{"lyprop", id=(i1), visible="0"}
		tag{"lyprop", id=(i2), visible="0"}
		tag{"lyprop", id=(i3), top=(-v1.h)}
		tag{"lyprop", id=(i4), top=( v2.h)}
		estag("init")
		estag{"uitrans", { rule="rule_extraon", fade=(t2) }}
		estag{"lyprop", id=(i2), visible="1"}
		estag{"systween", { id=(i3), y=(-v1.h..",0"), time=(t2)}}
		estag{"systween", { id=(i4), y=( v1.h..",0"), time=(t2)}}
		estag{"uitrans", t2}
		estag{"lyprop", id=(i1), visible="1"}
		estag{"uitrans", tm}
		estag()
	end,
]]
	}
	if sw[name] then sw[name]()
	else uitrans() end
end
----------------------------------------
function uicloseanime(name)
	local tm = init.ui_fade
	local sw = {

	----------------------------------------
	-- dialog
	dialog = function()
		local tm = init.dlg_fade or init.ui_fade
		local y  = mulpos(50)
		systween2{ id="600.1", y=("0,"..y), time=(tm)}
		tag{"lyprop", id="600", visible="0"}
		estag("init")
		estag{"uitrans", tm}
		estag{"dialog_return"}
		estag()
	end,

	----------------------------------------
	-- backlog
	blog = function()
		estag("init")
		estag{"blog_reset"}
		estag{"uitrans"}
		estag()
	end,

	----------------------------------------
	-- save / load
	save = function()
		estag("init")
		estag{"save_reset"}
		if not getTitle() then estag{"uitrans"} end
		estag()
	end,

	----------------------------------------
	-- config
	conf = function()
		estag("init")
		estag{"conf_savecheck"}		-- セーブ確認
		estag{"conf_reset"}			-- 消去
		if not getTitle() then estag{"uitrans"} end
		estag()
	end,

	----------------------------------------
	-- pico設定
	mwconf = function()
		local v  = getBtnInfo("bg")
		local x  = -v.w
		tag{"lyprop", id="500", visible="0"}
		systween2{ id="500.mn", x=("0,"..x), time=(tm)}
		uitrans(tm)
	end,
	}
	if sw[name] then sw[name]()
	else uitrans() end
end
----------------------------------------
-- 時限選択肢拡張
----------------------------------------
--[[
function user_selecttimed_open(time, wait)
	local id = select_timed_getid()
	local a  = scr.select.anime
	local y  = a.y or 0
	systween{ id=(id), alpha="0,255", time=(time), ease="none"}
	systween{ id=(id), y=((y-80)..","..y), time=(time)}
end
----------------------------------------
function user_selecttimed_close(time, wait)
	local id = select_timed_getid()
	local a  = scr.select.anime
	local y  = a.y or 0
	systween{ id=(id), alpha="255,0", time=(time), ease="none"}
	systween{ id=(id), y=(y..","..(y+80)), time=(time)}
end
]]
----------------------------------------
--
----------------------------------------
-- 作品別初期化ルーチン / 起動時及びconfig reset時に呼ばれる
--[[
function user_conf()

end
]]
----------------------------------------
--
----------------------------------------
--[[
-- extra cg / 強制開放
function extra_cgopen()
	local set_table = {
		ev_gue_01 = true,
	}
	local ev_table = {
		ev_gue_01a = true,
	}

	-- set登録
	for set, v in pairs(set_table) do
		if not gscr.evset[set] then
			gscr.evset[set] = true
		end
	end

	-- ev登録
	for k, v in pairs(ev_table) do
		if not gscr.ev[k] then
			gscr.ev[k] = true
		end
	end
end
]]
----------------------------------------
-- user tag
----------------------------------------
tags.user = function(e, p)
	local md = p.mode
	local sw = {
		-- start時のmanual
		start = function()
		 	user_gamestart()
		end,

		--exskip強制停止
		exskipstop = function()
			if flg.exskip then
				flg.exskipstop = true
				exskip_stop()
			end
		end,
	}
	if sw[md] then sw[md]() end
	return 1
end
----------------------------------------
function user_gamestart()
	flg.ui = {}
	csvbtn3("user", "500", lang.ui_start)
	estag("init")
	estag{"uitrans", 1000}
	estag{"eqwait"}
	estag("stop")
end
----------------------------------------
function user_gameclick()
	ResetStack()
	se_ok()
	delbtn("user")		-- 削除
	uitrans(1000)
	flg.ui = nil
	init_adv_btn()		-- adv btn
	autoskip_init()		-- autoskip
end
----------------------------------------
--
----------------------------------------
tags["demo"] = function(e, p)
	local cf = p.auto or 1
	conf.mspeed = p.mspeed or conf.mspeed
	conf.aspeed = p.aspeed or conf.aspeed
	conf.auto   = p.auto or 1
	conf.tabletui = p.tablet or 0
	conf.mw_aread = p.aread  or 0
	adv_auto()
	return 1
end
----------------------------------------
