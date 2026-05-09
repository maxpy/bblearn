# BiblePlayer 双语圣经音频阅读器 - 实现计划

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** 一个 Flutter 全平台 App，支持英中双语圣经音频逐节交替播放，用户可自定义播放序列。

**Architecture:** Flutter + Riverpod 状态管理 + just_audio 音频引擎 + Hive 本地存储。数据层读取已有的 .mp3 / .subtitle.json / .txt.json 文件。播放引擎核心是一个 PlayQueue，根据用户定义的播放序列（PlaySequence）和经节时间戳，生成精确的 seek+play 指令队列。

**Tech Stack:** Flutter 3.x, Dart, Riverpod, just_audio, Hive, go_router

---

## Phase 0: 环境搭建

### Task 0.1: 安装 Flutter SDK
- 安装 Flutter (stable channel)
- 验证: `flutter doctor`

### Task 0.2: 创建 Flutter 项目
- `flutter create --org com.bibleaudio --project-name bible_player bible_player`
- 配置 pubspec.yaml 依赖
- 验证: `flutter run -d chrome`

**pubspec.yaml 核心依赖:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  just_audio: ^0.9.36
  hive_flutter: ^1.1.0
  go_router: ^14.0.0
  google_fonts: ^6.1.0
  path_provider: ^2.1.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  hive_generator: ^2.0.0
  flutter_lints: ^4.0.0
```

---

## Phase 1: 数据层

### Task 1.1: 数据模型定义

**Files:**
- Create: `lib/models/bible_book.dart`
- Create: `lib/models/verse.dart`
- Create: `lib/models/play_sequence.dart`
- Create: `lib/models/bookmark.dart`

**bible_book.dart:**
```dart
enum Testament { OT, NT }

class BibleBook {
  final int number;       // 1-66
  final String nameEn;
  final String nameZh;
  final int chapters;
  final Testament testament;
}
```

**verse.dart:**
```dart
class VerseText {
  final int verse;
  final String text;
}

class VerseTiming {
  final int verse;
  final double start;  // seconds
  final double end;    // seconds
  final String text;
}

class ChapterData {
  final String version;   // "KJV" or "CUV"
  final int bookNumber;
  final int chapter;
  final List<VerseTiming> verses;
  final String audioPath;
}
```

**play_sequence.dart:**
```dart
class PlayStep {
  final String version;  // "KJV", "CUV", etc.
  final double speed;    // 0.5 - 2.0
}

class PlaySequence {
  final String name;
  final List<PlayStep> steps;
  final double gapBetweenSteps;   // seconds, 同节不同语言间
  final double gapBetweenVerses;  // seconds, 进入下一节前
}

// 预设序列
const presetSequences = [
  PlaySequence(name: "EN", steps: [PlayStep("KJV", 1.0)], ...),
  PlaySequence(name: "CN", steps: [PlayStep("CUV", 1.0)], ...),
  PlaySequence(name: "EN→CN", steps: [PlayStep("KJV", 1.0), PlayStep("CUV", 1.0)], ...),
  PlaySequence(name: "CN→EN", steps: [PlayStep("CUV", 1.0), PlayStep("KJV", 1.0)], ...),
  PlaySequence(name: "EN→CN→EN", steps: [PlayStep("KJV", 1.0), PlayStep("CUV", 0.8), PlayStep("KJV", 1.2)], ...),
  PlaySequence(name: "CN→EN→CN", steps: [PlayStep("CUV", 1.0), PlayStep("KJV", 1.0), PlayStep("CUV", 0.8)], ...),
];
```

### Task 1.2: 数据加载服务

**Files:**
- Create: `lib/services/bible_data_service.dart`

从本地文件系统 (assets 或 documents 目录) 加载:
- metadata.json → 书卷列表
- {version}/{testament}/{book}/{book}_{chapter}.subtitle.json → 经节时间戳
- {version}/{testament}/{book}/{book}_{chapter}.txt.json → 经文文本

### Task 1.3: 将圣经数据打包为 Flutter assets

**策略:** 
- 文本数据 (.txt.json, .subtitle.json, metadata.json) 打包进 assets (约 50MB)
- 音频文件 (.mp3) 太大 (3.2GB)，首次启动时从 assets 复制到 documents 目录
  或者提供按书卷下载功能

**简化方案 (v1):** 先把所有数据放 assets，Web 端直接加载，移动端首次复制到本地。

---

## Phase 2: 音频播放引擎

### Task 2.1: PlayQueue 播放队列生成器

**Files:**
- Create: `lib/services/play_queue.dart`

**核心逻辑:**
```dart
class PlayQueueItem {
  final String audioPath;
  final double startTime;   // seek position
  final double endTime;     // stop position
  final double speed;
  final String version;
  final int verse;
  final bool isPause;       // gap item
  final double pauseDuration;
}

