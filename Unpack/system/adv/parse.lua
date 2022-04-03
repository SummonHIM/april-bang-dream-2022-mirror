----------------------------------------
-- file関数
----------------------------------------
-- ■ parseIni関数
function parseIni(file)
	local ret = nil
	if e:isFileExists(file) then
		local dx = e:file(file):gsub("\r\n", "\n")
		if dx then
--			keys = {}
			ret  = {}
			for i, v in ipairs(split(dx, "\n")) do
				local a = v and v:sub(1, 1) or ";"
				if a == '[' or a ~= ";" and v:find("=") then
					v = v:gsub("\"(.*)\"", function(k) return k:gsub(" ", "<>") end)
					v = v:gsub("[ 	]", ""):gsub("<>", " ")
					table.insert(ret, v)
				end
			end
		end
	end
	return ret
end
----------------------------------------
-- ■ parseCSVLine関数
-- e:file()を使用して行単位で読み込む
function parseCSVLine(file, code)
	local r = {}			-- テーブル初期化
	local d = e:file(file)	-- file の読み込み
	if d then
		-- 中身を取り出す
		for k, v in ipairs(split(d, "\r\n")) do
			-- 空行とコメント行は飛ばす
			if v ~= '' and v:sub(1, 2) ~= '//' then

				-- sjis → utf-8変換
				if code == 'utf8' then v = code_utf8(v) end

				-- スペースの削除
				v = v:gsub("[ 	]", "")

				-- http/https
				v = v:gsub("http://", "<http>")
				v = v:gsub("https://", "<https>")

				-- 行内にコメントがあったら取り除く
				local a = v:find("//")
				if a then v = v:sub(1, a-1) end

				-- http/https
				v = v:gsub("<http>", "http://")
				v = v:gsub("<https>", "https://")

				-- 書き込み
				table.insert(r, v)
			end
		end
	else
		error_message(file, "が見つかりませんでした")
		r = nil
	end
	return r
end
----------------------------------------
-- ■ parseCSV関数
-- ret[y][x]型 二次元テーブルにして返す
function parseCSV(file, code, flag)
	local d = flag or ','

	-- ファイルの読み込み
	local datas = parseCSVLine(file, code)
	if not datas then return end

	-- テーブル初期化
	local r = {}

	-- 中身を取り出す
	for i, v in ipairs(datas) do
		table.insert(r, split(v, d))
	end
	return r
end
----------------------------------------
-- ■ ui専用parseCSV関数
-- ret[key][x]型 二次元連想テーブルにして返す
function parseCSVui(filename)

	-- ファイルの読み込み
	local datas = parseCSVLine(filename)
	if not datas then return end

	-- テーブル初期化
	local ret = {}

	-- 中身を取り出す
	for i, val in ipairs(datas) do
		local r = split(val, ',')
		local t = {
			["id"]	= r[2],
			["x"]	= r[3],
			["y"]	= r[4],
			["btn"]	= r[5],
			["move"]= r[6],
			["act"]	= r[7]
		}
		ret[r[1]] = r
	end
	return ret
end
----------------------------------------
-- ■ parseCSVtable関数
-- ret[key] = {} １つ目の要素をkeyに、残りを配列として返す(空要素は詰める / flag=trueの場合はkeyを数値で返す
function parseCSVtable(filename, flag)

	-- ファイルの読み込み
	local datas = parseCSVLine(filename)
	if not datas then return end

	-- テーブル初期化
	local ret = {}

	-- 中身を取り出す
	for i, val in ipairs(datas) do
		local r = split(val, ',')
		local h = table.remove(r, 1)
		if flag then h = tonumber(h) end
		ret[h] = r
	end
	return ret
end
----------------------------------------
-- ■ parse_ini関数
-- e:file()を使用して読み込む
-- key = value 形式のデータをtableで返す
function parse_ini(file)

	-- ファイルの読み込み
	local dx = parseCSVLine(file)
	if not dx then return end

	-- 中身を取り出す
	local r = {}
	for i, v in ipairs(dx) do
		if v == "" then
		elseif v:sub(1, 1) == ';' then
		else
			-- 全角文字はutf8に変換
			if not v:find("^[%[%]a-zA-Z0-9_=\"]+$") then v = code_utf8(v) end

			-- 分離
			local f = split(v, "=")
			r[f[1]] = f[2]
		end
	end
	return r
end
----------------------------------------
