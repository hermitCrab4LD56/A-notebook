import { router } from '@kit.ArkUI';

@Entry
@Component
struct UpdateNotebookLabels {
  @State private labels: string[] = ['工作', '学习', '生活', '重要'];
  @State private newLabel: string = '';
  @State private editingIndex: number = -1;
  @State private editingText: string = '';

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor('#333333')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

        Text('更新笔记本标签')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button('保存')
          .fontSize(16)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.saveLabels();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Divider()
        .color('#E5E5E5')
        .strokeWidth(0.5)

      // 主要内容区域
      Column() {
        // 添加新标签区域
        Column() {
          Text('添加新标签')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })

          Row() {
            TextInput({ placeholder: '输入标签名称' })
              .layoutWeight(1)
              .height(44)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.newLabel = value;
              })

            Button('添加')
              .width(60)
              .height(44)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor('#007AFF')
              .borderRadius(8)
              .margin({ left: 12 })
              .onClick(() => {
                this.addLabel();
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ bottom: 16 })

        // 现有标签列表
        Column() {
          Text('现有标签')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })

          List() {
            ForEach(this.labels, (label: string, index: number) => {
              ListItem() {
                this.LabelItem(label, index)
              }
              .margin({ bottom: 8 })
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(16)
      .backgroundColor('#F8F8F8')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  @Builder
  LabelItem(label: string, index: number) {
    Row() {
      if (this.editingIndex === index) {
        // 编辑模式
        TextInput({ text: this.editingText })
          .layoutWeight(1)
          .height(40)
          .borderRadius(6)
          .backgroundColor('#F5F5F5')
          .border({ width: 1, color: '#007AFF' })
          .padding({ left: 8, right: 8 })
          .onChange((value: string) => {
            this.editingText = value;
          })

        Button('确认')
          .width(50)
          .height(32)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#007AFF')
          .borderRadius(6)
          .margin({ left: 8 })
          .onClick(() => {
            this.confirmEdit(index);
          })

        Button('取消')
          .width(50)
          .height(32)
          .fontSize(12)
          .fontColor('#666666')
          .backgroundColor('#E0E0E0')
          .borderRadius(6)
          .margin({ left: 4 })
          .onClick(() => {
            this.cancelEdit();
          })
      } else {
        // 显示模式
        Row() {
          Text(label)
            .fontSize(16)
            .fontColor('#333333')
            .layoutWeight(1)

          // 标签颜色指示器
          Circle()
            .width(12)
            .height(12)
            .fill(this.getLabelColor(index))
            .margin({ left: 8, right: 12 })
        }
        .layoutWeight(1)
        .onClick(() => {
          this.startEdit(index, label);
        })

        Button() {
          Image($r('sys.media.ohos_ic_public_delete'))
            .width(16)
            .height(16)
            .fillColor('#FF3B30')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.deleteLabel(index);
        })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
    .borderRadius(8)
    .border({ width: 1, color: '#E0E0E0' })
  }

  private addLabel(): void {
    if (this.newLabel.trim() && !this.labels.includes(this.newLabel.trim())) {
      this.labels.push(this.newLabel.trim());
      this.newLabel = '';
    }
  }

  private startEdit(index: number, label: string): void {
    this.editingIndex = index;
    this.editingText = label;
  }

  private confirmEdit(index: number): void {
    if (this.editingText.trim() && !this.labels.includes(this.editingText.trim())) {
      this.labels[index] = this.editingText.trim();
    }
    this.cancelEdit();
  }

  private cancelEdit(): void {
    this.editingIndex = -1;
    this.editingText = '';
  }

  private deleteLabel(index: number): void {
    this.labels.splice(index, 1);
  }

  private getLabelColor(index: number): string {
    const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD'];
    return colors[index % colors.length];
  }

  private saveLabels(): void {
    // 这里可以添加保存到本地存储或服务器的逻辑
    console.log('保存标签:', this.labels);
    router.back();
  }
}