class PlayQueue {
  List<PlayQueueItem> items = [];
  int currentIndex = 0;

  /// 根据 PlaySequence + 两个版本的 ChapterData 生成队列
  static PlayQueue build({
    required Map<String, ChapterData> chapterDataByVersion,
    required PlaySequence sequence,
    int? startVerse,
    int? endVerse,
  });
}
```

### Task 2.2: AudioPlayerService 音频播放服务

**Files:**
- Create: `lib/services/audio_player_service.dart`

基于 just_audio，实现:
- 加载音频文件
- seek 到指定位置
- 播放到指定结束位置后自动停止
- 切换到队列中下一项
- 播放/暂停/上一节/下一节
- 速度控制
- 播放状态流 (当前经节、当前版本、进度)

**关键实现:**
```dart
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  PlayQueue? _queue;
  Timer? _endTimer;

  Stream<PlaybackState> get stateStream;

  Future<void> playItem(PlayQueueItem item) async {
    if (item.isPause) {
      await Future.delayed(Duration(milliseconds: (item.pauseDuration * 1000).round()));
      _playNext();
      return;
    }
    await _player.setFilePath(item.audioPath);
    await _player.seek(Duration(milliseconds: (item.startTime * 1000).round()));
    await _player.setSpeed(item.speed);
    _player.play();
    // 监听位置，到达 endTime 时停止并播放下一项
    _positionSubscription = _player.positionStream.listen((pos) {
      if (pos.inMilliseconds >= item.endTime * 1000) {
        _player.pause();
        _playNext();
      }
    });
  }
}
```

### Task 2.3: PlaybackState 状态管理

**Files:**
- Create: `lib/providers/playback_provider.dart`

Riverpod provider，暴露:
- 当前播放书卷/章/节
- 当前播放版本 (KJV/CUV)
- 当前播放序列中的步骤 (第几轮)
- 播放/暂停状态
- 当前经节在章中的进度
- 当前播放序列配置

---

## Phase 3: UI 页面

### Task 3.1: App 骨架 + 路由

**Files:**
- Create: `lib/app.dart`
- Create: `lib/router.dart`
- Modify: `lib/main.dart`

路由:
- `/` → 首页 (书卷列表)
- `/book/:bookId` → 章节选择
- `/play/:bookId/:chapter` → 播放页
- `/settings` → 设置页
- `/bookmarks` → 书签页
- `/sequence-editor` → 播放序列编排页

主题: Material 3, 支持深色模式, 使用 Noto Serif 字体

### Task 3.2: 首页 - 书卷列表

**Files:**
- Create: `lib/pages/home_page.dart`
- Create: `lib/widgets/book_list_tile.dart`
- Create: `lib/widgets/continue_playing_card.dart`

布局:
- 顶部: 继续播放卡片 (上次位置)
- 旧约/新约 可折叠分组
- 每行: 书号 + 英文名 + 中文名
- 底部: 书签 / 历史 / 设置 导航

### Task 3.3: 章节选择页

**Files:**
- Create: `lib/pages/chapter_select_page.dart`

布局:
- 标题: 书名 (中英)
- 网格: 章节号按钮
- 点击进入播放页

### Task 3.4: 播放页 (核心)

**Files:**
- Create: `lib/pages/player_page.dart`
- Create: `lib/widgets/verse_display.dart`
- Create: `lib/widgets/player_controls.dart`
- Create: `lib/widgets/sequence_selector.dart`

布局 (从上到下):
1. 顶栏: 书名 + 章节 + 进度
2. 经文显示区 (可滚动):
   - 双栏: 左 KJV 右 CUV (宽屏) 或 上下排列 (窄屏)
   - 当前经节高亮
   - 当前播放的语言侧加重高亮
   - 点击经节跳转
3. 进度条: 经节级 (v.3/31)
4. 控制栏:
   - 循环模式 / 上一节 / 播放暂停 / 下一节 / 序列选择
5. 音量/速度条

### Task 3.5: 播放序列编排页

**Files:**
- Create: `lib/pages/sequence_editor_page.dart`
- Create: `lib/widgets/sequence_step_tile.dart`

布局:
- 可拖拽排序的步骤列表
- 每步: 版本选择 + 语速滑块 + 删除按钮
- 添加步骤按钮
- 节间停顿 / 轮间停顿 设置
- 预览文字
- 保存为预设 / 应用

### Task 3.6: 设置页

**Files:**
- Create: `lib/pages/settings_page.dart`

设置项:
- 默认播放序列
- 字体大小
- 深色模式
- 章间自动续播
- 睡眠定时
- 存储管理

### Task 3.7: 书签页

**Files:**
- Create: `lib/pages/bookmarks_page.dart`

功能:
- 书签列表 (书卷+章+节+时间)
- 点击跳转播放
- 滑动删除

---

## Phase 4: 持久化

### Task 4.1: Hive 本地存储

**Files:**
- Create: `lib/services/storage_service.dart`

存储:
- 播放进度 (上次播放位置)
- 书签列表
- 自定义播放序列
- 设置偏好
- 播放历史

---

## Phase 5: 平台适配

### Task 5.1: Web 端适配
- 音频文件通过 HTTP 加载 (assets 目录)
- 响应式布局 (宽屏双栏，窄屏单栏)

### Task 5.2: iOS 适配
- 后台音频播放 (audio_session)
- 锁屏控制 (MediaSession)
- Info.plist 配置

### Task 5.3: Android 适配
- 后台音频播放
- 通知栏控制
- AndroidManifest 配置

---

## Phase 6: 优化

### Task 6.1: 音频预加载
- 播放当前经节时预加载下一个音频片段
- 减少语言切换时的延迟

### Task 6.2: 按书卷下载管理
- 不打包全部音频到 assets
- 提供按书卷下载/删除功能
- 显示下载进度和存储占用

### Task 6.3: 搜索功能
- 按经文内容搜索
- 支持中英文

---

## 文件结构总览

```
bible_player/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── router.dart
│   ├── models/
│   │   ├── bible_book.dart
│   │   ├── verse.dart
│   │   ├── play_sequence.dart
│   │   └── bookmark.dart
│   ├── services/
│   │   ├── bible_data_service.dart
│   │   ├── audio_player_service.dart
│   │   ├── play_queue.dart
│   │   └── storage_service.dart
│   ├── providers/
│   │   ├── bible_data_provider.dart
│   │   ├── playback_provider.dart
│   │   └── settings_provider.dart
│   ├── pages/
│   │   ├── home_page.dart
│   │   ├── chapter_select_page.dart
│   │   ├── player_page.dart
│   │   ├── sequence_editor_page.dart
│   │   ├── settings_page.dart
│   │   └── bookmarks_page.dart
│   ├── widgets/
│   │   ├── book_list_tile.dart
│   │   ├── continue_playing_card.dart
│   │   ├── verse_display.dart
│   │   ├── player_controls.dart
│   │   ├── sequence_selector.dart
│   │   └── sequence_step_tile.dart
│   └── utils/
│       ├── constants.dart
│       └── bible_data.dart       // 66 books static data
├── assets/
│   ├── data/
│   │   └── metadata.json
│   ├── text/                     // .txt.json files
│   │   ├── KJV/
│   │   └── CUV/
│   └── audio/                    // .mp3 + .subtitle.json
│       ├── KJV/
│       └── CUV/
├── pubspec.yaml
└── README.md
```

---

## 实现顺序

1. Phase 0 → 环境 + 项目创建
2. Phase 1 → 数据模型 + 加载
3. Phase 2 → 播放引擎 (核心)
4. Phase 3.1-3.2 → App 骨架 + 首页
5. Phase 3.3 → 章节选择
6. Phase 3.4 → 播放页 (核心 UI)
7. Phase 4 → 持久化
8. Phase 3.5-3.7 → 编排页 + 设置 + 书签
9. Phase 5 → 平台适配
10. Phase 6 → 优化

---

## 问题追踪 (Issue Tracker)

### 🔴 EN-CN 序列只播放 KJV 不播放 CUV
**发现日期:** 2025-05-07  
**状态:** 未解决

**现象:** 选择 EN-CN 播放序列后，只播放 KJV，从不切换到 CUV。

**分析过程:**
1. 确认 `PlaySequence` 定义正确: `steps: [KJV, CUV]`
2. 确认 SRT 和 MP3 音频文件都能正常访问:
   - `https://audio.bblearn.uk/srt/KJV/mark/6.srt` → 200
   - `https://audio.bblearn.uk/srt/CUV/mark/6.srt` → 200
   - `https://audio.bblearn.uk/audio/KJV/genesis/1.mp3` → 200
