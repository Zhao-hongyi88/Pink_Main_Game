# Pink_Main_Game --- TRAE 完整项目交接规范

&gt; **文档版本：2026-08-17**
&gt; **项目：Pink_Main_Game**
&gt; **开发引擎：Godot 2D**
&gt; **本地项目位置：D:\_Main_Game**
&gt; **用途：TRAE 接管项目时的最高优先级开发规则、项目背景、工作方式与验收标准**

---

## ⚠️ 必须从当前项目读取确认的信息

以下信息**必须从当前项目实际代码/场景/数据中读取确认**，不得根据本文档猜测：

1. 五名 NPC 的正式英文 `display_name`
2. 每名 NPC 的真实 `npc_id`
3. `npc_base.tscn` 的实际节点结构
4. `note_item.tscn` 与 `note_card.tscn` 哪个在运行时被实际引用
5. NoteDetailPopup 的实际尺寸和动画数值
6. Memory 场景路径与返回逻辑
7. 当前项目实际使用的 Unlock Key 列表
8. GameState / NPCProgress 的实际字段
9. 副轴分支名称与具体成果
10. 当前项目 Godot 版本
11. 当前 Git 分支状态与工作区状态
12. `res://tests/` 目录下实际存在的测试
13. 当前项目英文术语表
14. 实际图片资源路径
15. Archive 具体实现

---

## 目录

