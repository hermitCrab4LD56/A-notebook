import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State selectedTrack: number = 2; // 当前选中的轨道
  @State playingTrack: number = -1; // 当前播放的轨道
  @State waveformData: number[] = []; // 波形数据
  
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

        // new group 笔记本
        this.NotebookItem('new group', false, false)
      }
    }
    .width('100%')
    .padding(this.isMaximized ? 24 : 12)
    .alignItems(this.isMaximized ? HorizontalAlign.Center : HorizontalAlign.Start)
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
      Circle({ width: this.isMaximized ? 10 : 8, height: this.isMaximized ? 10 : 8 })
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
        Circle({ width: 8, height: 8 })
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

      // 音频轨道列表
      this.AudioTracksList()
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

        // 三个点菜单
        Text('⋯')
          .fontSize(20)
          .fontColor('#9CA3AF')
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/UpdateNotebookLabels' });
            } catch (error) {
              hilog.error(DOMAIN, 'testTag', 'Failed to navigate to UpdateNotebookLabels: %{public}s', JSON.stringify(error));
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  @Builder
  AudioTracksList() {
    Column({ space: 12 }) {
      this.AudioTrackItem($r('app.string.audio_track_1_duration').toString(), 0, this.playingTrack === 0)
      this.AudioTrackItem($r('app.string.audio_track_2_duration').toString(), 1, this.playingTrack === 1)
      this.AudioTrackItem($r('app.string.audio_track_3_duration').toString(), 2, this.playingTrack === 2)
      this.AudioTrackItem($r('app.string.audio_track_4_duration').toString(), 3, this.playingTrack === 3)
    }
    .width('100%')
  }

  @Builder
  AudioTrackItem(duration: string, trackIndex: number, isPlaying: boolean) {
    Row({ space: 16 }) {
      // 音量图标
      Text('🔊')
        .fontSize(16)
        .fontColor(isPlaying ? '#10B981' : '#D1D5DB')

      // 波形可视化
      this.WaveformVisualization(trackIndex)

      // 时长
      Text(duration)
        .fontSize(14)
        .fontColor('#D1D5DB')
    }
    .width('100%')
    .height(56)
    .padding(16)
    .backgroundColor('#4B5563')
    .borderRadius(8)
    .onClick(() => {
      this.playingTrack = isPlaying ? -1 : trackIndex;
    })
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



  aboutToAppear() {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Audio Notebook App started');
  }
}