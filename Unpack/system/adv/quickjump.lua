----------------------------------------
-- クイックジャンプ制御
----------------------------------------
local ex = {}
----------------------------------------
-- 実行するtagと順番(上から実行)
ex.tag_table = {
	"tone",			-- セピア等
	"timezone",		-- 時間帯
	"bg",			-- 背景
	"fgf",			-- frame
	"fg",			-- 立ち絵
	"fgact",		-- 立ち絵アクション(loop)
	"bgm",			-- bgm
	"se",			-- se
	"lvo",			-- ループ音声
	"ex",			-- 拡張タグ
	"menuoff",		-- メニューon/off
	"autoplay",		-- 自動実行タグ
	"mw",			-- メッセージウィンドウ(旧)
	"msg",			-- メッセージウィンドウ(新)
	"savetitle",	-- セーブタイトル
	"scene",		-- シーンタグ
	"line",			-- lineタグ
	"user",			-- userタグ
}
----------------------------------------
function quickjump(no, flag)
	-- 現在のblockが存在するか確認しておく
	local p  = log.stack[no]
	local bl = p.block
	readScriptFile(p.file)		-- 読み込んでおく
	if not ast[bl] then
		local fl = p.file
		local mx = no
		for i=mx, 1, -1 do
			-- fileが異なっている場合は読み直す
			p = log.stack[i]
			if fl ~= p.file then
				if readScriptFile(p.file) then
					fl = p.file
					scr.ip.file = fl
				end
			end

			-- blockが存在した場合はそこを呼ぶ
			if ast[p.block] then
				no = i
				break
			end
		end
	end

	-- いつも通り
	local file = p.file		-- script file
	local blj  = p.blj		-- backlog jump
	local chk  = flag == true and nil or true
	local ws   = checkWasmsync() and scr.ip.file	-- wasmsyncは現在のファイルを入れておく
	scr.blj = blj

	----------------------------------------
	-- 画面初期化
	if chk then
		adv_cls4()			-- テキスト消去

		-- ロード時は音を停止しない
		if not loadstart then
			allsound_stop{ time=0 }