3. Flutter dev server 持续崩溃 ("Dart compiler exited unexpectedly")，无法进行运行时调试
4. 静态 HTTP server (`build/web/`) 无法运行 Flutter web — 需要 Flutter 引擎 bootstrap

**可能原因:**
- `PlayQueue.build()` 构建队列时可能没有正确添加 CUV 项目
- `AudioPlayerService._onItemCompleted()` 完成后没有正确切换到下一队列项
- KJV 和 CUV 的 `verseCount` 不同可能导致队列长度计算问题

**待验证:** 需要 Flutter dev server 正常运行后添加 debug print 语句验证队列内容

---

### 🟡 JSON 文件返回 404，服务器只有 SRT 文件
**发现日期:** 2025-05-07  
**状态:** ✅ 已修复

**现象:** `https://audio.bblearn.uk/srt/KJV/genesis/1.json` 返回 404

**修复:** 在 `subtitle_service.dart` 中添加 SRT fallback，当 JSON 返回 404 时尝试加载 SRT 文件

---

### 🟡 中文字符显示乱码
**发现日期:** 2025-05-07  
**状态:** ✅ 已修复

**现象:** CUV 中文经文显示为乱码

**修复:** 在 `subtitle_service.dart` 中使用 `utf8.decode(response.bodyBytes)` 显式 UTF-8 解码

