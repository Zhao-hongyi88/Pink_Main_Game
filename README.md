# Pink_Main_Game

Godot 4.7 的 2D 叙事游戏程序原型。当前版本只使用占位视觉，主页作为游戏统一入口。

## 当前模块

- `core/navigation`：集中式页面路由，包含 Main Menu、Lobby 和剧情占位页。
- `core/save`：通用存档协调器，后续系统可注册各自的数据分区。
- `systems/main_axis`：数据驱动的主线节点定义与运行时进度。
- `data/main_axis`：默认占位主线数据。
- `scenes/main/main_menu.tscn`：Main Menu 主场景，组合背景、控制脚本与独立 UI 场景。
- `scenes/main/lobby.tscn`：Start 按钮进入的 Lobby 占位场景。
- `scenes/ui/time_display.tscn`：可初始化、暂停并实时递减的独立倒计时组件。
- `scenes/ui/rule_panel.tscn`：规则说明覆盖层。
- `scripts/main/main_menu.gd`：Main Menu 控制脚本。
- `scripts/ui/time_display.gd`：时间显示脚本。
- `scenes/story`：用于验证主线闭环的剧情占位页。

## 扩展约定

新增主线内容时，优先在 `default_main_axis.tres` 中增加节点；新增页面时在 `SceneRouter.ROUTES` 注册路由。NPC、对话、证据、回忆等系统应保持独立，并通过 `SaveService.register_section` 注册自己的存档数据，不把业务状态写入主页场景。