--			reset_voice()
		end

		----------------------------------------
		-- 変数を巻き戻す
		local vl = p.eval
		if vl then
			get_stack_eval(vl)
		else
			-- データが無いので念のためリセット
			log.vari = {}
			scr.vari = {}
		end

		----------------------------------------
		-- bselを巻き戻す
		local vl = p.bsel
		if vl then
			delBackSelect(vl)
		end
	end
	reset_bg()
	sv.delpoint()			-- saveflag delete
	mw_facedel(true)		-- mwface delete (emote用)
	delImageStack()			-- cache delete
	sesys_reset()			-- sound reset
	menuon()				-- menu on
	mw_time()				-- mw timeを戻す
	mwline_reset()			-- line
	scr.tone = nil			-- tone color
	scr.zone = nil			-- 時間帯
	scr.novel = nil			-- novel
	scr.flowposition = nil	-- フローチャート位置情報削除
	loadstart = nil			-- ロード処理フラグ
	if smex then smex.sm_close() end	-- sm

	-- user
	local nm = "user_quickjumpreset"
	if _G[nm] then _G[nm]() end

	-- 選択肢
	if scr.select then
		select_reset()		-- reset
		set_message_speed()	-- mspeed復帰
	end

	----------------------------------------
	-- 現在読み込まれてるscript fileと違うのであれば読み直す
	local sf = scr.ip.file
	local checkscript = function(nm, p, flag)
		local r = nil
		local file = p and p[1]
		if file and sf ~= file then
			local r = readScriptFile(file)
			if not r then
				error_message(file.."の読み込みに失敗しました")
				readScriptFile(s)
				file = sf
			end
			sf = file
		end

		-- astを返す
		if p and nm ~= 'load' then
			-- ast一致
			if ast[p[2]] then
				local sn = p[4]
				if sn then
					r = tcopy(ast[p[2]].delay[sn][p[3]])
				else
					r = tcopy(ast[p[2]][p[3]])
				end

				-- ファイル内だけでも検索する / パッチでも使うはず
				if r[1] ~= nm then
					error_message(nm.."がみつかりませんでした")
					r = nil
				end

			else
				error_message(nm.."がみつかりませんでした")
			end
		end
		return r
	end

	----------------------------------------
	-- 実行
	local mwnm = "bg01"

	-- noの情報を取得して描き直す
	flg.blj = true
	for i, nm in ipairs(ex.tag_table) do
		local p  = blj[nm]
		local sw = {}

		----------------------------------------
		-- 色調
		sw.tone = function(p)
			local a = checkscript('colortone', p)
			colortone(a)
		end

		----------------------------------------
		-- 時間帯
		sw.timezone = function(p)
			local a = checkscript('timezone', p)
			timezone(a)
		end

		----------------------------------------
		-- bg
		sw.bg = function(p)
			for id, t in pairs(p) do
				local a = checkscript('bg', t)
				if a then
					a.x2=nil a.y2=nil a.z2=nil a.notrans=nil
					image_view(a, true)
				end
			end
		end

		----------------------------------------
		-- fg
		sw.fg = function(p)
			for id, t in pairs(p) do
				local a = checkscript('fg', t)
				if a then
					local m = a.mode
					if m >= 2 then
						a.disp=nil a.mx=nil a.my=nil a.x2=nil a.y2=nil a.z2=nil
						fg(a)
					end

					-- face
					if m == 1 or m == 3 then
						local ch = a.ch
						if ch then
							if not scr.face then scr.face = {} end
							scr.face[ch] = a
						end
					end
				end
			end
		end

		----------------------------------------
		-- fgact
		sw.fgact = function(p)
			for id, t in pairs(p) do
				local a = checkscript('fgact', t)
				if a then
					fgact(a)
				end
			end
		end

		----------------------------------------
		-- fgf
		sw.fgf = function(p)
			for id, t in pairs(p) do
				local a = checkscript('fgf', t)
				if a then
					a.disp = nil
					fgf(a)
				end
			end
		end

		----------------------------------------
		-- bgm
		sw.bgm = function(p)
			local a = checkscript('bgm', p)
			if a then bgm(a) end
		end

		----------------------------------------
		-- se
		sw.se = function(p)
			for id, t in pairs(p) do
				local a = checkscript('se', t)
				if a then sesys_se(a) end
			end
		end

		----------------------------------------
		-- lvo
		sw.lvo = function(p)
			for id, t in pairs(p) do
				local a = checkscript('lvo', t)
				if a then sesys_lvo(a) end
			end
		end

		----------------------------------------
		-- mw
		sw.mw = function(p)
			local a = checkscript('mw', p)
			mwnm = 'bg0'..(a.no or 1)
		end

		----------------------------------------
		-- msg
		sw.msg = function(p)
			local a = checkscript('msg', p)
			mw(a)
		end

		----------------------------------------
		-- menuoff
		sw.menuoff = function(p)
			menuoff()
		end

		----------------------------------------
		-- autoplay
		sw.autoplay = function(p)
			local a = checkscript('autoplay', p)
			tags.autoplay(e, a)
		end

		----------------------------------------
		-- title
		sw.savetitle = function(p)
			local a = checkscript('savetitle', p)
			if a then tags.savetitle(e, a) end
		end

		----------------------------------------
		-- scene area
		sw.scene = function(p)
			local a = checkscript('scene', p)
			if a then tag_scene(a) end
		end

		----------------------------------------
		-- line
		sw.line = function(p)
			local a = checkscript('line', p)
			if a then mwline_quicktags(a, no, flag) end
		end

		----------------------------------------
		-- user
		sw.user = function(p)
			for id, t in pairs(p) do
				local a = checkscript('user', t)
				if a then tags.user(e, a) end
			end
		end

		----------------------------------------
		-- 呼び出し
		if p and sw[nm] then sw[nm](p) else

			if p then message(nm) end

		end
	end
	flg.blj = nil

	----------------------------------------
	-- mwを戻す