---

### 🟡 KJV 和 CUV 音频时长不同导致字幕不同步
**发现日期:** 2025-05-07  
**状态:** ✅ 已修复

**现象:** 基于位置的同步在高亮显示时出现偏差，因为同一经节 KJV 和 CUV 的音频时长不同

**修复:** 改为基于 verse 的同步方式，使用 `ChapterData.verseAtTime()` 计算当前经节

---

### 🟡 currentVerse 只在新项目开始时更新
**发现日期:** 2025-05-07  
**状态:** ✅ 已修复

**现象:** 字幕高亮在播放过程中不随位置更新

**修复:** 在 `AudioPlayerService._onPositionChanged` 中调用 `verseAtTime()` 实时计算 `currentVerse`

---

### 🟡 Flutter build web 警告: cupertino_icons 字体缺失
**发现日期:** 2025-05-07  
**状态:** 已知警告，不影响功能

**警告信息:**
```
Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons)
```

---

## 环境问题

### 🔴 Flutter dev server 崩溃
**状态:** 未解决

**现象:** `flutter run -d chrome` 运行一段时间后崩溃
```
Dart compiler exited unexpectedly
Debugger: Target crashed!
```

**影响:** 无法进行交互式调试，难以诊断运行时问题

**临时方案:** 使用静态 HTTP server (`python3 -m http.server 9000 --directory build/web`) 验证构建结果
