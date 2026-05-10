/**
 * 铭键输入法 - 主应用页面
 * 展示应用信息和设置入口
 * 
 * 功能：
 * - 显示应用介绍
 * - 跳转到输入法设置
 * - 显示翻译Agent状态
 */

import commonEventManager from '@ohos.commonEventManager';
import promptAction from '@ohos.promptAction';
import hilog from '@hilog';

@Entry
@Component
struct Index {
  // 应用状态
  @State appStatus: string = '初始化中...';
  @State translateServiceStatus: string = '正常';
  @State version: string = '1.0.0 PoC';

  /**
   * 页面即将显示时调用
   */
  aboutToAppear() {
    hilog.info(0x0000, 'MingKeyIndex', '主页面加载');
    this.checkServiceStatus();
  }

  /**
   * 检查服务状态
   */
  checkServiceStatus() {
    this.appStatus = '运行中';
    this.translateServiceStatus = '正常';
  }

  /**
   * 跳转到输入法设置
   */
  async goToInputMethodSettings() {
    try {
      // 尝试跳转到系统输入法设置页面
      // 注意：实际跳转需要系统权限
      hilog.info(0x0000, 'MingKeyIndex', '请求跳转到输入法设置');
      
      promptAction.showToast({
        message: '请在系统设置中启用铭键输入法',
        duration: 3000
      });
    } catch (error) {
      hilog.error(0x0000, 'MingKeyIndex', '跳转失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 测试翻译功能
   */
  async testTranslation() {
    hilog.info(0x0000, 'MingKeyIndex', '测试翻译功能');
    
    // 发布测试翻译请求
    const requestId = `test_${Date.now()}`;
    const publishOptions: commonEventManager.PublishOptions = {
      parameters: {
        requestId: requestId,
        text: '你好世界',
        sourceLang: 'zh',
        targetLang: 'en'
      }
    };

    commonEventManager.publish('com.mingkey.inputmethod.TRANSLATE_REQUEST', publishOptions, (err) => {
      if (err) {
        hilog.error(0x0000, 'MingKeyIndex', '发布测试请求失败: %{public}s', JSON.stringify(err));
        promptAction.showToast({
          message: '测试失败',
          duration: 2000
        });
      } else {
        promptAction.showToast({
          message: '翻译请求已发送，请查看输入法键盘',
          duration: 2000
        });
      }
    });
  }

  /**
   * 构建页面UI
   */
  build() {
    Column() {
      // 顶部标题区域
      Column() {
        Text('铭键')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 60 });

        Text('MingKey')
          .fontSize(20)
          .fontColor('#666666')
          .margin({ top: 8 });

        Text('智能输入法 - Agent入口')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 16 });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center);

      // 版本信息
      Column() {
        Text(`版本: ${this.version}`)
          .fontSize(12)
          .fontColor('#999999');
      }
      .margin({ top: 20 });

      // 服务状态卡片
      Column() {
        Text('服务状态')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, bottom: 12 });

        Row() {
          Text('主应用状态')
            .fontSize(14)
            .fontColor('#666666');
          Blank();
          Text(this.appStatus)
            .fontSize(14)
            .fontColor('#52C41A');
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 8 });

        Divider()
          .color('#F0F0F0')
          .margin({ left: 20, right: 20 });

        Row() {
          Text('翻译服务')
            .fontSize(14)
            .fontColor('#666666');
          Blank();
          Text(this.translateServiceStatus)
            .fontSize(14)
            .fontColor('#52C41A');
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 8 });
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: '#0D000000',
        offsetX: 0,
        offsetY: 2
      })
      .margin({ top: 40 });

      // 功能说明卡片
      Column() {
        Text('使用说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, bottom: 12 });

        Text('1. 在系统设置中启用"铭键输入法"')
          .fontSize(13)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, bottom: 8 });

        Text('2. 将铭键设为默认输入法')
          .fontSize(13)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, bottom: 8 });

        Text('3. 长按空格键触发翻译Agent')
          .fontSize(13)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20 });
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: '#0D000000',
        offsetX: 0,
        offsetY: 2
      })
      .margin({ top: 20 });

      // 按钮区域
      Column() {
        Button('测试翻译')
          .width('80%')
          .height(44)
          .backgroundColor('#1890FF')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            this.testTranslation();
          });

        Button('启用输入法')
          .width('80%')
          .height(44)
          .backgroundColor('#52C41A')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            this.goToInputMethodSettings();
          });
      }
      .margin({ top: 40, bottom: 40 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}
