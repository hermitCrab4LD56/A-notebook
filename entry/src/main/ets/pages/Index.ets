import { hilog } from '@kit.PerformanceAnalysisKit';
// 移除KeyType导入，因为它不存在

const DOMAIN = 0x0000;

// 音轨数据接口
interface AudioTrack {
  id: string; // 音轨唯一标识
  waveformData: number[]; // 波形数据
  duration: number; // 录音时长（秒）
  isPlaying: boolean; // 是否正在播放
  position: number; // 在文档中的位置
  finalWaveform: number[]; // 最终固定的波形数据
}

// 音频分组接口
interface AudioGroup {
  name: string;
  tracks: string[];
  fileItems: string[];
}

// 分组项接口
interface GroupItem {
  groupId: string;
  groupData: AudioGroup;
}

@Entry
@Component
struct Index {
  @State selectedTrack: number = 2; // 当前选中的轨道
  @State playingTrack: number = -1; // 当前播放的轨道
  @State waveformData: number[] = []; // 波形数据
  
  // 文档编辑相关状态
  @State documentContent: string = ''; // 文档内容
  @State isRecording: boolean = false; // 是否正在录音
  @State recordingDuration: number = 0; // 录音时长（秒）
  @State currentRecordingTrack: AudioTrack | null = null; // 当前录音的音轨
  @State audioTracks: AudioTrack[] = []; // 所有音轨数据
  @State realtimeWaveform: number[] = []; // 实时波形数据
  @State recordingTimer: number = -1; // 录音计时器ID
  @State waveformAnimationTimer: number = -1; // 波形动画计时器ID
  @State animationSeed: number = 0; // 动画种子，用于随机波形变化
  
  // 录音按钮交互状态
  @State recordButtonHovered: boolean = false; // 录音按钮悬停状态
  @State recordButtonPressed: boolean = false; // 录音按钮按下状态
  
  // 搜索相关状态
  @State isSearchActive: boolean = false; // 搜索是否激活
  @State searchText: string = ''; // 搜索文本
  @State searchHovered: boolean = false; // 搜索图标悬停状态
  @State searchPressed: boolean = false; // 搜索图标按下状态
  
  // 最大化相关状态
  @State isMaximized: boolean = false; // 侧边栏是否最大化
  
  // 菜单相关状态
  @State menuHovered: boolean = false; // 菜单图标悬停状态
  @State menuPressed: boolean = false; // 菜单图标按下状态
  
  // 搜索结果
  @State searchResults: string[] = []; // 搜索结果列表
  
  // 选择模式相关状态
  @State isSelectionMode: boolean = false; // 是否处于选择模式
  @State selectedTracks: Set<string> = new Set(); // 选中的音轨ID集合
  @State pinnedTracks: string[] = []; // 置顶的音轨ID数组
  @State audioGroups: Map<string, AudioGroup> = new Map(); // 音频分组
  @State showGroupOptions: boolean = false; // 是否显示分组选项
  @State showNewGroupDialog: boolean = false; // 是否显示新建分组对话框
  @State newGroupName: string = ''; // 新分组名称
  
  // 拖拽相关状态
  @State isDragging: boolean = false;
  @State dragStartIndex: number = -1;
  @State dragCurrentIndex: number = -1;
  
  // 所有可搜索的文本内容
  private allSearchableTexts: string[] = [
    'default',
    'Mockup Date 1',
    'Mockup Date 2', 
    'Mockup Date 3',
    'new group'
  ];

