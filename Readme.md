# Vim-v2ex

在 vim 下刷新 v2ex。这个插件主要存在价值在于方便看到最新的主题, 使用了 node
后台进程请求数据，查看列表无需等待, 也无需手动刷新。

## 主要功能

* 打开/关闭最新主题列表
* 列表自动更新
* 查看主题详情
* 浏览器打开主题

## 安装

* 需要 node >= 4.0, 命令行下 `node -v` 查看
* 安装 vimproc，如果你使用 [vim-plug](https://github.com/junegunn/vim-plug),
  可添加：

      Plug 'Shougo/vimproc', {'do': 'yes \| make'}

  到 `.vimrc`, 然后 `PlugInstall`
* 非 Mac 用户使用浏览器打开功能，需安装 [vim-shell](https://github.com/xolox/vim-shell), 例如：

          Plug 'xolox/vim-shell'

* 使用 vim-plug 安装本插件：

          Plug 'chemzqm/vim-v2ex', {'do': 'yes \| npm install'}

如使用其它方式安装，须在安装完成后在插件目录下执行 `npm install` (因为 sqlite
使用了 node-gyp，所以安装过程可能稍长)

## 使用

唯一命令 `:V2toggle` 打开关闭主题列表，这个列表是全局是唯一的,

可添加映射，例如：

    nmap <leader>v <Plug>(V2exToggle)

列表打开会自动更新，因为使用 CursorHold 事件，所有并不会影响你正常使用，列表内支持一些快捷键：

* `q` 退出
* `<CR>` 浏览器打开当前主题
* `p` 预览窗口查看当前主题
* `<c-l>` 强制重启后台进程并刷新当前列表

## 限制

* v2ex 的 latest API 存在 5 分钟左右缓存，并非实时
* v2ex 的 latest API 每小时请求限制 120 次, 这个插件只会 1 分钟请求 1 次
* v2ex 不提供查看回复等功能的 API，并不会考虑支持

如有意见/建议，欢迎开 [issue](https://github.com/chemzqm/vim-v2ex/issues)
