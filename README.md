# april-bang-dream-2022-mirror
## English
Here is the BanG Dream 2022 April fool day's game data pack mirror repo.

This game using Artemis WebAssembly engine.

All right by Bushiroad and Craft Egg.

### File description

- The `artemis.data` is the original game data pack
- The `Unpack` folder is `artemis.data`'s unpack data by using GARbro

### Branch
Here has three branchs for this repo

1. The Artemis branchs is original game data
2. The [gh-pages branchs](https://github.com/SummonHIM/april-bang-dream-2022-mirror/tree/gh-pages) is original game site mirror

### Workflow auto pack (Beta)
You can auto pack the data folder to Artemis pfs pack

#### Use Step
1. Clone the project
2. Go to Setting→ Actions→ General. Select the "Allow XXX, and select non-XXX, actions and reusable workflows" (Safe mode) or "Allow all actions and reusable workflows" (Unsafe)
3. Fill "actions/checkout@v3, actions/upload-artifact@v3" into "Allow specified actions and reusable workflows" (If you select "Allow XXX, and select non-XXX, actions and reusable workflows")
4. Go to Actions pack, Click AutoPack, then click "Run Workflow"
5. Select the right branch, then fill the folder name you wanna pack
6. Wait workflow finish, then download file in actions.

#### Known Bugs
1. cannot use the pfs file and cannot read by GARbro

## 中文
该仓库为 BanG Dream 2022 愚人节游戏的数据包镜像站。

该游戏使用 Artemis WebAssembly 引擎。

所有版权归武士道与 Craft Egg 所有。

### 文件说明

- `artemis.data` 为原始游戏数据包
- `Unpack` 文件夹为由 `artemis.data` 解包出来的数据。解包软件使用 GARbro。

### 分支说明
该仓库有三个分支

1. Artemis 分支为原始游戏数据
2. [gh-pages 分支](https://github.com/SummonHIM/april-bang-dream-2022-mirror/tree/gh-pages)为原始游戏网站镜像