  build() {
    Row() {
      // 侧边栏
      this.Sidebar()

      // 主内容区 - 根据最大化状态决定是否显示
      if (!this.isMaximized) {
        this.MainContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1F2937')
  }

  @Builder
  Sidebar() {
    Column() {
      // 侧边栏头部
      this.SidebarHeader()

      // 文件/笔记本部分
      this.NotebookSection()
    }
    .width(this.isMaximized ? '100%' : 200)
    .height('100%')
    .backgroundColor('#374151')
    .border({ width: { right: this.isMaximized ? 0 : 1 }, color: '#4B5563' })
  }

  @Builder
  SidebarHeader() {
    Row() {
      // 菜单图标容器
      Row() {
        Text('≡')
          .fontSize(18)
          .fontColor('#9CA3AF')
      }
      .width(32)
      .height(32)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.menuHovered || this.menuPressed ? '#4B5563' : Color.Transparent)
      .borderRadius(4)
      .onHover((isHover: boolean) => {
        this.menuHovered = isHover;
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.menuPressed = true;
        } else if (event.type === TouchType.Up) {
          this.menuPressed = false;
          this.toggleMaximize();
        }
      })

      // 搜索框 - 仅在搜索激活时显示
      if (this.isSearchActive) {
        TextInput({ placeholder: '搜索...', text: this.searchText })
          .width(80)
          .height(32)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#4B5563')
          .borderRadius(4)
          .padding({ left: 8, right: 8 })
          .placeholderColor('#9CA3AF')
          .onChange((value: string) => {
            this.searchText = value;
            this.performSearch(value);
          })
          .margin({ left: 4, right: 4 })
      } else {
        Blank()
      }

      // 搜索图标
      Row() {
        Image($r('app.media.search_icon'))
          .width(18)
          .height(17)
          .fillColor('#9CA3AF')
      }
      .width(32)
      .height(32)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.searchHovered || this.searchPressed ? '#4B5563' : Color.Transparent)
      .borderRadius(4)
      .onHover((isHover: boolean) => {
        this.searchHovered = isHover;
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.searchPressed = true;
        } else if (event.type === TouchType.Up) {
          this.searchPressed = false;
          this.toggleSearch();
        }
      })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#374151')
  }

  @Builder
  NotebookSection() {
    Column({ space: 16 }) {
      if (this.isSearchActive) {
        // 搜索模式 - 显示搜索结果
        if (this.searchResults.length > 0) {
          ForEach(this.searchResults, (result: string) => {
            this.SearchResultItem(result)
          })
        } else if (this.searchText.length > 0) {
          // 无搜索结果
          Text('无匹配结果')
            .fontSize(14)
            .fontColor('#9CA3AF')
            .margin({ top: 20 })
        }
      } else {
        // 正常模式 - 显示所有内容
        // default 笔记本
        this.NotebookItem('default', true, false)

        // default笔记本下的文件列表
        Column({ space: 4 }) {
          this.FileItem('Mockup Date 1', false, $r('app.color.accent_purple'))
          this.FileItem('Mockup Date 2', false, $r('app.color.accent_purple'))
          this.FileItem('Mockup Date 3', true, $r('app.color.accent_green'))
        }
        .padding({ left: this.isMaximized ? 24 : 12, right: this.isMaximized ? 24 : 12 })
        .alignItems(this.isMaximized ? HorizontalAlign.Center : HorizontalAlign.Start)
        
        // 动态显示新创建的分组
        ForEach(this.getAudioGroupsArray(), (item: GroupItem) => {
          this.renderGroupItem(item.groupId, item.groupData)
        }, (item: GroupItem) => item.groupId)
      }
    }
  }

  @Builder
  NotebookItem(name: string, isDefault: boolean, isSelected: boolean) {
    Row({ space: 8 }) {
      // 笔记本图标
      Image($r('app.media.icon'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.accent_red'))

      Text(name)
        .fontSize(this.isMaximized ? 16 : 14)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: this.isMaximized ? 8 : 4,
      right: this.isMaximized ? 8 : 4,
      top: this.isMaximized ? 12 : 8,
      bottom: this.isMaximized ? 12 : 8
    })
    .backgroundColor(isSelected ? $r('app.color.background_tertiary') : Color.Transparent)
    .borderRadius(4)
    .justifyContent(this.isMaximized ? FlexAlign.Center : FlexAlign.Start)
  }

  @Builder
  FileItem(name: string, isSelected: boolean, dotColor: Resource) {
    Row({ space: 8 }) {
      // 状态点
      Circle()
        .width(this.isMaximized ? 10 : 8)
        .height(this.isMaximized ? 10 : 8)
        .fill(dotColor)

      Text(name)
        .fontSize(this.isMaximized ? 16 : 14)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: this.isMaximized ? 16 : 8,
      right: this.isMaximized ? 16 : 8,
      top: this.isMaximized ? 8 : 4,
      bottom: this.isMaximized ? 8 : 4
    })
    .backgroundColor(isSelected ? $r('app.color.background_tertiary') : Color.Transparent)
    .borderRadius(4)
    .justifyContent(this.isMaximized ? FlexAlign.Center : FlexAlign.Start)
  }

  @Builder
  SearchResultItem(result: string) {
    Row({ space: 8 }) {
      // 搜索结果图标
      if (result === 'default' || result === 'new group') {
        Image($r('app.media.icon'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.accent_red'))
      } else {
        Circle()
          .width(8)
          .height(8)
          .fill($r('app.color.accent_purple'))
      }

      // 高亮显示匹配的文本
      this.HighlightText(result, this.searchText)
    }
    .width('100%')
    .padding({
      left: 8,
      right: 8,
      top: 6,
      bottom: 6
    })
    .backgroundColor('#4B5563')
    .borderRadius(4)
  }

  @Builder
  HighlightText(fullText: string, searchText: string) {
    if (searchText.length === 0) {
      Text(fullText)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    } else {
      Row() {
        Text(fullText)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
    }
  }

  @Builder
  MainContent() {
    Column() {
      // 头部标题
      this.MainHeader()

      // 文档编辑区域
      this.DocumentEditArea()
    }
    .layoutWeight(1)
    .height('100%')
    .backgroundColor('#1F2937')
    .padding(24)
  }

  @Builder
  MainHeader() {
    Column({ space: 12 }) {
      Row() {
        Text('Mockup Date 3')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Blank()
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  @Builder
  DocumentEditArea() {
    Column({ space: 4 }) {
      // 音轨符号按钮
      Row() {
        Button() {
          Image($r('app.media.mic_icon'))
            .width(30)
            .height(30)
            .fillColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(this.recordButtonHovered || this.recordButtonPressed ? '#4B5563' : '#1F2937')
        .borderRadius(20)
        .onHover((isHover: boolean) => {
          this.recordButtonHovered = isHover;
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.recordButtonPressed = true;
          } else if (event.type === TouchType.Up) {
            this.recordButtonPressed = false;
          }
        })
        .onClick(() => {
          this.toggleRecording();
        })
        
        // 录音状态显示 - 与mic_icon.png同一行
        if (this.isRecording) {
          Text('录音中...')
            .fontSize(14)
            .fontColor('#EF4444')
            .margin({ left: 12 })
        }
        
        Blank()
        
        // 三个点菜单
        Text('⋯')
          .fontSize(20)
          .fontColor('#9CA3AF')
          .onClick(() => {
            this.isSelectionMode = !this.isSelectionMode;
            if (!this.isSelectionMode) {
              this.selectedTracks.clear();
              this.showGroupOptions = false;
            }
          })
      }
      .width('100%')
      .padding(16)
      
      // 混合内容滚动区域（文本编辑和语音条在同一个滚动容器中）
      Scroll() {
        Column({ space: 8 }) {
          // 文本编辑区域（在滚动区域内）
          TextArea({
            text: this.documentContent
          })
            .width('100%')
            .height(12)
            .fontSize(16)
            .fontColor('#1F2937')
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .padding(16)
            .onChange((value: string) => {
              this.documentContent = value;
            })
            .onKeyEvent((event) => {
              // 检查是否为删除键按下事件
              // 支持多种设备的删除键：Delete键(2017, 46)、Backspace键(67, 8)、以及其他常见键码
              if (event.type === 0 && (
                event.keyCode === 2017 || // Delete键
                event.keyCode === 67 ||   // Backspace键
                event.keyCode === 46 ||   // Delete键(标准键码)
                event.keyCode === 8 ||    // Backspace键(标准键码)
                event.keyCode === 127     // Delete键(ASCII)
              )) {
                this.handleDeleteKey();
              }
            })
          
          // 录音轨显示（在文本编辑区域下方）
          if (this.currentRecordingTrack) {
            this.RecordingTrackItem(this.currentRecordingTrack)
          }
          
          // 已完成的音轨（置顶音轨在前，其他音轨在后）
          ForEach(this.getSortedAudioTracks(), (track: AudioTrack) => {
            this.CompletedAudioTrackItem(track)
          }, (track: AudioTrack) => track.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 4, bottom: 16 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.On)
      .scrollBarColor('#E5E7EB')
      .scrollBarWidth(4)
      .layoutWeight(1)
      .width('100%')
      .padding({ right: 60 })
      .edgeEffect(EdgeEffect.Fade)
      .align(Alignment.TopStart)
      .onScroll((xOffset: number, yOffset: number) => {
        // 确保滚动方向正确：正的yOffset表示向下滚动
      })
      
      // 选择模式下的底部操作按钮
      if (this.isSelectionMode && this.selectedTracks.size > 0) {
        Row({ space: 16 }) {
          // 加入分组按钮
          Button('加入分组')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#10B981')
            .borderRadius(8)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.showGroupOptions = true;
            })
          
          // 置顶按钮
          Button('置顶')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#F59E0B')
            .borderRadius(8)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.pinSelectedTracks();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 16, bottom: 16 })
        .backgroundColor('#374151')
      }
      
      // 分组选项弹窗
      if (this.showGroupOptions) {
        this.GroupOptionsDialog()
      }
      
      // 新建分组对话框
      if (this.showNewGroupDialog) {
        this.NewGroupDialog()
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding(16)
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  RecordingTrackItem(track: AudioTrack) {
    Row({ space: 12 }) {
      // 录音状态指示器
      Circle()
        .width(8)
        .height(8)
        .fill('#EF4444')
      
      // 实时波形显示
      this.RealtimeWaveformVisualization()
      
      // 录音时长显示在最右端 - 使用实时录音时长
      Text(this.formatDuration(this.recordingDuration))
        .fontSize(12)
        .fontColor('#FFFFFF')
        .width(50)
        .textAlign(TextAlign.End)
        .flexShrink(0)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#4B5563')
    .borderRadius(24)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8, top: 0 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  CompletedAudioTrackItem(track: AudioTrack) {
    Row({ space: 12 }) {
      // 选择模式下的checkbox（置顶音轨不显示checkbox）
      if (this.isSelectionMode && !this.pinnedTracks.includes(track.id)) {
        Row() {
          if (this.selectedTracks.has(track.id)) {
            // 选中状态 - 实心圆
            Circle()
              .width(20)
              .height(20)
              .fill('#10B981')
.stroke('#10B981')
          } else {
            // 未选中状态 - 空心圆
            Circle()
              .width(20)
              .height(20)
              .fill('transparent')
.stroke('#9CA3AF')
          }
        }
        .width(24)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.selectedTracks.has(track.id)) {
            this.selectedTracks.delete(track.id);
          } else {
            this.selectedTracks.add(track.id);
          }
          // 如果有选中的音轨，显示操作选项
          this.showGroupOptions = this.selectedTracks.size > 0;
        })
      }
      
      // 播放/停止按钮
      Row() {
        if (track.isPlaying) {
          // 停止按钮（白色正方形）
          Rect()
            .width(8)
            .height(8)
            .fill('#FFFFFF')
        } else {
          // 播放按钮（白色三角形）
          Polygon()
            .width(10)
            .height(10)
            .points([[0, 0], [10, 5], [0, 10]])
            .fill('#FFFFFF')
        }
      }
      .width(24)
      .height(24)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (!this.isSelectionMode) {
          this.toggleTrackPlayback(track.id);
        }
      })
      
      // 已完成波形显示
      this.CompletedWaveformVisualization(track)
      
      // 音轨时长
      Text(this.formatDuration(track.duration))
        .fontSize(12)
        .fontColor('#FFFFFF')
        .width(50)
        .textAlign(TextAlign.End)
        .flexShrink(0)
      
      // 选择模式下的拖拽手柄
      if (this.isSelectionMode) {
        Row() {
          Text('≡')
            .fontSize(16)
            .fontColor('#9CA3AF')
            .textAlign(TextAlign.Center)
        }
        .width(24)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction(() => {
              this.startDragMode(track.id);
            })
        )
        .gesture(
          PanGesture()
            .onActionStart(() => {
              this.dragStartIndex = this.audioTracks.findIndex(t => t.id === track.id);
            })
            .onActionUpdate((event: GestureEvent) => {
              if (this.dragStartIndex !== -1) {
                this.handleDragUpdate(event.offsetY);
              }
            })
            .onActionEnd(() => {
              this.endDragMode();
            })
        )
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#4B5563')
    .borderRadius(24)
    .margin({ bottom: 8 })
  }



  @Builder
  RealtimeWaveformVisualization() {
    Row({ space: 2 }) {
      ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39], (item: number) => {
        Column()
          .width(2)
          .height(this.getRealtimeWaveformHeight(item))
          .backgroundColor('#10B981')
          .borderRadius(1)
      })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  CompletedWaveformVisualization(track: AudioTrack) {
    Row({ space: 2 }) {
      ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39], (item: number) => {
        Column()
          .width(2)
          .height(this.getCompletedWaveformHeight(track, item))
          .backgroundColor(track.isPlaying ? '#10B981' : '#9CA3AF')
          .borderRadius(1)
      })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  WaveformVisualization(trackIndex: number) {
    Row({ space: 2 }) {
      ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39], (item: number) => {
        Column()
          .width(2)
          .height(this.getWaveformHeight(trackIndex, item))
          .backgroundColor(this.playingTrack === trackIndex ? '#10B981' : '#9CA3AF')
          .borderRadius(1)
      })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 生成波形高度数据
  private getWaveformHeight(trackIndex: number, barIndex: number): number {
    // 为每个轨道生成固定的波形数据
    const baseHeight = 8;
    const variation = 16;
    const seed = trackIndex * 20 + barIndex;
    return baseHeight + (Math.sin(seed * 0.3) * variation * 0.5 + variation * 0.5);
  }

  // 获取实时波形高度
  private getRealtimeWaveformHeight(barIndex: number): number {
    const minHeight = 0.9; // 最小高度（更短的收缩）
    const maxHeight = 40; // 最大高度（更长的扩展，接近录音条边缘）
    
    // 使用动画种子和条形索引生成随机变化
    const seed1 = (this.animationSeed + barIndex * 7) % 1000;
    const seed2 = (this.animationSeed * 3 + barIndex * 11) % 1000;
    
    // 生成随机高度，使用多个正弦波叠加产生更自然的随机效果
    const amplitude1 = Math.sin(seed1 * 0.01) * 0.5 + 0.5;
    const amplitude2 = Math.sin(seed2 * 0.013) * 0.3 + 0.3;
    const combinedAmplitude = (amplitude1 + amplitude2) / 2;
    
    const height = minHeight + combinedAmplitude * (maxHeight - minHeight);
    return Math.round(height);
  }

  // 获取已完成音轨的波形高度
  private getCompletedWaveformHeight(track: AudioTrack, barIndex: number): number {
    if (track.finalWaveform && track.finalWaveform[barIndex] !== undefined) {
      return track.finalWaveform[barIndex];
    }
    // 如果没有保存的波形数据，使用默认生成
    const baseHeight = 2;
    const variation = 16;
    const seed = parseInt(track.id) * 20 + barIndex;
    return baseHeight + (Math.sin(seed * 0.3) * variation * 0.5 + variation * 0.5);
  }

  // 格式化时长为 mm:ss 格式
  private formatDuration(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  // 切换音轨播放状态
  private toggleTrackPlayback(trackId: string): void {
    const trackIndex = this.audioTracks.findIndex(track => track.id === trackId);
    if (trackIndex !== -1) {
      // 停止所有其他音轨的播放
      this.audioTracks.forEach((track, index) => {
        if (index !== trackIndex) {
          track.isPlaying = false;
        }
      });
      
      // 切换当前音轨的播放状态
      this.audioTracks[trackIndex].isPlaying = !this.audioTracks[trackIndex].isPlaying;
      
      if (this.audioTracks[trackIndex].isPlaying) {
        hilog.info(DOMAIN, 'testTag', `开始播放音轨: ${trackId}`);
        // 这里可以添加实际的音频播放逻辑
      } else {
        hilog.info(DOMAIN, 'testTag', `停止播放音轨: ${trackId}`);
        // 这里可以添加实际的音频停止逻辑
      }
    }
  }

  // 切换搜索状态
  private toggleSearch(): void {
    this.isSearchActive = !this.isSearchActive;
    if (!this.isSearchActive) {
      // 关闭搜索时清空搜索内容
      this.searchText = '';
      this.searchResults = [];
    }
  }

  // 执行搜索
  private performSearch(searchText: string): void {
    if (searchText.trim().length === 0) {
      this.searchResults = [];
      return;
    }

    const lowerSearchText = searchText.toLowerCase();
    this.searchResults = this.allSearchableTexts.filter(text => 
      text.toLowerCase().includes(lowerSearchText)
    );
  }

  // 切换最大化状态
  private toggleMaximize(): void {
    this.isMaximized = !this.isMaximized;
  }
  
  // 切换录音状态
  private toggleRecording(): void {
    if (this.isRecording) {
      // 停止录音
      this.stopRecording();
    } else {
      // 开始录音
      this.startRecording();
    }
  }
  
  // 开始录音
  private startRecording(): void {
    this.isRecording = true;
    this.recordingDuration = 0;
    this.animationSeed = 0;
    
    // 创建新的录音音轨
    const newTrack: AudioTrack = {
      id: Date.now().toString(),
      waveformData: [],
      duration: 0,
      isPlaying: false,
      position: this.documentContent.length, // 在当前光标位置
      finalWaveform: []
    };
    
    this.currentRecordingTrack = newTrack;
    this.startRecordingTimer();
    this.startWaveformAnimation();
    
    hilog.info(DOMAIN, 'testTag', '开始录音');
  }
  
  // 停止录音
  private stopRecording(): void {
    this.isRecording = false;
    
    if (this.currentRecordingTrack) {
      // 保存最终波形数据
      const finalWaveform: number[] = [];
      for (let i = 0; i < 40; i++) {
        finalWaveform.push(this.getRealtimeWaveformHeight(i));
      }
      
      this.currentRecordingTrack.duration = this.recordingDuration;
      this.currentRecordingTrack.finalWaveform = finalWaveform;
      this.currentRecordingTrack.isPlaying = false; // 确保初始状态为非播放状态
      
      // 将录音音轨添加到已完成列表的末尾（新录音在下方，按时间顺序排列）
      this.audioTracks.push(this.currentRecordingTrack);
      this.currentRecordingTrack = null;
    }
    
    // 清除所有计时器
    if (this.recordingTimer !== -1) {
      clearInterval(this.recordingTimer);
      this.recordingTimer = -1;
    }
    
    if (this.waveformAnimationTimer !== -1) {
      clearInterval(this.waveformAnimationTimer);
      this.waveformAnimationTimer = -1;
    }
    
    this.recordingDuration = 0;
    hilog.info(DOMAIN, 'testTag', '录音已停止');
  }
  
  // 录音计时器 - 每100毫秒更新一次以实现更流畅的计时显示
  private startRecordingTimer(): void {
    this.recordingTimer = setInterval(() => {
      if (this.isRecording) {
        this.recordingDuration++;
        // 同时更新当前录音音轨的时长
        if (this.currentRecordingTrack) {
          this.currentRecordingTrack.duration = this.recordingDuration;
        }
      } else {
        clearInterval(this.recordingTimer);
        this.recordingTimer = -1;
      }
    }, 1000);
  }
  
  // 波形动画定时器 - 每50毫秒更新一次以实现流畅的波形动画
  private startWaveformAnimation(): void {
    this.waveformAnimationTimer = setInterval(() => {
      if (this.isRecording) {
        // 更新动画种子以产生随机波形变化
        this.animationSeed = (this.animationSeed + 1) % 10000;
      } else {
        clearInterval(this.waveformAnimationTimer);
        this.waveformAnimationTimer = -1;
      }
    }, 50);
  }
  
  // 处理删除键事件
  private handleDeleteKey(): void {
    // 检查光标是否位于语音条之后
    const cursorPosition = this.documentContent.length; // 简化处理，假设光标在末尾
    
    // 删除最新的音轨（数组最后一个元素）
    if (this.audioTracks.length > 0) {
      const lastTrack = this.audioTracks[this.audioTracks.length - 1];
      
      // 删除最后一个音轨
      this.audioTracks.pop();
      hilog.info(DOMAIN, 'testTag', `删除音轨: ${lastTrack.id}`);
    }
  }



  // 分组选项对话框
  @Builder
  GroupOptionsDialog() {
    Column() {
      // 背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showGroupOptions = false;
        })
      
      // 对话框内容
      Column({ space: 16 }) {
        Text('选择操作')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        // 加入已有分组
        Button('加入已有分组')
          .width('100%')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#374151')
          .borderRadius(8)
          .onClick(() => {
            this.showExistingGroups();
          })
        
        // 加入新分组
        Button('加入新分组')
          .width('100%')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#10B981')
          .borderRadius(8)
          .onClick(() => {
            this.showGroupOptions = false;
            this.showNewGroupDialog = true;
          })
        
        // 取消按钮
        Button('取消')
          .width('100%')
          .fontSize(16)
          .fontColor('#9CA3AF')
          .backgroundColor('transparent')
          .border({ width: 1, color: '#9CA3AF' })
          .borderRadius(8)
          .onClick(() => {
            this.showGroupOptions = false;
          })
      }
      .width(280)
      .padding(24)
      .backgroundColor('#1F2937')
      .borderRadius(12)
      .position({ x: '50%', y: '50%' })
      .translate({ x: '-50%', y: '-50%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }
  
  // 新建分组对话框
  @Builder
  NewGroupDialog() {
    Column() {
      // 背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showNewGroupDialog = false;
          this.newGroupName = '';
        })
      
      // 对话框内容
      Column({ space: 16 }) {
        Text('创建新分组')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        // 输入框
        TextInput({ placeholder: '请输入分组名称', text: this.newGroupName })
          .width('100%')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#374151')
          .borderRadius(8)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .placeholderColor('#9CA3AF')
          .onChange((value: string) => {
            this.newGroupName = value;
          })
        
        Row({ space: 12 }) {
          // 取消按钮
          Button('取消')
            .layoutWeight(1)
            .fontSize(16)
            .fontColor('#9CA3AF')
            .backgroundColor('transparent')
            .border({ width: 1, color: '#9CA3AF' })
            .borderRadius(8)
            .onClick(() => {
              this.showNewGroupDialog = false;
              this.newGroupName = '';
            })
          
          // 确认按钮
          Button('确认')
            .layoutWeight(1)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#10B981')
            .borderRadius(8)
            .onClick(() => {
              this.createNewGroup();
            })
        }
        .width('100%')
      }
      .width(320)
      .padding(24)
      .backgroundColor('#1F2937')
      .borderRadius(12)
      .position({ x: '50%', y: '50%' })
      .translate({ x: '-50%', y: '-50%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }
  
  // 显示已有分组列表
  private showExistingGroups(): void {
    // 这里可以实现显示已有分组的逻辑
    hilog.info(DOMAIN, 'testTag', '显示已有分组列表');
    this.showGroupOptions = false;
  }
  
  // 创建新分组
  private createNewGroup(): void {
    if (this.newGroupName.trim().length === 0) {
      return;
    }
    
    const groupId = Date.now().toString();
    const selectedTrackIds = Array.from(this.selectedTracks);
    
    // 创建新分组
    const newGroup: AudioGroup = {
      name: this.newGroupName.trim(),
      tracks: selectedTrackIds,
      fileItems: []
    };
    this.audioGroups.set(groupId, newGroup);
    
    hilog.info(DOMAIN, 'testTag', `创建新分组: ${this.newGroupName}, 包含 ${selectedTrackIds.length} 个音轨`);
    
    // 清空选择状态
    this.selectedTracks.clear();
    this.isSelectionMode = false;
    this.showNewGroupDialog = false;
    this.newGroupName = '';
  }
  
  // 置顶选中的音轨
  private pinSelectedTracks(): void {
    const selectedTrackIds = Array.from(this.selectedTracks);
    
    selectedTrackIds.forEach(trackId => {
      if (!this.pinnedTracks.includes(trackId)) {
        this.pinnedTracks.push(trackId);
      }
    });
    
    hilog.info(DOMAIN, 'testTag', `置顶 ${selectedTrackIds.length} 个音轨`);
    
    // 清空选择状态
    this.selectedTracks.clear();
    this.isSelectionMode = false;
  }
  
  // 开始拖拽模式
  private startDragMode(trackId: string): void {
    this.isDragging = true;
    this.dragStartIndex = this.audioTracks.findIndex(track => track.id === trackId);
    this.dragCurrentIndex = this.dragStartIndex;
    hilog.info(DOMAIN, 'testTag', `开始拖拽音轨: ${trackId}, 索引: ${this.dragStartIndex}`);
  }
  
  // 处理拖拽更新
  private handleDragUpdate(offsetY: number): void {
    if (this.dragStartIndex === -1) return;
    
    // 计算目标索引（每个音轨高度约48px）
    const itemHeight = 48;
    const indexOffset = Math.round(offsetY / itemHeight);
    const targetIndex = Math.max(0, Math.min(this.audioTracks.length - 1, this.dragStartIndex + indexOffset));
    
    if (targetIndex !== this.dragCurrentIndex) {
      this.dragCurrentIndex = targetIndex;
      // 实时交换位置
      this.swapTracks(this.dragStartIndex, targetIndex);
      this.dragStartIndex = targetIndex;
    }
  }
  
  // 结束拖拽模式
  private endDragMode(): void {
    this.isDragging = false;
    this.dragStartIndex = -1;
    this.dragCurrentIndex = -1;
    hilog.info(DOMAIN, 'testTag', '结束拖拽模式');
  }
  
  // 交换两个音轨的位置
  private swapTracks(fromIndex: number, toIndex: number): void {
    if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || 
        fromIndex >= this.audioTracks.length || toIndex >= this.audioTracks.length) {
      return;
    }
    
    const temp = this.audioTracks[fromIndex];
    this.audioTracks[fromIndex] = this.audioTracks[toIndex];
    this.audioTracks[toIndex] = temp;
    
    hilog.info(DOMAIN, 'testTag', `交换音轨位置: ${fromIndex} <-> ${toIndex}`);
  }
  
  // 获取排序后的音轨列表（置顶音轨在前）
  private getSortedAudioTracks(): AudioTrack[] {
    const pinnedTracks: AudioTrack[] = [];
    const normalTracks: AudioTrack[] = [];
    
    this.audioTracks.forEach(track => {
      if (this.pinnedTracks.includes(track.id)) {
        pinnedTracks.push(track);
      } else {
        normalTracks.push(track);
      }
    });
    
    // 置顶音轨按原始顺序排列，然后是普通音轨
    return [...pinnedTracks, ...normalTracks];
  }
  
  // 获取当前日期字符串
  private getCurrentDateString(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
  
  // 将Map转换为数组以供ForEach使用
  private getAudioGroupsArray(): GroupItem[] {
    const result: GroupItem[] = [];
    this.audioGroups.forEach((groupData: AudioGroup, groupId: string) => {
      result.push({ groupId, groupData });
    });
    return result;
  }
  
  // 渲染分组项
  @Builder
  renderGroupItem(groupId: string, groupData: AudioGroup) {
    Column() {
      // 分组笔记本
      this.NotebookItem(groupData.name, false, false)
      
      // 分组下的文件
      Column({ space: 4 }) {
        this.FileItem(this.getCurrentDateString(), false, $r('app.color.accent_red'))
      }
    }
    .padding({ left: this.isMaximized ? 24 : 12, right: this.isMaximized ? 24 : 12 })
    .alignItems(this.isMaximized ? HorizontalAlign.Center : HorizontalAlign.Start)
  }

  // 生成实时波形数据
  private generateRealtimeWaveform(): void {
    // 模拟实时波形数据生成
    const newPoint = Math.random() * 0.8 + 0.1;
    this.realtimeWaveform.push(newPoint);
    
    // 限制波形数据长度
    if (this.realtimeWaveform.length > 100) {
      this.realtimeWaveform.shift();
    }
  }

  aboutToAppear() {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Audio Notebook App started');
  }
}