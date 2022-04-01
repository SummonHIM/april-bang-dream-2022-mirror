----------------------------------------
-- UIメッセージ処理
----------------------------------------
-- ui message表示
function ui_message(id, p)
	local s = type(p) == 'table'
	if s and p[1] then set_textfont(p[1], id, true) end

	-- text
	local tx = s and p.text or not s and p
	e:tag{"chgmsg", id=(id), layered="1"}
	e:tag{"rp"}
	if tx then e:tag{"print", data=(tx)} end
	e:tag{"/chgmsg"}

	-- pos
	if s and (p.x or p.y) then tag{"lyprop", id=(id), left=(p.x), top=(p.y)} end
end
----------------------------------------
-- ui help
----------------------------------------
-- help設定の確認
function uihelp_check(nm)
	local fl = nm == 'adv' and "game_mwhelp" or "game_uihelp"
	return init[fl] == "on"
end
----------------------------------------
-- ui help font設定
function set_uihelp(id, nm)
	if uihelp_check(nm) then
		del_uihelp()
		if id and nm then
			scr.uihelp = id
			ui_message(id, { nm })
		end
	end
end
----------------------------------------
-- ui help消去
function del_uihelp()
	local id = scr.uihelp
	if id then
		ui_message(id)
		scr.uihelp = nil
	end
end
----------------------------------------
-- ボタンover時にcsvを参照する
function uihelp_over(p)
	local nm = p.name
	if uihelp_check(nm) then
		local id = scr.uihelp
		local gr = btn.name
		local tb = gr and getLangHelp(gr)

		-- adv
		if nm == 'adv' then
			local c = conf.mwhelp
			if flg.txclick or c ~= 1 then id = nil end
		end

		-- 表示
		if id and gr and nm then
			local tx = tb[nm]
			if not tx then
				local v  = getBtnInfo(nm)
				if v then
					local p1 = v.p1
					local p2 = v.p2
					if p1 == "help" and p2 then
						tx = tb[p2]

					-- save/load/favo
					else
						tx = uihelp_saveload(tb[p1], p1, p2)
					end
				end
			end
			if tx then
				ui_message(id, tx)

				-- textセンタリング
				local y  = 0
				local bm = btn and btn.name
				if bm then
					local hp = init["uihelp_"..bm]
					if hp then
						tag{"chgmsg", id=(id)}
						tag{"var", name="t.ht", system="get_message_layer_height"}
						local ht = tn(e:var("t.ht"))
						tag{"/chgmsg"}
						y = mulpos(hp) - ht
						if y > 0 then y = math.floor(y / 2) end
					end
				end
				tag{"lyprop", id=(id), top=(y)}
			end
		end
	end
end
----------------------------------------
function uihelp_out(p)
	local id = scr.uihelp
	if id then ui_message(id) end
end
----------------------------------------
function uihelp_saveload(tx, nm, no)
	local qs = flg.saveqload	-- qload flag

	----------------------------------------
	-- セーブデータ番号計算
	local getSaveNum = function()
		local pg = qs and game.qsavehead or (flg.save.page-1) * init.save_column
		return pg + no
	end

	-- 番号変換
	local changeSaveNum = function(tx)
		if tx and tx:find("[num]") then
			local nm = "No.0001"
			local md = init.uihelp_savemode or 4
			if type(md) == "table" then
				local n1 = md[1] or 2
				local n2 = md[2] or 2
				local pg = qs and "Quick." or string.format("No.%0"..n1.."d-", flg.save.page)
				nm = pg..string.format("%0"..n2.."d", no)
			else
				local nb = flg.save.page				-- ページ番号
				local pg = (nb-1) * init.save_column	-- ページ先頭を計算
				local zz = "No.%0"..md.."d"
				nm = qs and string.format("Quick.%02d", no) or string.format(zz, pg + no)
			end
			tx = tx:gsub("%[num%]", nm)
		end
		return tx
	end

	----------------------------------------
	-- ui振り分け
	local tz = { save=2, load=1, favo=2, move=1, edit=1, del=1 }	-- ボタンp1
	local gr = btn.name
	local tb = gr and getLangHelp(gr)
	local sw = {

	save = function()
		local no = getSaveNum()
		if tz[nm] == 2 and isSaveFile(no) then tx = tb.save2 end
		tx = changeSaveNum(tx)
	end,

	load = function()
		local no = getSaveNum()
		if not isSaveFile(no) then tx = nil end
		tx = changeSaveNum(tx)
	end,

	favo = function()
		local no = getSaveNum()
		local s  = sys.favo[no]
		if tz[nm] == 2 and flg.favo then
			if s then tx = tb.favos2		-- 上書き
			else	  tx = tb.favos1 end	-- 保存
		elseif not s then tx = nil end
		tx = changeSaveNum(tx)
	end,
	}
	-- move
	if flg.save and flg.save.move then
		tx = tb.move and tb.move.move
		tx = changeSaveNum(tx)

	-- その他
	elseif tx and tz[nm] and sw[gr] then sw[gr]() end
	return tx
end
----------------------------------------
-- 
----------------------------------------
-- lang
function getLangHelp(nm)
	local r = {}
	local z = lang and lang.uihelp or {}
	if nm and z[nm] then r = z[nm] end
	return r
end
----------------------------------------