--	setMWImage(mwnm)
	setMWFont()

	----------------------------------------
	if chk then
		-- ファイルを読み直す
		checkscript('load', { file })
		scr.ip.file = file
		local block = p.block
		local count = 1

		----------------------------------------
		-- call stackを巻き戻す
		local gss = p.gss			-- gamescript stack
		if gss and init.game_stack == 'on' then
			local max = #gss
			if max > 0 then
				local g = gss[max]
				scr.gss = tcopy(gss)
			end
		else
			-- データが無いので念のためリセット
			scr.gss = {}
		end

		----------------------------------------
		-- log dataを現在位置へ
		local n = no + 0
		local m = #log.stack
		for i=n, m do
			table.remove(log.stack, n)
		end

		----------------------------------------
		-- 移動準備
		local r = readScriptFile(file)	-- 読み直しておく
		local block = block				-- script block
		local count = count				-- script count
		local t = ast[block]

		-- bsel / 前の選択肢に戻る
		if flag == "bsel" then
			for i, v in ipairs(t) do
				if v[1] == "select" then
					count = i
					break
				end
			end

		-- nsel / 次の選択肢へ進む
		elseif flag == "nsel" then
			flag = "ui"
			count = scr.ip.count or 1

		-- exskip
		elseif flag == "exskip" then
			flag = "ui"
			count = 1
			flg.exskipjump = true	-- exskipjumpフラグを立てておく
			tag{"exec", command="skip", mode="1"}
			lyc2{ id="exskip", file=(init.black) }

		-- その他
		else
			local com = { sm=1, text=1, fgact=1 }
			for i, v in ipairs(t) do
				local a = v[1]
				if com[a] then
					count = i
					break
				end
			end
		end

		-- mw reset
		msg_reset()

		-- novel / line
		scr.ip.novel = p.novel		-- novel

		-- 移動する
		scr.tagstack = nil
		scr.ip.block = block
		scr.ip.count = count or 1
		scr.ip.textcount = nil
		checkAread()				-- 既読チェック
		autocache(true)				-- 自動キャッシュ

		-- 全体シェーダー反映
		flg.trans = true
		shader_trans{}

		if flag == "ui" or flag == "bsel" then
			scr.uifunc = nil
			flg.ui = nil
			if ws and ws ~= file then
				e:tag{"jump", file="system/script.asb", label="wasmcache_blj"}	-- wasmsync読み直し
			else
				e:tag{"jump", file="system/script.asb", label="main_blj"}		-- 普通に進行
			end

		-- zapping
		elseif flag == "zap" then
			e:tag{"jump", file="system/script.asb", label="main_zap"}
		else
			e:tag{"jump", file="system/script.asb", label="main"}
		end
	end
end
----------------------------------------
-- 暗転を挟む
function quickjumpui(no, name)
	flg.qjno = no
	local time = init.ui_fade
	local s = flg.sysvoid

	-- 全音停止
	estag("init")
	if not loadstart then
		estag{"allsound_stop", { mode="system", time=(time) } }
	end

	-- uiから来た
	if name == "blog" then
		estag{"blog_reset"}
	else
		estag{"notification_clear"}
		estag{"adv_cls4"}
		estag{"msg_hide"}
	end

	-- mask
	estag{"uimask_on"}

	-- 共通消去
	local nm = name == "bsel" and name or "ui"
	estag{"reset_bg"}
	estag{"uitrans", time}
	if debug_flag and game.trueos == "windows" and name ~= "load" then		-- デバッグ時の処理
		scr.ip.file = "_debugreset"
		if debug_debugmessage then
			estag{"debugToolConverter"}
		else
			estag{"debugConvertStart"}
		end
	end

	-- sysvo待機
	if s then
		estag{"wait", se=(s), input="0"}	-- sysvo待機
	end

	-- jump
	estag{"quickjumpui2", { no, nm }}
	estag()
end
----------------------------------------
function quickjumpui2(p)
	ResetStack()	-- スタックリセット
	quickjump(p[1], p[2])
end
----------------------------------------
-- msgshow
function quickjumpmsg()
	adv_cls4()			-- テキスト消去
	msg_reset()
	estag("init")

	-- novel
	local s = scr.ip.novel
	if s then
		set_message_speed_tween(0)			-- 瞬間表示に切り替え
		estag{"quickjumpnovel", s}			-- novel text描画
		estag{"uitrans", { time="0" }}		-- 表画面に載せておく
		estag{"set_message_speed"}			-- text speed戻し
		scr.ip.novel = nil
	end

	-- suspend
	estag{"load_suspendcheck"}

	-- main
	estag{"quickjumpmsgmain"}
	estag()
end
----------------------------------------
function quickjumpmsgmain()
	-- mw処理 / line
	local block = scr.ip.block
	local z = ast[block].text or {}

	-- hide
	if z.hide then
		msgcheck("off")

	-- [line]
	elseif type(z.linemode) == "table" then
		scr.mw.msg = true
		msgcheck("sys")

	-- 
	elseif scr.adv.menu then
		scr.mw.msg = true
		msgcheck("on")

	-- select / count位置を調整する
	elseif ast[block].select then
		local v  = ast[block]
		local ct = scr.ip.count or 1
		for i=ct, 1, -1 do
			local nm = v[i][1]
			if nm == "text" or nm == "select" then
				scr.ip.count = i
			end
		end
	end

	-- 有効化
	init_adv_btn()
	autoskip_init()
