import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State selectedTrack: number = 2; // 当前选中的轨道
  @State playingTrack: number = -1; // 当前播放的轨道
  @State waveformData: number[] = []; // 波形数据

  build() {
    Row() {
      // 侧边栏
      this.Sidebar()

      // 主内容区
      this.MainContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  Sidebar() {
    Column() {
      // 侧边栏头部
      this.SidebarHeader()

      // 文件/笔记本部分
      this.NotebookSection()
    }
    .width(192) // 48 * 4 = 192vp
    .height('100%')
    .backgroundColor($r('app.color.background_secondary'))
    .border({ width: { right: 1 }, color: $r('app.color.border_primary') })
  }

  @Builder
  SidebarHeader() {
    Row() {
      // 菜单图标
      Image($r('app.media.icon'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_tertiary'))

      Blank()

      // 搜索和最大化图标
      Row({ space: 8 }) {
        Image($r('app.media.icon'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.text_tertiary'))

        Image($r('app.media.icon'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.text_tertiary'))
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 1 }, color: $r('app.color.border_primary') })
  }

  @Builder
  NotebookSection() {
    Column({ space: 16 }) {
      // default 笔记本
      this.NotebookItem($r('app.string.default_notebook').toString(), true, false)

      // 文件列表
      Column({ space: 4 }) {
        this.FileItem($r('app.string.mockup_date_1').toString(), false, $r('app.color.accent_purple'))
        this.FileItem($r('app.string.mockup_date_2').toString(), false, $r('app.color.accent_purple'))
        this.FileItem($r('app.string.mockup_date_3').toString(), true, $r('app.color.accent_green'))
      }
      .padding({ left: 12, right: 12 })

      // new group 笔记本
      this.NotebookItem($r('app.string.new_group').toString(), false, false)
    }
    .width('100%')
    .padding(12)
    .alignItems(HorizontalAlign.Start)
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
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding({
      left: 4,
      right: 4,
      top: 8,
      bottom: 8
    })
    .backgroundColor(isSelected ? $r('app.color.background_tertiary') : Color.Transparent)
    .borderRadius(4)
  }

  @Builder
  FileItem(name: string, isSelected: boolean, dotColor: Resource) {
    Row({ space: 8 }) {
      // 状态点
      Circle({ width: 8, height: 8 })
        .fill(dotColor)

      Text(name)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding({
      left: 8,
      right: 8,
      top: 4,
      bottom: 4
    })
    .backgroundColor(isSelected ? $r('app.color.background_tertiary') : Color.Transparent)
    .borderRadius(4)
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
    .backgroundColor($r('app.color.background_tertiary'))
    .padding(24)
  }

  @Builder
  MainHeader() {
    Column({ space: 12 }) {
      Row() {
        Text($r('app.string.mockup_date_3').toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        Blank()

        // 标签管理按钮
        Button('标签管理')
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.background_secondary'))
          .borderRadius(6)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/UpdateNotebookLabels' });
          })

        // 三个点菜单
        Column({ space: 2 }) {
          Circle({ width: 4, height: 4 })
            .fill($r('app.color.text_tertiary'))
          Circle({ width: 4, height: 4 })
            .fill($r('app.color.text_tertiary'))
          Circle({ width: 4, height: 4 })
            .fill($r('app.color.text_tertiary'))
        }
      }
      .width('100%')

      // 分割线
      Divider()
        .color($r('app.color.border_primary'))
        .strokeWidth(1)
    }
    .width('100%')
    .margin({ bottom: 16 })
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
      Image($r('app.media.icon'))
        .width(20)
        .height(20)
        .fillColor(isPlaying ? $r('app.color.accent_green') : $r('app.color.text_secondary'))

      // 波形可视化
      this.WaveformVisualization(trackIndex)

      // 时长
      Text(duration)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height(56)
    .padding(16)
    .backgroundColor(isPlaying ? $r('app.color.background_tertiary') : $r('app.color.background_secondary'))
    .borderRadius(8)
    .onClick(() => {
      this.playingTrack = isPlaying ? -1 : trackIndex;
    })
  }

  @Builder
  WaveformVisualization(trackIndex: number) {
    Row({ space: 2 }) {
      ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19], (item: number) => {
        Column()
          .width(2)
          .height(this.getWaveformHeight(trackIndex, item))
          .backgroundColor(this.playingTrack === trackIndex ? $r('app.color.accent_green') : $r('app.color.wave_color'))
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

  aboutToAppear() {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Audio Notebook App started');
  }
}