----------------------------------------
-- システム変数
----------------------------------------
openui_table = {
		menu = { "menu_init",	"menu_reset",	"menu_close", },	-- menu
		mnal = { "mnal_init",	"mnal_reset",	"mnal_close", },	-- manual
		blog = { "blog_init",	"blog_reset",	"blog_close", },	-- backlog
		sbck = { "sbck_init",	"sbck_reset",	"sbck_close", },	-- scene back
		save = { "save_init",	"save_reset",	"save_close", },	-- save
		load = { "load_init",	"save_reset",	"save_close", },	-- load
		favo = { "favo_init",	"save_reset",	"save_close", },	-- お気に入りボイス
		conf = { "conf_init",	"conf_reset",	"conf_close", },	-- config
--		ttl1 = { "title_init",	"title_reset",	"title_close", },	-- title

		flow = { "flow_init",	"flow_reset",	"flow_close", },	-- flowchart
		tbui = { "tbui_init",	"tbui_reset",	"tbui_close", },	-- tablet ui

		cgmd = { "extra_cg_init",	"extra_cg_reset",	"extra_cg_close", },	-- cg mode
		scen = { "extra_scene_init","extra_scene_reset","extra_scene_close", },	-- scene mode
		bgmd = { "extra_bgm_init",	"extra_bgm_reset",	"extra_bgm_close", },	-- bgm mode
		ctmd = { "extra_cat_init",	"extra_cat_reset",	"extra_cat_close", },	-- cat mode
}
----------------------------------------
-- ■ セーブされる変数の登録
scr = {}	-- スクリプトで使用する変数 / local
log = {}	-- スクリプトで使用する変数 / local backlog専用
gscr = {}	-- スクリプトで使用する変数 / global
sys = {}	-- システムで使用する変数	/ global
--conf = {}	-- config data				/ global
----------------------------------------
-- ■ セーブされない変数
init = {}	-- システム設定
tags = {}	-- タグフィルタ
e:setTagFilter(tags)
----------------------------------------
-- ■テーブルの初期化
----------------------------------------
function vartable_init()
	----------------------------------------
	-- ■セーブされる - global
	----------------------------------------
	-- システムデータ
	if not scr	then scr = {} end	-- スクリプトで使用／セーブされる
	if not log	then log = {} end	-- バックログデータ／セーブされる
	if not gscr	then gscr = {} end	-- グローバルテーブル
	if not sys	then sys = {} end	-- システムテーブル
	----------------------------------------
	-- 変数
	if not scr.vari		then scr.vari	 = {} end	-- f.変数
	if not gscr.vari	then gscr.vari	 = {} end	-- sf.変数
	----------------------------------------
	-- 見たフラグ
	if not gscr.bg		then gscr.bg	 = {} end	-- BGを見たフラグ
	if not gscr.ev		then gscr.ev	 = {} end	-- EVを見たフラグ
	if not gscr.evset	then gscr.evset	 = {} end	-- EVセットを見たフラグ
	if not gscr.bgm		then gscr.bgm	 = {} end	-- BGMを再生したフラグ
	if not gscr.movie	then gscr.movie	 = {} end	-- 動画を見たフラグ
	if not gscr.scr		then gscr.scr	 = {} end	-- スクリプトを見たフラグ
	if not gscr.scene	then gscr.scene	 = {} end	-- シーンを見たフラグ
	if not gscr.select	then gscr.select = {} end	-- 選択肢の既読テーブル
	if not gscr.aread	then gscr.aread  = {} end	-- 既読フラグ

	----------------------------------------
	-- ADV
	if not gscr.adv		then gscr.adv	 = {} end	-- ADV汎用
	if not scr.adv		then scr.adv	 = {} end	-- ADV汎用
	if not scr.mw		then scr.mw	 	= {} end	-- MW
	if not scr.se		then scr.se	 	= {} end	-- SE
	if not scr.bgm		then scr.bgm 	= {} end	-- BGM
	if not scr.lvo		then scr.lvo	= {} end	-- loop voice
	if not scr.blj		then scr.blj 	= {} end	-- BLJ
	----------------------------------------
	-- SAVE/LOAD
	if not sys.saveslot then sys.saveslot = {} end
	----------------------------------------
	-- ■セーブされる - local
	scr.file = ""

	-- stack初期化
	initVariStack("varistack")
	initVariStack("bselstack")

	-- reset対策
	scr.clickjump= nil

	----------------------------------------
	-- ■セーブされない
	adv_flagreset()		-- ADVフラグリセット
end
----------------------------------------
-- ■ セーブされない
----------------------------------------
-- システム変数
----------------------------------------
quake_idtable = {
	al = '1',
	gr = '1.0',
	mw = (init.mwid or '1.80')..".mw",
}
----------------------------------------