end
----------------------------------------
-- novel text
function quickjumpnovel(p)
	local no = p.no
	local fl = ""
	local sv = scr.ip.file
	if no and no >= 1 then
		local v = log.stack
		local m = #v
		for i=no, 1, -1 do
			local n = m - i + 1
			local t = v[n]
			local f = t.file
			if f ~= fl then
				readScriptFile(f)	-- read script
				fl = f
			end

			-- text描画
			local bl = t.block
			local tx = ast[bl].text

			-- name
			local nm = getNameChar(tx, true)
			if nm then message_name(nm) end

			-- text
			local ln = get_language(true)
			mw_textloop{ text=(tx), lang=(ln) }

			-- 改行
			local s = scr.novel
			scr.novel.no = s.no + 1
			if not tx.join then rt2() end
		end

		-- 読み直し
		if fl ~= sv then
			readScriptFile(sv)		-- scriptを戻す
		end
	end
end
----------------------------------------
-- 実行情報
----------------------------------------
-- タグ実行時に情報を格納する
function storeQJumpStack(nm, p, dl)
	-- フラグがonであれば保存しておく
	if init.game_quickjump ~= 'on' then return end

	local sw = {}
	----------------------------------------
	-- 呼ばれたら現在位置を返す
	local getBlock = function(v)
		local d = v	-- and 'delay'
		local f = scr.ip.file
		local b = scr.ip.block
		local c = scr.ip.count or 1
		return { f, b, c, d }
	end
	----------------------------------------

	----------------------------------------
	-- 背景
	sw.bg = function(p)
		local id = (p.id or 0) + 1
		stackBLJ('bg', getBlock(dl), id)
		if id == 1 and p.face ~= 1 then
			stackBLJ('fg', nil)
			stackBLJ('fgf', nil)
			stackBLJ('fgact', nil)

			-- 背景以外全削除する
			if scr.blj.bg then
				for i, v in pairs(scr.blj.bg) do
					if i ~= 1 then stackBLJ('bg', nil, i) end
				end
			end
		end
	end

	----------------------------------------
	-- cgdel
	sw.cgdel = function(p)
		local id = (p.id or 0) + 1
		if id == 0 and scr.blj.bg then
			-- 背景以外全削除する
			for i, v in pairs(scr.blj.bg) do
				if i ~= 1 then stackBLJ('bg', nil, i) end
			end
		else
			stackBLJ('bg', nil, id)
		end
	end

	----------------------------------------
	-- 立ち絵
	sw.fg = function(p)
		local id = tn(p.id or 1)
		local md = tn(p.mode)
		if md == -2 then
			stackBLJ('fg', nil)
			stackBLJ('fgact', nil)
			flg.qjfgdel = true		-- quickjump fg flag
		elseif md == -1 then
			stackBLJ('fg', nil, id)
			stackBLJ('fgact', nil, id)
		else
			-- idが変わっていたら削除
			local ch = p.ch
			local z  = scr.img.fg or {}
			local d  = z[ch] and z[ch].p or {}
			local ix = d.id
			if not flg.qjfgdel and ix and (p.resize or ix ~= id) then stackBLJ('fg', nil, ix) end

			-- 格納
			stackBLJ('fg', getBlock(dl), id)
		end
	end

	----------------------------------------
	-- 立ち絵アクション
	sw.fgact = function(p)
		local id = tn(p.id or 1)
		local lp = image_actloop(p)
		local ac = p.act
		if lp == -1 then		 stackBLJ('fgact', getBlock(dl), id)
		elseif ac == "停止" then stackBLJ('fgact', nil, id) end
	end

	----------------------------------------
	-- fgframe
	sw.fgf = function(p)
		local fr, nm = get_fgfid(p)
		local md = tn(p.mode)
		if md == -1 then
			stackBLJ('fgf', nil, nm)

			-- 同時に立ち絵も消す
			local ch = scr.img.fgf and scr.img.fgf[nm] and scr.img.fgf[nm].ch
			if ch then
				local id = scr.img.fgf[ch].fgid
				if id then
					stackBLJ('fg', nil, id)
					stackBLJ('fgact', nil, id)
				end
			end
		else
			stackBLJ('fgf', getBlock(dl), nm)
		end
	end

	----------------------------------------
	-- 色調
	sw.colortone = function(p)
		local r = p.mode == 'reset'
		if r then stackBLJ('tone', nil)
		else	  stackBLJ('tone', getBlock(dl)) end
	end

	----------------------------------------
	-- 時間帯
	sw.timezone = function(p)
		local r = p.mode == 'reset'
		if r then stackBLJ('timezone', nil)
		else	  stackBLJ('timezone', getBlock(dl)) end
	end

	----------------------------------------
	-- mw
	sw.mw = function(p)
		local no = p.no
		if no == 1 then stackBLJ('mw', nil)
		else			stackBLJ('mw', getBlock(dl)) end
	end

	----------------------------------------
	-- msg
	sw.msg = function(p)
		stackBLJ('msg', getBlock(dl))
	end

	----------------------------------------
	-- media
	----------------------------------------
	sw.bgm = function(p)
		if p.unlock ~= 1 then
			local st = tn(p.stop)
			if st == 1 then stackBLJ('bgm', nil)
			else			stackBLJ('bgm', getBlock(dl)) end
		end
	end

	----------------------------------------
	sw.se = function(p)
		local id = tn(p.id or 1)
		local st = tn(p.stop)
		local lp = tn(p.loop)
		if st == 1 then
			-- 全停止
			if id == -1 then
				stackBLJ('se', nil)
			else
				stackBLJ('se', nil, id)
			end

		-- loopseは保存する
		elseif lp == 1 then
			stackBLJ('se', getBlock(dl), id)

		-- 単発seは保存しない / loopseを同IDで上書きしている可能性があるので消す
		else
			stackBLJ('se', nil, id)
		end
	end

	----------------------------------------
	sw.vo = function(p)