- [0. TRAE 接手前必须理解的事情](#0-trae-接手前必须理解的事情)
- [1. 信息优先级 / Source of Truth](#1-信息优先级--source-of-truth)
- [2. 禁止想当然](#2-禁止想当然)
- [3. 每一次任务开始前必须告诉用户使用什么模型](#3-每一次任务开始前必须告诉用户使用什么模型)
- [4. 当前 TRAE 模型选择原则](#4-当前-trae-模型选择原则)
- [5. 模型选择绝不能为了省积分牺牲游戏质量](#5-模型选择绝不能为了省积分牺牲游戏质量)
- [6. 用户操作水平与回答方式](#6-用户操作水平与回答方式)
- [7. 报错处理规则](#7-报错处理规则)
- [8. 用户要求 TRAE 指令时](#8-用户要求-trae-指令时)
- [9. 游戏基本定位](#9-游戏基本定位)
- [10. 玩家身份](#10-玩家身份)
- [11. 游戏整体流程](#11-游戏整体流程)
- [12. Main Menu 当前设计方向](#12-main-menu-当前设计方向)
- [13. Archive / NPC推进](#13-archive--npc推进)
- [14. NPC 页面核心体验](#14-npc-页面核心体验)
- [15. 解锁机制必须使用 Unlock Key](#15-解锁机制必须使用-unlock-key)
- [16. 核心系统不得重复创建](#16-核心系统不得重复创建)
- [17. GameState / NPCProgress 核心原则](#17-gamestate--npcprogress-核心原则)
- [18. 五名 NPC 必须保持独立进度](#18-五名-npc-必须保持独立进度)
- [19. NPC 内部 ID 和游戏显示名称必须区分](#19-npc-内部-id-和游戏显示名称必须区分)
- [20. 不允许猜五名 NPC 的最终英文名字](#20-不允许猜五名-npc-的最终英文名字)
- [21. 历史 NPC_A / NPC_B / NPC_C 等仅属于开发占位](#21-历史-npc_a--npc_b--npc_c-等仅属于开发占位)
- [22. NPC01 --- 张远（开发资料名称）](#22-npc01-----张远开发资料名称)
- [23. NPC02 --- 李磊（开发资料名称）](#23-npc02-----李磊开发资料名称)
- [24. NPC03 --- 刘桂兰（开发资料名称）](#24-npc03-----刘桂兰开发资料名称)
- [25. NPC04 --- 苏晴（开发资料名称）](#25-npc04-----苏晴开发资料名称)
- [26. NPC05 --- 王建国（开发资料名称）](#26-npc05-----王建国开发资料名称)
- [27. 每名 NPC 首次接管都必须检查这些内容](#27-每名-npc-首次接管都必须检查这些内容)
- [28. 游戏正式玩家可见语言原则](#28-游戏正式玩家可见语言原则)
- [29. 已经英文化的内容禁止恢复中文](#29-已经英文化的内容禁止恢复中文)
- [30. 中文只允许存在于开发内容](#30-中文只允许存在于开发内容)
- [31. 第一次接管必须进行正式中文残留扫描](#31-第一次接管必须进行正式中文残留扫描)
- [32. PNG/JPG里的中文必须单独检查](#32-pngjpg里的中文必须单独检查)
- [33. 不允许在旧中文图片上随便盖英文 Label](#33-不允许在旧中文图片上随便盖英文-label)
- [34. 中文转英文后必须重新做 UI 排版](#34-中文转英文后必须重新做-ui-排版)
- [35. 已经确定的英文术语不要随意改写](#35-已经确定的英文术语不要随意改写)
- [36. NPCBase 当前已知重要节点](#36-npcbase-当前已知重要节点)
- [37. NPCBase 图片大致用途](#37-npcbase-图片大致用途)
- [38. Runtime UI 与编辑器预览不同](#38-runtime-ui-与编辑器预览不同)
- [39. UI修改必须检查 Runtime Override](#39-ui修改必须检查-runtime-override)
- [40. Note 系统是当前已发生过错误的重点区域](#40-note-系统是当前已发生过错误的重点区域)
- [41. 不要删除另一个 Note Scene](#41-不要删除另一个-note-scene)
- [42. 当前便利贴视觉方向](#42-当前便利贴视觉方向)
- [43. 多余紫色 AccentStrip](#43-多余紫色-accentstrip)
- [44. NoteDetailPopup统一结构](#44-notedetailpopup统一结构)
- [45. NoteDetailPopup功能原则](#45-notedetailpopup功能原则)
- [46. NoteDetailPopup动画](#46-notedetailpopup动画)
- [47. NoteDetailPopup尺寸曾继续调整](#47-notedetailpopup尺寸曾继续调整)
- [48. 图片资源定位开发工具已经制作](#48-图片资源定位开发工具已经制作)
- [49. 当前项目基准分辨率](#49-当前项目基准分辨率)
- [50. 图片资源原则](#50-图片资源原则)
- [51. PNG透明背景](#51-png透明背景)
- [52. 正方形游戏图标](#52-正方形游戏图标)
- [53. 不要擅自批量修改图片](#53-不要擅自批量修改图片)
- [54. 双人开发结构](#54-双人开发结构)
- [55. 主轴主要职责](#55-主轴主要职责)
- [56. 副轴主要职责](#56-副轴主要职责)
- [57. 主副轴核心原则](#57-主副轴核心原则)
- [58. TRAE接手时必须同时检查副轴](#58-trae接手时必须同时检查副轴)
- [59. 第一次副轴检查必须检查 Git](#59-第一次副轴检查必须检查-git)
- [60. 不允许接手时自动 Merge](#60-不允许接手时自动-merge)
- [61. 副轴差异必须分类](#61-副轴差异必须分类)
- [62. 副轴公共文件冲突必须重点检查](#62-副轴公共文件冲突必须重点检查)
- [63. 副轴旧 UI 不能覆盖当前主轴最新 UI](#63-副轴旧-ui-不能覆盖当前主轴最新-ui)
- [64. Binary图片冲突不要自动解决](#64-binary图片冲突不要自动解决)
- [65. Memory系统首次检查](#65-memory系统首次检查)
- [66. Memory必须保持观察者玩法](#66-memory必须保持观察者玩法)
- [67. Memory需要逐人验证](#67-memory需要逐人验证)
- [68. 李磊与刘桂兰 Memory必须独立](#68-李磊与刘桂兰-memory必须独立)
- [69. Memory返回规则需要读取当前项目确认](#69-memory返回规则需要读取当前项目确认)
- [70. 副轴必须接受正式英文化检查](#70-副轴必须接受正式英文化检查)
- [71. 副轴NPC ID一致性](#71-副轴npc-id一致性)
- [72. 副轴 Scene Path 检查](#72-副轴-scene-path-检查)
- [73. 副轴 GameState 接入检查](#73-副轴-gamestate-接入检查)
- [74. 副轴 Save兼容性](#74-副轴-save兼容性)
- [75. 当前历史主轴实现状态](#75-当前历史主轴实现状态)
- [76. 历史重要测试](#76-历史重要测试)
- [77. 修改后的测试范围必须和风险匹配](#77-修改后的测试范围必须和风险匹配)
- [78. 不允许只看 Smoke Test 不看实际游戏效果](#78-不允许只看-smoke-test-不看实际游戏效果)
- [79. 用户运行截图优先级很高](#79-用户运行截图优先级很高)
- [80. 修改完成的定义](#80-修改完成的定义)
- [81. Git安全规则](#81-git安全规则)
- [82. 不要擅自 Commit / Push](#82-不要擅自-commit--push)
- [83. 多人协作时减少 Merge Conflict](#83-多人协作时减少-merge-conflict)
- [84. `.tscn` 特别安全规则](#84-tscn-特别安全规则)
- [85. 不要修改 `.godot/`](#85-不要修改-godot)
- [86. 不要随意修改已有资源目录名称](#86-不要随意修改已有资源目录名称)
- [87. 文件移动属于高风险操作](#87-文件移动属于高风险操作)
- [88. 额度 / 积分优化原则](#88-额度--积分优化原则)
- [89. 但额度优化不能牺牲正确性](#89-但额度优化不能牺牲正确性)
- [90. 明确的UI小任务不要扩大范围](#90-明确的ui小任务不要扩大范围)
- [91. 视觉任务禁止借机重构逻辑](#91-视觉任务禁止借机重构逻辑)
- [92. 数据任务禁止借机修改视觉](#92-数据任务禁止借机修改视觉)
- [93. 测试字符串不代表正式剧情](#93-测试字符串不代表正式剧情)
- [94. 当前完整英文对白是后续重点](#94-当前完整英文对白是后续重点)
- [95. NPC资料英文也属于正式内容](#95-npc资料英文也属于正式内容)
- [96. 人物故事不能被 AI 擅自改写](#96-人物故事不能被-ai-擅自改写)
- [97. 五人故事不要变成同一个模板](#97-五人故事不要变成同一个模板)
- [98. 张远作为黄金样板](#98-张远作为黄金样板)
- [99. 五 NPC最终整体验收](#99-五-npc最终整体验收)
- [100. 首次 TRAE 接管必须使用 Seed-2.1-Pro](#100-首次-trae-接管必须使用-seed-21-pro)
- [101. 第一次接管 --- Step 1：环境确认](#101-第一次接管----step-1环境确认)
- [102. Step 2：核心系统读取](#102-step-2核心系统读取)
- [103. Step 3：确认真实运行引用](#103-step-3确认真实运行引用)
- [104. Step 4：五名 NPC正式数据盘点](#104-step-4五名-npc正式数据盘点)
- [105. Step 5：英文正式版盘点](#105-step-5英文正式版盘点)
- [106. Step 6：副轴接管检查](#106-step-6副轴接管检查)
- [107. Step 7：主副轴差异检查](#107-step-7主副轴差异检查)
- [108. Step 8：测试盘点](#108-step-8测试盘点)
- [109. Step 9：首次接管风险检查](#109-step-9首次接管风险检查)
- [110. 第一次接管结束后必须回复的内容](#110-第一次接管结束后必须回复的内容)
- [111. 第一次接管禁止进行的事情](#111-第一次接管禁止进行的事情)
- [112. 后续每一个任务的标准工作流程](#112-后续每一个任务的标准工作流程)
- [113. 完成报告固定格式](#113-完成报告固定格式)
- [114. 不要假装完成](#114-不要假装完成)
- [115. 不要伪造测试结果](#115-不要伪造测试结果)
- [116. 不要伪造文件或资源](#116-不要伪造文件或资源)
- [117. 如果发现旧 AI报告与项目不一致](#117-如果发现旧-ai报告与项目不一致)
- [118. 用户截图是一种验收证据](#118-用户截图是一种验收证据)
- [119. 不要责怪用户操作](#119-不要责怪用户操作)
- [120. 当前最重要的总体开发目标](#120-当前最重要的总体开发目标)
- [121. 最后一条最高优先级规则](#121-最后一条最高优先级规则)
- [TRAE 第一次收到本文档后的立即任务](#trae-第一次收到本文档后的立即任务)

---

## 0. TRAE 接手前必须理解的事情

这是一个已经持续开发了一段时间、已经拥有现有场景、代码、NPC数据、UI、美术资源、测试和双人协作内容的 Godot 项目。

**这不是一个新项目。**

你的任务不是重新设计 Pink_Main_Game。

你的任务是：

&gt; 在当前真实项目基础上，以最小风险、最少无关修改、最高完成效率，继续把现有游戏制作完成。

从接手开始，必须遵守：

**稳定 &gt; 炫技**

**现有项目兼容性 &gt; 你认为更漂亮的架构**

**实际运行效果 &gt; "代码已经写入"**

**用户最新要求 &gt; AI 自己的设计偏好**

---

## 1. 信息优先级 / Source of Truth

当不同来源的信息发生冲突时，严格按照以下优先级判断。

### 第一优先级

用户当前这一轮最新明确要求。

### 第二优先级

项目仓库当前实际运行代码、场景、数据和资源。

### 第三优先级

本交接文档中定义的长期设计规则。

### 第四优先级

旧聊天、旧设计稿、旧测试字符串、旧占位数据。

---

如果本交接文档与当前项目实际情况存在冲突：

**不要擅自修改项目以符合本交接文档。**

必须告诉用户：

&gt; 当前项目实际实现与交接记录存在以下差异......

然后等待用户决定。

---

## 2. 禁止想当然

绝对禁止：

- 根据文件名猜测实际运行文件
- 根据节点名字猜测用途
- 根据旧聊天猜测当前数据
- 根据旧截图覆盖当前项目
- 根据你自己的偏好重构系统
- 因为文件名"看起来拼错"就改名
- 因为结构"不够优雅"就整理目录
- 因为存在旧文件就自行删除
- 因为测试通过就认为视觉一定正确
- 因为代码写入成功就认为游戏效果已经改变

正确流程必须是：

**搜索实际引用 → 确认真正运行路径 → 定点修改 → 运行验证。**

---

## 3. 每一次任务开始前必须告诉用户使用什么模型

这是用户长期固定要求。

每次准备进行 Pink_Main_Game 的制作、Debug、代码修改、UI修改、测试或架构分析前，回复最前面必须出现：

**推荐模型：XXX**

**任务强度：低 / 中 / 高 / 极高**

必要时增加：

**是否建议切换模型：是 / 否**

并用一句话解释为什么。

---

## 4. 当前 TRAE 模型选择原则

当前主要使用：

- Seed-2.1-Pro
- Seed-2.1-Turbo
- Seed-Code
- 其他可用高级代码模型

如果未来 TRAE 模型列表发生变化，不要死守旧型号。

按照下面的能力等级重新映射。

---

### Seed-Code

用于**明确、低风险、机械性的修改**。

例如：

- Font Color
- Font Size
- Position
- Size
- Rotation
- Texture
- 图片路径
- Button大小
- 一个明确节点的视觉修改
- 单文件简单字符串修改
- 用户已经明确告诉你具体文件和节点

推荐强度：

**低 / 中**

例如：

&gt; 把 NPCName 从黄色改成 #1A1A1A。

这种任务不要浪费高级模型。

---

### Seed-2.1-Pro

Pink_Main_Game 的**核心高级开发模型**。

以下情况优先使用：

- 第一次项目接管
- 不确定真正运行哪个文件
- 多文件联动
- Bug排查
- NPCBase
- DialogueManager
- UnlockSystem
- GameState
- NPCProgress
- Save
- Archive
- SceneRouter
- Memory系统
- 多NPC状态
- JSON与GDScript联动
- 场景切换
- 信号
- NodePath
- Runtime实例化问题
- 不确定 note_item / note_card 谁真正运行
- 主副轴代码冲突
- Git差异分析
- 回归问题
- 架构修改

推荐强度：

**高 / 极高**

原则：

&gt; 如果改错可能破坏游戏逻辑，默认 Seed-2.1-Pro。

---

### Seed-2.1-Turbo

可以用于：

- 快速只读检查
- 简单解释
- 低风险分析

不要作为复杂核心修改的默认模型。

---

### Auto Mode

核心制作阶段不建议长期依赖。

关键修改应该明确知道使用了什么模型。

---

## 5. 模型选择绝不能为了省积分牺牲游戏质量

用户希望控制 TRAE 积分消耗，但优先级是：

**游戏质量第一。**

正确做法：

简单任务使用 Seed-Code。

复杂任务使用 Seed-2.1-Pro。

不要：

为了省积分让轻量模型处理高风险架构问题。

也不要：

一个颜色值修改都使用最高成本模型。

---

## 6. 用户操作水平与回答方式

用户不是专业程序员。

涉及 Godot、Git、代码、TRAE 操作时：

必须按照**小白可以直接照着执行**的方式说明。

---

禁止：

- 一次给多个完全不同方案
- 用大量专业术语不解释
- 让用户"自己找一下"
- 给模糊路径
- 只讲原理
- 一句话包含很多操作
- 明明能搜索项目却要求用户自己判断
- 用户问在哪里却给一大段架构说明

---

正确方式：

如果用户问：

&gt; 这个图片在哪里换？

回答应该类似：

1.  打开 `npc_base.tscn`
2.  左边点击 `Background`
3.  看右侧检查器
4.  找 `Texture`
5.  点击 Texture
6.  选择新的 PNG

---

如果用户说：

&gt; 一个一个告诉我。

必须严格一次只告诉一个步骤。

等待用户操作完再继续。

---

## 7. 报错处理规则

用户发 Godot 红色错误时：

第一步：

用普通中文解释：

**这个错误是什么意思。**

第二步：

告诉用户：

**为什么发生。**

第三步：

只给一套最推荐的解决操作。

不要同时给：

方案A、方案B、方案C。

用户明确偏好：

&gt; 先解释红色代码，再告诉我确定应该怎么做。

---

## 8. 用户要求 TRAE 指令时

用户经常会说：

&gt; 给我 TRAE 指令。

这时候输出应该是一整段：

**可以直接复制给 TRAE Agent 执行的指令。**

必须明确：

- 修改目标
- 修改文件
- 修改节点/函数
- 不允许修改什么
- 验收方式
- 测试要求

不要混入大量无关知识科普。

---

## 9. 游戏基本定位

项目名称：

**Pink_Main_Game**

类型：

**Godot 2D 叙事游戏**

核心主题：

- 时间
- 劳动
- 生存
- 社会压力
- 人生选择
- 时间贷款

---

## 10. 玩家身份

玩家不是救世主。

特别是在 Memory 中：

玩家是：

**观察者。**

玩家可以：

- 观察
- 阅读
- 调查
- 点击
- 听对话
- 经历角色过去的重要人生节点

玩家不能：

- 改变历史
- 拯救 NPC
- 阻止过去发生
- 改写人物命运
- 制造分支人生
- 产生"选择不同所以过去改变"的玩法

Memory 的目的：

&gt; 让玩家理解这个 NPC 为什么最终走到了现在。

---

## 11. 游戏整体流程

目标主流程：

Main Menu

↓

START

↓

进入当前 NPC 页面

↓

与 NPC 交流

↓

逐步解锁人物信息

↓

逐步解锁 Related Data / Evidence

↓

完成核心交流

↓

解锁 Memory入口

↓

进入关键人生经历

↓

玩家作为观察者体验过去

↓

Memory结束

↓

回到现实流程

↓

NPC状态保持

↓

Archive / 主流程推进

↓

进入下一名 NPC。

---

## 12. Main Menu 当前设计方向

当前设计已经简化：

不需要复杂大厅 NPC 点击系统。

START：

应该进入当前选中的 NPC。

最初默认进入第一名 NPC。

Archive：

承担 NPC查看 / 切换 / 后续推进功能。

---

## 13. Archive / NPC推进

项目设计中存在：

- selected_npc_id
- unlocked_npc_ids
- NPCProgress
- NPC完成状态

NPC完成后：

应该能够：

- 解锁下一名
- 选择下一名
- 返回主页后继续

具体实现**必须从当前项目读取确认**。

不要根据旧文档重新实现第二套 Archive。

---

## 14. NPC 页面核心体验

首次进入一个全新 NPC 页面时：

原则上只显示必要的初始视觉内容，例如人物照片。

下面这些信息应该随着交流逐步解锁：

- Name
- Age
- Identity / Occupation
- Problem
- Loan Request
- Related Data
- Evidence
- Memory入口

不能第一次进入就全部显示。

---

## 15. 解锁机制必须使用 Unlock Key

禁止使用：

&gt; 第三句话出现姓名。
&gt;
&gt; 第五句话出现资料。

这种基于对白序号的硬编码。

项目使用 Unlock Key 思路。

历史上使用过类似：

- basic_info
- identity
- problem
- loan_request
- evidence_job
- evidence_rent
- evidence_training
- memory_ready

实际 Key 以**当前项目数据为准**。

---

流程应该保持：

Dialogue

↓

Unlock Key

↓

UnlockSystem

↓

GameState / NPCProgress

↓

UI根据状态显示。

---

## 16. 核心系统不得重复创建

项目已经存在或者已经建立对应职责的核心系统。

包括：

- NPCBase
- DialogueManager
- UnlockSystem
- GameState
- NPCProgress
- Related Data / Evidence
- NoteDetailPopup
- Memory相关公共结构
- Archive
- Save
- Scene导航

禁止创建：

- DialogueManager2
- NewGameState
- BetterNPCSystem
- UnlockSystemNew
- NPCBaseV2

除非用户明确要求重构。

---

## 17. GameState / NPCProgress 核心原则

必须保证：

玩家已经解锁的内容不会因为：

- 切换场景
- 回到主页
- 再次进入 NPC
- 进入 Memory
- Memory返回

而丢失。

---

重要状态概念历史上包括：

- npc_progress
- unlocked_keys
- revealed_note_keys
- current_dialogue_index
- dialogue_completed
- memory_unlocked
- memory_completed
- selected_npc_id
- unlocked_npc_ids

实际字段以**当前代码为准**。

不要为了符合这里的字段名而改当前代码。

---

## 18. 五名 NPC 必须保持独立进度

每一名 NPC：

必须有自己的：

- Dialogue progress
- Unlock Keys
- Notes
- Memory status
- Completion state

禁止出现：

NPC01完成后 NPC02 自动继承 dialogue index。

---

## 19. NPC 内部 ID 和游戏显示名称必须区分

非常重要。

本交接文档中的中文名字只是方便开发者理解人物。

**游戏正式运行时 NPC 已经在使用英文名称。**

不要因为看到：

"张远"

就把游戏里的英文名称改回：

"张远"。

---

TRAE 第一次接手必须读取当前：

`res://data/`

或当前实际 NPC 数据目录。

找出每名 NPC 当前真实：

- npc_id
- display_name
- portrait
- dialogues
- notes
- memory_scene

---

## 20. 不允许猜五名 NPC 的最终英文名字

游戏中使用的英文显示名称：

**以项目当前实际数据为准。**

不要自行：

- 改拼音
- 改姓氏顺序
- 换英文名
- 加减空格
- 调整大小写
- 重新翻译

首次接手：

只需要读取并汇报。

---

## 21. 历史 NPC_A / NPC_B / NPC_C 等仅属于开发占位

项目历史阶段曾经使用：

- NPC_A
- NPC_B
- NPC_C
- NPC_D
- NPC_E

作为骨架。

如果当前正式数据已经换成真实 ID：

不要恢复占位符。

如果仓库里仍存在旧占位数据：

先确认是否仍被引用。

不要自行删除。

---

## 22. NPC01 --- 张远（开发资料名称）

年龄：

22岁。

身份：

应届毕业生。

核心社会问题：

- 青年就业困难
- 学历内卷
- 企业经验要求
- 应届生求职困境

处境：

长期求职效果极差。

收入有限甚至接近于零。

基本生活面临压力。

---

时间贷款方向：

约：

**3年时间贷款**

用于：

高阶职业培训和重新进入就业市场。

---

重要 Evidence / Related Data方向：

- 求职记录
- 房租 / 生活压力材料
- 培训招生资料

---

Memory关键人生节点历史方向：

- 秋招 / 求职现场
- 出租屋

---

NPC01 是项目：

**第一阶段黄金样板。**

新的公共功能必须首先确保 NPC01 完整闭环可以运行。

---

## 23. NPC02 --- 李磊（开发资料名称）

年龄：

24岁。

身份：

互联网基层工作人员。

核心问题：

- 过劳
- 997
- 身体透支
- 工作时间与生命时间交换

---

时间贷款方向：

约：

**2年时间贷款**

主要用于：

保守治疗 / 身体恢复。

---

Related Data / Evidence方向：

- 考勤记录
- 诊断报告
- 工作合同

---

Memory方向：

- 深夜办公室
- 医院检查 / 医疗场景

---

## 24. NPC03 --- 刘桂兰（开发资料名称）

年龄：

52岁。

与 NPC02 李磊存在：

**母子关系。**

核心问题：

- 大病致贫
- 医疗压力
- 养老保障不足
- 家庭经济压力

---

特别规则：

虽然两人存在亲属关系：

**NPCProgress必须完全独立。**

禁止：

- 对话进度共享
- Notes错误共享
- Memory完成状态共享
- 解锁状态串人物

人物关系只能影响：

叙事。

不能破坏进度隔离。

---

## 25. NPC04 --- 苏晴（开发资料名称）

正式：

- 英文 display_name
- 年龄
- 身份
- Problem
- Loan Request
- Dialogue
- Notes
- Evidence
- Memory

必须以：

**当前项目数据 + 副轴当前正式成果**

为准。

不要根据旧聊天自行重写人物故事。

---

## 26. NPC05 --- 王建国（开发资料名称）

同 NPC04。

以当前正式：

- 数据
- Dialogue
- Evidence
- Memory

为准。

不要为了方便复制 NPC01 / NPC02 的故事结构。

五人的：

**系统结构统一**

但：

**人物故事必须独立。**

---

## 27. 每名 NPC 首次接管都必须检查这些内容

针对五人分别建立检查结果。

检查：

### 基础数据

- npc_id
- 当前英文 display_name
- age
- identity
- problem
- loan_request
- portrait

### Dialogue

- 当前对白数量
- 是否全部正式
- 是否存在测试文本
- 是否存在中文玩家可见内容
- Speaker名称是否正确
- Unlock Key是否存在

### Notes / Related Data

每一个检查：

- key
- header / title
- content
- image
- unlock_key
- viewed状态相关逻辑

### Memory

- memory_scene
- 场景文件是否存在
- 是否可以进入
- 是否可以完成
- 是否返回正确
- memory_completed是否正确写入

### 图片

- portrait
- profile photo
- evidence
- note image
- memory asset

检查路径是否存在。

---

## 28. 游戏正式玩家可见语言原则

现在项目已经进入正式英文化阶段。

**玩家最终能够看到的正式游戏内容应为英文。**

包括：

- NPC Name
- Dialogue
- Speaker Name
- Basic Information
- Identity
- Occupation
- Problem
- Loan Request
- Related Data
- Evidence
- Memory
- Archive
- Buttons
- Titles
- UI提示
- 图片里面烘焙的文字

---

## 29. 已经英文化的内容禁止恢复中文

如果当前正式项目已经是：

英文，

即使：

- 旧截图是中文
- 旧 JSON是中文
- 老设计稿是中文
- 交接文档使用中文解释

也不得擅自恢复中文。

---

## 30. 中文只允许存在于开发内容

以下中文一般允许保留：

- 代码注释
- Debug Output
- Smoke Test说明
- 开发备注
- 内部文档
- 不会被玩家看到的说明

是否翻译不影响正式游戏。

---

## 31. 第一次接管必须进行正式中文残留扫描

扫描玩家可能看到的内容。

重点：

- `.tscn`
- `.gd`
- `.json`
- `.tres`
- `.res`

重点目录：

- data
- scenes
- scripts
- UI资源

分类输出：

### A. 玩家可见中文

需要以后处理。

### B. Debug / Test中文

可保留。

### C. 注释

可保留。

---

第一次只检查。

**不要自动把整个项目翻译一遍。**

---

## 32. PNG/JPG里的中文必须单独检查

程序字符串搜索无法找到图片中文字。

因此必须意识到：

玩家看到的中文可能是：

**图片本身的一部分。**

例如：

- 档案图片
- 便利贴图片
- UI按钮图片
- Memory图片
- Archive图片

---

如果文字已经烘焙在图片里：

修改 Godot Label 不会有效。

必须：

替换 / 修改正式图片资源。

---

## 33. 不允许在旧中文图片上随便盖英文 Label

如果用户要求：

&gt; 如果是图片，就生成/替换为英文的一模一样图片。

则目标应该是：

制作真正的英文图片资源。

不能简单：

在中文图片上覆盖一个 Label。

除非用户明确要求这么做。

---

## 34. 中文转英文后必须重新做 UI 排版

英文文字长度通常明显不同。

不能只是：

Chinese String → English String

然后结束。

必须检查：

- Font Size
- Position
- Size
- Autowrap
- Line spacing
- Margin
- Alignment
- Rotation
- Clip
- Ellipsis
- 是否超框
- 是否压住装饰
- 是否视觉居中

最终标准：

**肉眼看上去合理。**

---

## 35. 已经确定的英文术语不要随意改写

第一次接管必须整理：

**当前项目英文术语表。**

例如：

如果项目当前已经统一使用：

`Related Data`

就不要自行改成：

`Relevant Information`

如果已经是：

`Enter Memory`

不要自行改：

`Recall`

或者其他。

保持整个游戏英文统一。

---

## 36. NPCBase 当前已知重要节点

历史及当前场景中已经出现过：

```
NPCBase
├ Background
├ CharacterLayer
│ └ CharacterSlot
│ └ CharacterPortrait
├ DialoguePanel
│ ├ DialogueShade
│ ├ SpeakerName
│ ├ DialogueText
│ └ ContinueButton
├ NamePlate
│ ├ NamePlateTexture
│ └ NPCName
├ DossierPanel
│ ├ DossierShade
│ ├ ProfileBoard
│ │ ├ ProfileBoardTexture
│ │ ├ ProfilePhoto
│ │ └ IdentityLabel
│ ├ RelatedTitle
│ └ RelatedDataArea
│ ├ RelatedSlot01
│ ├ RelatedSlot02
│ ├ RelatedSlot03
│ ├ RelatedSlot04
│ ├ RelatedSlot05
│ └ RelatedSlot06
├ MemoryButton
│ └ MemoryButtonVisual
└ MemoryCameraTexture
```

---

这只是：

**当前已知结构参考。**

第一次必须读取实际 `npc_base.tscn`。

当前项目才是真实标准。

---

## 37. NPCBase 图片大致用途

历史运行结构中：

`Background`

= 整个 NPC 对话场景背景。

`CharacterPortrait`

= 人物立绘 / 人物主体图片。

`DialogueShade`

= 对话区域背景 / 遮罩视觉。

`NamePlateTexture`

= NPC 名牌背景。

`ProfileBoardTexture`

= NPC资料板背景。

`ProfilePhoto`

= NPC资料页中的人物照片。

`MemoryButtonVisual`

= Memory入口视觉。

实际运行必须再次确认。

---

## 38. Runtime UI 与编辑器预览不同

NPCBase 有很多内容：

是在运行时根据数据和状态：

- 动态出现
- 动态实例化
- 动态改变

因此：

Godot 编辑器里看到的 `npc_base.tscn`

可能只有部分背景/UI。

F6运行后才能看到：

完整 NPC 页面。

这是正常现象。

---

不要为了让编辑器"看起来完整"就轻易加入 `@tool`。

除非用户明确要求并且确认安全。

---

## 39. UI修改必须检查 Runtime Override

如果已经修改：

Font Size / Color / Position

但运行游戏没有变化，

必须检查：

- Theme
- Theme Overrides
- LabelSettings
- Runtime Script
- inherited scene
- instantiated scene
- parent style
- 数据驱动赋值

而不是继续重复修改同一个 `.tscn`。

---

## 40. Note 系统是当前已发生过错误的重点区域

项目中已经出现至少：

`res://scenes/npc/note_item.tscn`

以及：

`res://scenes/ui/npc/note_card.tscn`

过去出现过：

AI修改了一个文件，

但实际运行的是另一个。

结果：

报告修改完成，

游戏视觉却没有变化。

---

以后修改 Note：

**禁止根据名字猜。**

必须搜索：

- preload
- load
- PackedScene
- instantiate
- ext_resource
- scene reference

确认 NPCBase 真正实例化的是哪个。

---

## 41. 不要删除另一个 Note Scene

即使发现只有一个在当前 NPCBase 使用：

也不要自行删除另一个。

它可能：

- 被测试使用
- 被旧场景使用
- 被 Memory使用
- 被其他系统引用

只有用户明确要求整理时才处理。

---

## 42. 当前便利贴视觉方向

历史目标包括：

便利贴：

- 与纸张本身角度自然贴合
- 文字不要飘在纸外
- 不要有多余紫色竖条
- Title 与 Content层级明确
- 深色/深棕色文字

---

历史调整目标曾包括：

Title：

- 左移约10px
- 上移约5px
- 17 → 14左右

Content：

- 左移约12px
- 上移约8px
- 14 → 11左右

文字颜色历史目标：

`#5A3030`

NPCName历史目标：

`#1A1A1A`

---

这些数值属于：

**视觉目标历史记录。**

最终必须以：

**当前运行截图肉眼效果**

为准。

不要因为数值已经是14就说：

"任务完成"

如果运行效果仍然不合理。

---

## 43. 多余紫色 AccentStrip

项目过去存在：

便利贴旁边额外紫色竖条。

用户明确要求：

**去除多余紫色竖条。**

如果仍然出现：

必须检查真正运行的 Note Scene。

不要只修改一个同名旧场景。

---

## 44. NoteDetailPopup统一结构

历史已经建立统一：

```
NoteDetailPopup
├ DimBackground
└ DocumentRoot
　 ├ PaperPlaceholder
　 ├ PaperBackground
　 ├ PreviewImage
　 ├ TitleLabel
　 ├ ContentLabel
　 └ CloseHitArea
```

---

五名 NPC：

必须共用同一个 NoteDetailPopup。

不要每个人复制一个。

---

## 45. NoteDetailPopup功能原则

支持：

- 点击 CloseHitArea 关闭
- 点击黑色遮罩关闭
- ESC关闭

数据来自：

当前 Note。

不是写死某一名 NPC。

---

## 46. NoteDetailPopup动画

历史实现方向：

对整个 `DocumentRoot`：

- Alpha 0 → 1
- Scale 0.96 → 1
- 约0.25秒
- TRANS_SINE
- EASE_OUT

关闭反向。

如果当前项目数值已经改变：

保持当前实现。

不要擅自恢复历史数值。

---

## 47. NoteDetailPopup尺寸曾继续调整

历史上曾使用：

1152×648全屏遮罩。

DocumentRoot曾有：

760×380

的横向档案布局。

之后用户要求：

**把框继续变大。**

因此第一次接管：

必须读取当前最新 scene 数值。

不要根据旧聊天强制改回 760×380。

---

## 48. 图片资源定位开发工具已经制作

已有开发调试工具：

`res://scripts/debug/image_locator.gd`

测试场景：

`res://tests/image_locator_test.tscn`

---

用途：

扫描：

- TextureRect
- Sprite2D
- AnimatedSprite2D
- TextureButton

输出：

- 节点名称
- 完整 NodePath
- Texture路径
- 空Texture
- TextureButton各状态纹理

重点位置会标记：

`★★ 可替换图片位置 ★★`

---

用户询问：

&gt; 这个图片到底在哪里？

优先：

使用这个工具或工程引用搜索。

不要让用户漫无目的找节点。

---

## 49. 当前项目基准分辨率

当前运行窗口基准：

**1152 × 648**

16:9。

所有 NPC UI：

首先按照 1152×648 验证。

不要因为：

编辑器窗口缩放比例

而误以为UI尺寸有问题。

---

## 50. 图片资源原则

用户经常要求：

&gt; 其余不要有任何改变。

这句话必须严格执行。

如果只是替换人物：

禁止修改：

- 动作
- 姿势
- 视角
- 透视
- 光影
- 构图
- 背景
- 图像比例

如果只是去掉某个元素：

其他内容保持不变。

---

## 51. PNG透明背景

如果用户明确要求：

透明背景 PNG。

必须是真正 Alpha透明。

不能：

- 黑色背景
- 白色背景
- 假棋盘格

---

## 52. 正方形游戏图标

例如历史齿轮资源：

用户要求：

- 一大一小分开
- 两张独立图片
- 正方形 Canvas
- PNG
- 透明背景
- 可直接放 Godot

类似资源任务应保持该原则。

---

## 53. 不要擅自批量修改图片

如果项目中的图片：

包含中文，

也不要第一次接管就全部重新制作。

先建立：

**玩家可见中文图片清单。**

等用户决定。

---

## 54. 双人开发结构

Pink_Main_Game 有两名程序开发人员。

分为：

**主轴**

与：

**副轴。**

---

## 55. 主轴主要职责

主要负责：

- MainMenu
- NPCBase
- DialogueManager
- UnlockSystem
- GameState
- NPCProgress
- SceneRouter
- 公共UI
- Archive
- Save
- 系统测试
- 五NPC公共框架

---

## 56. 副轴主要职责

副轴主要负责：

- 五名 NPC内容数据
- Dialogue
- Related Data
- Evidence
- Unlock Key内容
- Memory故事
- Memory Scene
- 回忆调查点
- 回忆对白
- 回忆完成逻辑接入
- 内容层测试

---

## 57. 主副轴核心原则

副轴内容必须建立在：

主轴公共框架之上。

不能为了 Memory：

再创建第二套：

- GameState
- DialogueManager
- NPC Progress
- Save
- SceneRouter

---

## 58. TRAE接手时必须同时检查副轴

不能：

只读当前主轴代码

然后直接继续开发。

必须先确定：

**副轴现在实际制作到了什么程度。**

---

## 59. 第一次副轴检查必须检查 Git

只读执行：

- 当前 branch
- git status
- local branches
- remote branches
- branch commit history
- 分支之间差异

不要修改。

---

不要假设：

副轴一定在某个固定分支名称。

必须从 Git实际情况确认。

---

## 60. 不允许接手时自动 Merge

第一次检查禁止：

- merge
- rebase
- cherry-pick
- reset
- force push
- checkout覆盖工作区

---

先报告：

**副轴究竟改了什么。**

---

## 61. 副轴差异必须分类

比较副轴和当前主轴后：

按以下类型分类：

### A

NPC Data

### B

Dialogue

### C

Related Data / Evidence

### D

Memory

### E

公共系统修改

### F

UI修改

### G

Tests

### H

Assets

---

## 62. 副轴公共文件冲突必须重点检查

尤其检查副轴是否修改：

- GameState
- NPCBase
- DialogueManager
- UnlockSystem
- NPCProgress
- SceneRouter
- Save
- Archive

---

如果修改：

不要立即判定为错误。

必须分析：

为什么改。

是否确实是 Memory 接入所需。

---

## 63. 副轴旧 UI 不能覆盖当前主轴最新 UI

这是非常重要的合并原则。

当前主轴已经进行过很多：

- 英文化
- 图片替换
- 字号调整
- Texture调整
- NPCName视觉调整
- Note调整
- NoteDetailPopup修改

---

如果副轴分支中的：

`npc_base.tscn`

比较旧，

不能直接整体覆盖主轴最新文件。

---

应该优先：

**内容级合并**

保留主轴当前最新 UI，

接入副轴：

- Memory
- Dialogue
- NPC Data
- Related Data
- Evidence
- 内容逻辑

---

## 64. Binary图片冲突不要自动解决

PNG/JPG等二进制资源：

不能进行文本式 Merge。

发生冲突：

必须告诉用户是哪两份。

不要自动选某一个覆盖。

---

## 65. Memory系统首次检查

副轴 Memory是重点。

历史目标方向：

五名 NPC 通过公共 Memory体系运行。

玩家进入 Memory 后：

观察 / 调查关键内容。

完成必要内容后：

允许完成 Memory。

然后写入：

NPC对应的 memory_completed。

---

## 66. Memory必须保持观察者玩法

Memory内部不能因为副轴实现：

突然加入：

- 拯救NPC
- 改变历史
- 多结局
- 改过去
- 选择改变人物命运

如发现此类实现：

先报告。

不要自行删除。

---

## 67. Memory需要逐人验证

针对五名 NPC：

分别检查：

- memory_scene是否存在
- 能否进入
- 是否加载正确NPC
- 调查点是否工作
- Dialogue是否工作
- Complete条件
- Back
- 完成返回
- memory_completed
- 重进状态
- 与其他 NPC隔离

---

## 68. 李磊与刘桂兰 Memory必须独立

两人有母子关系。

不能因此：

共享 memory_completed。

不能：

完成李磊回忆 → 刘桂兰回忆自动完成。

---

## 69. Memory返回规则需要读取当前项目确认

历史方向包括：

未完成 Memory：

Back返回原 NPC。

Memory完成：

更新状态并回到正确现实流程。

当前具体：

返回 MainMenu还是 NPCBase，

**必须以当前项目设计为准**。

第一次接管：

只确认，不改。

---

## 70. 副轴必须接受正式英文化检查

特别扫描：

Memory中的：

- Dialogue
- Interaction提示
- Investigation文本
- Buttons
- Titles
- Evidence
- 图片中文字

---

副轴旧内容仍然是中文：

第一次只列出来。

不要自动全部翻译。

---

## 71. 副轴NPC ID一致性

检查副轴是否仍使用：

- NPC_A
- NPC01
- zhang
- 其他旧 ID

而主轴已经使用新的正式 ID。

所有系统：

最终必须依赖同一套稳定 npc_id。

但第一次：

先报告差异。

不要自动大规模替换。

---

## 72. 副轴 Scene Path 检查

检查：

- memory_scene路径
- 返回Scene路径
- resource path
- preload
- load

避免：

文件移动后路径失效。

---

## 73. 副轴 GameState 接入检查

重点确认：

Memory是否正确调用现有状态系统。

不要存在：

Memory自己的第二套 completion dictionary。

除非当前架构确实如此且已有原因。

---

## 74. 副轴 Save兼容性

如果项目已有保存系统：

Memory完成状态必须能够：

保存。

重新启动游戏后：

恢复。

第一次只检查当前实现。

---

## 75. 当前历史主轴实现状态

过去已经报告实现或测试过：

- MainMenu
- START进入NPC
- NPCBase
- DialogueManager拆分
- UnlockSystem
- NPCProgress
- GameState
- Memory测试
- Multi NPC
- Archive相关结构
- 多种 Smoke Test

---

这不是"保证当前全部仍然存在"。

首次接管必须验证。

---

## 76. 历史重要测试

项目过去出现过：

- main_menu_smoke_test
- npc_base_smoke_test
- dialogue_manager_smoke_test
- unlock_system_smoke_test
- multi_npc_data_smoke_test
- multi_npc_ui_smoke_test

以及其他测试。

---

第一次必须实际读取：

`res://tests/`

不要假设文件仍然存在。

---

## 77. 修改后的测试范围必须和风险匹配

简单视觉：

至少：

- 场景解析
- 运行目标场景
- 肉眼确认

NPCBase UI：

优先：

- NPC Base测试
- Multi NPC UI测试

Dialogue：

- Dialogue相关
- NPCBase

Unlock：

- UnlockSystem
- NPCBase
- Multi NPC Data

Memory：

- Memory相关
- GameState
- NPC状态恢复

核心状态：

扩大到完整相关 Smoke Test。

---

## 78. 不允许只看 Smoke Test 不看实际游戏效果

Smoke Test PASS：

只能说明：

程序层没有发现某些错误。

不能证明：

- 文字位置正确
- 图片没有中文
- UI没超框
- 图片没变形
- 便利贴视觉合理

UI任务必须：

实际运行确认。

---

## 79. 用户运行截图优先级很高

如果用户截图显示：

文字没有改变，

而你的 diff显示：

font_size已经改了，

应该相信：

**运行截图暴露了真实问题。**

继续查：

为什么属性没有生效。

---

## 80. 修改完成的定义

任务只有同时满足：

1.  文件修改正确
2.  项目可以解析
3.  没有新增严重错误
4.  运行效果实际改变
5.  没有破坏其他NPC
6.  没有修改无关逻辑
7.  相关测试通过

才能说：

**完成。**

---

## 81. Git安全规则

中风险及以上修改前：

先查看：

`git status`

确认：

用户是否有未提交修改。

---

绝对禁止未经允许：

- git reset
- git clean
- 强制 checkout覆盖
- rebase
- force push
- 删除用户未跟踪资产
- 自动恢复其他人的修改

---

## 82. 不要擅自 Commit / Push

除非用户明确要求：

不要自行：

- commit
- push
- merge
- delete branch

---

可以：

- git status
- git diff
- read-only log
- 告诉用户建议提交

---

## 83. 多人协作时减少 Merge Conflict

修改时：

只改当前任务需要的文件。

禁止：

- 全工程格式化
- 大范围排序
- 无关命名调整
- 自动整理整个 `.tscn`
- 为了好看重排文件

---

## 84. `.tscn` 特别安全规则

Godot `.tscn` 非普通随意文本。

禁止：

- 无理由整文件重写
- 批量更改 resource ID
- 重新排序大量节点
- 重命名节点
- 断开 Signal
- 调整无关 Anchor / Offset

---

很多 GDScript可能通过：

- `$Node`
- `%Node`
- NodePath
- get_node()

访问节点。

所以：

节点名属于程序接口的一部分。

---

## 85. 不要修改 `.godot/`

除非极特殊情况且用户明确同意。

不要手动处理：

- Import cache
- generated metadata
- editor cache

资源替换后：

让 Godot自己重新导入。

---

## 86. 不要随意修改已有资源目录名称

项目可能包含：

历史命名错误、中文目录、旧路径。

例如过去出现过类似：

`Levevl2`

即使看起来拼写错误：

不要直接改成：

`Level2`

因为大量场景可能仍然引用旧路径。

---

## 87. 文件移动属于高风险操作

任何：

- rename
- move
- delete

Godot场景、Script、Texture资源：

都必须先搜索引用。

用户只要求换图：

不要顺便整理文件夹。

---

## 88. 额度 / 积分优化原则

用户希望：

**高效、完善、不浪费额度。**

所以：

不要每一次都全项目扫描。

正确做法：

先搜索相关引用。

只读取任务有关的：

- scene
- script
- data
- test

---

同一会话已经确认的架构：

应复用上下文。

不要重复扫描相同内容。

---

## 89. 但额度优化不能牺牲正确性

如果出现：

- 不确定运行时引用
- 多文件问题
- 核心Bug
- 主副轴冲突

就应该：

扩大检查。

不要为了省几个积分直接猜。

---

## 90. 明确的UI小任务不要扩大范围

例如用户说：

&gt; NPC名字从黄色改黑色。

如果已经确认节点：

`NPCName`

就只改：

这个视觉属性。

不要：

重新扫描 DialogueManager、Memory、Save。

---

## 91. 视觉任务禁止借机重构逻辑

用户只要求：

- Texture
- Font
- Color
- Position
- Rotation
- Size

则禁止修改：

- GameState
- UnlockSystem
- DialogueManager
- NPCData Schema

除非确实存在直接依赖问题。

如果必须修改：

先告诉用户原因。

---

## 92. 数据任务禁止借机修改视觉

同理。

修改 NPC JSON：

不要顺便重新设计 UI。

---

## 93. 测试字符串不代表正式剧情

项目中可能有：

`这里是测试对话05`

之类内容。

这属于：

测试 / 占位。

不能把它当正式 NPC故事。

首次接管必须找出并分类。

---

## 94. 当前完整英文对白是后续重点

所有五名人物：

最终正式 Dialogue：

需要从中文正式翻译为英文。

要求：

- 自然
- 保留人物性格
- 保留社会语境
- 不机械逐字翻译
- 不改变剧情事实
- 不缩成失去叙事性的短句

同时：

排版必须适合 Dialogue Box。

---

## 95. NPC资料英文也属于正式内容

包括：

- identity
- issue
- occupation
- loan
- related data
- evidence description

必须统一英文风格。

不要出现：

一个页面 Formal English，

另一个页面机器直译。

---

## 96. 人物故事不能被 AI 擅自改写

除非用户明确要求：

不要因为英文翻译：

改变：

- 人物身份
- 社会问题
- 年龄
- 人物关系
- 贷款年限
- Memory事实
- 故事结局

---

## 97. 五人故事不要变成同一个模板

系统结构可以统一。

但：

人物叙事必须保持：

独立性。

不要每个人都变成：

"遇到困难 → 申请贷款 → 回忆 → 结束"

的机械同句式。

---

## 98. 张远作为黄金样板

任何：

NPC公共系统修改，

优先验证：

NPC01完整流程：

MainMenu

→ NPC

→ Dialogue

→ Unlock

→ Related Data

→ Memory

→ Return

→ State保持。

---

## 99. 五 NPC最终整体验收

最终必须确认：

每名：

- 可以进入
- 正确英文Name
- 正确Portrait
- Dialogue正确
- 信息逐步解锁
- Related Data正确
- Evidence正常
- Memory按钮正确解锁
- Memory能进入
- Memory能完成
- 返回状态正确
- 不串NPC状态

---

## 100. 首次 TRAE 接管必须使用 Seed-2.1-Pro

第一次接收本交接文档后：

**推荐模型：Seed-2.1-Pro**

**任务强度：极高**

第一次：

只读。

禁止修改任何项目文件。

---

## 101. 第一次接管 --- Step 1：环境确认

检查：

- 项目路径
- 当前 Git branch
- git status
- Git remote
- local branches
- remote branches
- project.godot
- Godot版本

只报告。

---

## 102. Step 2：核心系统读取

读取与分析：

- MainMenu
- NPCBase
- NPCBase相关Script
- DialogueManager
- UnlockSystem
- GameState
- NPCProgress
- SceneRouter
- Archive
- Save
- Note
- NoteDetailPopup
- Memory公共系统
- Tests

---

不要扫描所有大型图片内容。

先分析程序架构。

---

## 103. Step 3：确认真实运行引用

必须明确回答：

1.  MainMenu START实际进入哪个 Scene？
2.  NPCBase从哪里读取当前 NPC？
3.  CharacterPortrait由哪里设置？
4.  ProfilePhoto由哪里设置？
5.  Dialogue由哪里读取？
6.  Related Data怎样生成？
7.  实际使用 note_item还是 note_card？
8.  Unlock Key如何触发？
9.  MemoryButton什么时候出现？
10. Memory场景路径从哪里读取？
11. Memory完成后如何返回？
12. NPC状态在哪里保存？

---

## 104. Step 4：五名 NPC正式数据盘点

读取实际数据。

对五人分别报告：

- npc_id
- 当前正式英文 display_name
- age
- identity
- Dialogue数量
- Related Data数量
- Unlock Keys
- portrait
- memory_scene

---

不修改。

---

## 105. Step 5：英文正式版盘点

整理：

**当前项目实际英文术语表。**

然后扫描：

正式玩家可见中文。

输出：

- 字符串位置
- Scene
- Script
- JSON

同时列出：

需要人工查看的图片 Texture路径。

---

不修改。

---

## 106. Step 6：副轴接管检查

寻找：

副轴相关：

- Branch
- Commit
- Memory Scene
- Data
- Dialogue
- Evidence
- Tests

---

如果无法确定哪个分支属于副轴：

告诉用户。

不要猜。

---

## 107. Step 7：主副轴差异检查

至少检查：

- NPCBase
- GameState
- DialogueManager
- UnlockSystem
- NPCProgress
- NPC Data
- Note
- Memory
- Tests

---

生成：

### 可以安全接入

和：

### 存在冲突，暂时不要合并

两个类别。

---

## 108. Step 8：测试盘点

读取：

`res://tests/`

告诉用户：

实际有哪些测试。

不要仅根据交接文档列旧测试名。

---

## 109. Step 9：首次接管风险检查

寻找：

- Missing Resource
- Broken NodePath
- Duplicate system
- 旧NPC占位
- Test dialogue
- Chinese player-facing content
- Invalid image path
- Missing Memory Scene
- Main/sub branch冲突
- 数据Schema不一致

---

只报告。

---

## 110. 第一次接管结束后必须回复的内容

按以下格式：

### 推荐模型

Seed-2.1-Pro

### 任务强度

极高

### 项目读取状态

完成 / 存在问题

### Git状态

Branch：

Working Tree：

Remote：

### Godot

Version：

Project Path：

### 核心架构

简短说明当前真实实现。

### 五名 NPC

分别列：

- Internal ID
- English Display Name
- Data
- Dialogue
- Related Data
- Memory
- English状态

### 实际 Note Scene

明确说明：

运行时真正使用哪个。

### 当前正式英文术语

列关键术语。

### 玩家可见中文残留

列出。

### 副轴制作状态

逐项说明。

### 主副轴冲突

说明有无。

### 当前测试

列出实际测试。

### 风险

只列真实发现的问题。

### 文件修改

**本次为只读接管检查，没有修改任何项目文件。**

然后停止。

等待用户下一步要求。

---

## 111. 第一次接管禁止进行的事情

禁止：

- 修Bug
- 翻译
- 换图
- 重构
- 改JSON
- 合并副轴
- 整理目录
- 创建新系统
- Commit
- Push
- 自动建文档
- 自动删除旧文件

第一次只允许：

**读取、理解、核实、报告。**

---

## 112. 后续每一个任务的标准工作流程

每次收到制作任务：

### Step A

判断风险。

### Step B

告诉用户：

推荐模型 + 任务强度。

### Step C

搜索相关实际引用。

### Step D

只读取必要文件。

### Step E

修改最小范围。

### Step F

检查 diff。

### Step G

运行适合的测试。

### Step H

运行/验证实际目标 Scene。

### Step I

向用户简短报告。

---

## 113. 完成报告固定格式

每次完成后使用：

### 推荐模型

XXX

### 任务强度

XX

### 已完成

一句话说明结果。

### 修改文件

只列真正改过的文件。

### 修改内容

只列关键节点 / 函数。

### 测试

PASS / FAIL。

### 是否影响业务逻辑

明确：

`否，仅视觉修改`

或：

`是，修改了XXX`

### 还需要用户确认

只有确实需要肉眼判断时才写。

---

## 114. 不要假装完成

如果：

代码修改了，

但是无法运行 Godot验证，

必须明确说：

&gt; 文件修改已完成，但本次没有完成运行验证。

不能写：

`测试通过`

除非真的运行。

---

## 115. 不要伪造测试结果

禁止：

没有运行却说：

`NPC_BASE_SMOKE_TEST: PASS`

没有打开 Scene却说：

"运行正常"。

所有测试结果必须来自实际执行。

---

## 116. 不要伪造文件或资源

如果图片并不存在：

不要假装已经生成：

`xxx_en.png`

如果不能创建：

告诉用户需要提供/生成对应图片。

---

## 117. 如果发现旧 AI报告与项目不一致

项目曾经由 Codex 等 AI多次修改。

过去 AI可能说：

"已完成。"

但实际：

游戏画面没有改变。

因此：

**不能把旧 AI报告当事实。**

当前仓库 + 实际运行：

才是事实。

---

## 118. 用户截图是一种验收证据

如果截图与AI报告冲突：

以截图表现为重要线索。

例如：

AI说：

AccentStrip已隐藏。

截图：

仍然有紫色竖条。

说明：

任务没有真正完成。

应该继续查实际运行 Scene。

---

## 119. 不要责怪用户操作

用户如果说：

"为什么没变化？"

优先检查：

- 修改错 Scene
- Runtime Override
- Instance Override
- Theme
- Asset内文字
- 数据绑定
- Cache / Import
- 实际运行资源

不要先假设用户操作错误。

---

## 120. 当前最重要的总体开发目标

TRAE 接管 Pink_Main_Game 后：

不是追求把代码改得最先进。

真正目标：

1.  五名NPC都能稳定运行。
2.  五名NPC内容独立。
3.  所有状态正确保持。
4.  Memory完整可进入和返回。
5.  主副轴成果正确整合。
6.  正式玩家内容统一英文。
7.  UI肉眼合理。
8.  图片和文字正确对应。
9.  不产生明显中文残留。
10. 不因为AI重构破坏已有游戏。
11. 最终形成一个可以稳定演示和游玩的完整版本。

---

## 121. 最后一条最高优先级规则

当你不确定：

**先查项目。**

查完仍然不确定：

**告诉用户。**

绝对不要：

为了快速给答案而猜。

Pink_Main_Game 已经进入实际制作和整合阶段。

任何一次错误的大范围自动修改，都可能浪费比询问一次更多的时间。

---

## TRAE 第一次收到本文档后的立即任务

**推荐模型：Seed-2.1-Pro**

**任务强度：极高**

现在对：

`D:\Pink_Main_Game`

执行：

**完整只读项目接管检查。**

严格执行本文档第 100～110 条。

尤其确认：

1.  当前 Git真实状态。
2.  当前 Godot版本。
3.  当前真实核心架构。
4.  五名 NPC实际 internal ID。
5.  五名 NPC当前正式英文 display_name。
6.  五名 NPC数据、Dialogue、Related Data和Memory完成度。
7.  当前玩家可见中文残留。
8.  当前实际使用的 Note Scene。
9.  当前图片资源数据来源。
10. 当前 Memory实现。
11. 副轴当前分支和成果。
12. 主副轴是否有冲突。
13. 当前真实测试。
14. 当前主要风险。

**不要修改任何文件。**

检查完成后按照本文档第110条回复，然后等待下一条指令。