--	dump(p)
	end

	----------------------------------------
	sw.vostop = function(p)
		local ch = p.ch
		if ch then
			stackBLJ('lvo', nil, ch)	-- lvo停止
		else
			stackBLJ('lvo', nil)		-- lvo全停止
		end
	end

	----------------------------------------
	sw.lvo = function(p)
		local ch = p.ch
		if p.stop == 1 then	stackBLJ('lvo', nil, ch)
		else				stackBLJ('lvo', getBlock(dl), ch) end
	end

	----------------------------------------
	-- 演出
	----------------------------------------
	-- quake
	sw.quake = function(p)
--	dump(p)
	end

	-- savetitle
	sw.savetitle = function(p)
		stackBLJ('savetitle', getBlock(dl))
	end

	-- scene area
	sw.scene = function(p)
		local md = p.mode or "end"
		local fl = md == "start" and getBlock(dl)
		stackBLJ('scene', fl)
	end

	-- menuon
	sw.menuon = function(p)
		stackBLJ('menuoff', nil)
	end

	-- menuoff
	sw.menuoff = function(p)
		stackBLJ('menuoff', getBlock(dl))
	end

	-- autoplay
	sw.autoplay = function(p)
		local md = p.mode
		if md == "stop" then
			stackBLJ('autoplay', nil)
		else
			stackBLJ('autoplay', getBlock(dl))
		end
	end

	-- line
	sw.line = function(p)
		local md = p.mode
		if md == "del" then
			stackBLJ('line', nil)
		else
			stackBLJ('line', getBlock(dl))
		end
	end

	-- user
	sw.user = function(p)
		local nm = "user_quickjumpstack"
		if _G[nm] then _G[nm](p, dl) end
	end

	----------------------------------------
	if sw[nm] then sw[nm](p) end
end
----------------------------------------
-- bljにデータを積んでいく
function stackBLJ(nm, p, id)
	if not scr.blj then scr.blj = {} end	-- この変数はリセットしない

	-- 格納する
	if id then
		if not scr.blj[nm] then scr.blj[nm] = {} end
		scr.blj[nm][id] = p
	else
		scr.blj[nm] = p
	end
end
----------------------------------------
-- bljの実行情報を取得する／バックログ
function getQJumpStack()
	local r
	if init.game_quickjump == 'on' then
		r = tcopy2(scr.blj)	-- BackLogJump管理テーブル
	end
	return r
end
----------------------------------------
