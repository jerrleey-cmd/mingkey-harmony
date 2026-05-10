/**
 * 铭键输入法 - 键盘UI组件
 * 
 * 功能：
 * - QWERTY 26键布局
 * - 数字/符号切换
 * - 空格键长按触发翻译Agent
 * - 中英文切换
 * 
 * 设计原则：
 * - 本地优先，AI能力通过IPC委托
 * - 不在Extension进程中进行网络请求
 */

import inputMethod from '@ohos.inputMethod';
import display from '@ohos.display';
import commonEventManager from '@ohos.commonEventManager';
import hilog from '@hilog';

/**
 * 日志域ID
 */
const TAG = 'MingKeyKeyboardUI';

/**
 * CommonEvent事件名称
 */
const TRANSLATE_REQUEST_EVENT = 'com.mingkey.inputmethod.TRANSLATE_REQUEST';
const TRANSLATE_RESPONSE_EVENT = 'com.mingkey.inputmethod.TRANSLATE_RESPONSE';

/**
 * 键盘模式枚举
 */
enum KeyboardMode {
  QWERTY_LOWER = 0,      // 小写字母
  QWERTY_UPPER = 1,      // 大写字母
  NUMERIC = 2,           // 数字+符号
  SYMBOL = 3             // 特殊符号
}

/**
 * 按键数据接口
 */
interface KeyData {
  label: string;
  value: string;
  type: 'letter' | 'number' | 'symbol' | 'special';
  width?: number;  // 按键宽度比例
}

/**
 * 翻译结果接口
 */
interface TranslateResult {
  success: boolean;
  original: string;
  translated: string;
  sourceLang: string;
  targetLang: string;
  error?: string;
}

/**
 * 键盘组件
 */
@Component
export struct KeyboardComponent {
  // 键盘模式
  @State currentMode: KeyboardMode = KeyboardMode.QWERTY_LOWER;
  // 当前输入文本
  @State currentText: string = '';
  // 候选词列表
  @State candidates: string[] = ['你好', '世界', '铭键'];
  // 是否显示翻译结果
  @State showTranslateResult: boolean = false;
  // 翻译结果文本
  @State translateResult: string = '';
  // 是否正在翻译
  @State isTranslating: boolean = false;
  // 空格键长按计时器
  private spaceLongPressTimer: number | null = null;
  // 翻译回调ID
  private translateCallbackId: string = '';
  // 订阅ID
  private subscribeId: number = -1;

  // 键盘宽度（用于动态计算按键大小）
  private keyboardWidth: number = 360;
  // 按键高度
  private readonly KEY_HEIGHT: number = 42;
  // 行间距
  private readonly ROW_GAP: number = 6;

  /**
   * 组件即将显示
   */
  aboutToAppear() {
    hilog.info(0x0000, TAG, '键盘组件初始化');
    
    // 获取屏幕宽度
    try {
      const displayData = display.getDefaultDisplaySync();
      this.keyboardWidth = displayData.width / displayData.densityDPI * 160; // 转换为vp
    } catch (error) {
      hilog.error(0x0000, TAG, '获取屏幕尺寸失败: %{public}s', JSON.stringify(error));
    }
    
    // 订阅翻译响应事件
    this.subscribeTranslateResponse();
  }

  /**
   * 组件即将销毁
   */
  aboutToDisappear() {
    hilog.info(0x0000, TAG, '键盘组件销毁');
    this.unsubscribeEvents();
  }

  /**
   * 订阅翻译响应事件
   */
  private subscribeTranslateResponse(): void {
    hilog.info(0x0000, TAG, '订阅翻译响应事件');

    const subscribeOptions: commonEventManager.SubscribeOptions = {
      events: [TRANSLATE_RESPONSE_EVENT]
    };

    commonEventManager.subscribe(subscribeOptions, (err, data) => {
      if (err) {
        hilog.error(0x0000, TAG, '订阅翻译响应失败');
        return;
      }
      
      // 检查是否是当前请求的响应
      const responseData = data.parameters as ESObject;
      const requestId = responseData?.requestId as string;
      
      if (requestId === this.translateCallbackId) {
        this.handleTranslateResponse(responseData?.result as string);
      }
    }, (err, subscribeInfo) => {
      if (!err) {
        this.subscribeId = subscribeInfo.subscribeId;
      }
    });
  }

  /**
   * 处理翻译响应
   * @param resultStr 响应结果JSON字符串
   */
  private handleTranslateResponse(resultStr: string): void {
    hilog.info(0x0000, TAG, '收到翻译响应');
    
    try {
      const result: TranslateResult = JSON.parse(resultStr);
      
      if (result.success) {
        this.translateResult = result.translated;
        this.isTranslating = false;
        this.showTranslateResult = true;
        
        // 3秒后自动隐藏翻译结果
        setTimeout(() => {
          this.showTranslateResult = false;
        }, 3000);
      } else {
        this.translateResult = result.error || '翻译失败';
        this.isTranslating = false;
        this.showTranslateResult = true;
      }
    } catch (error) {
      hilog.error(0x0000, TAG, '解析翻译结果失败: %{public}s', JSON.stringify(error));
      this.isTranslating = false;
    }
  }

  /**
   * 取消事件订阅
   */
  private unsubscribeEvents(): void {
    if (this.subscribeId >= 0) {
      commonEventManager.unsubscribe(this.subscribeId, () => {
        hilog.info(0x0000, TAG, '取消订阅成功');
      });
    }
  }

  /**
   * 发送翻译请求
   */
  private sendTranslateRequest(): void {
    if (!this.currentText || this.currentText.trim() === '') {
      hilog.info(0x0000, TAG, '当前无输入文本');
      return;
    }

    hilog.info(0x0000, TAG, '发送翻译请求: %{public}s', this.currentText);
    
    this.isTranslating = true;
    this.translateCallbackId = `req_${Date.now()}`;
    
    const publishOptions: commonEventManager.PublishOptions = {
      parameters: {
        requestId: this.translateCallbackId,
        text: this.currentText,
        sourceLang: 'zh',
        targetLang: 'en'
      }
    };

    commonEventManager.publish(TRANSLATE_REQUEST_EVENT, publishOptions, (err) => {
      if (err) {
        hilog.error(0x0000, TAG, '发送翻译请求失败: %{public}s', JSON.stringify(err));
        this.isTranslating = false;
        this.translateResult = '请求失败';
        this.showTranslateResult = true;
      }
    });
  }

  /**
   * 空格键按下
   */
  private onSpaceKeyDown(): void {
    // 开始长按计时（500ms）
    this.spaceLongPressTimer = setTimeout(() => {
      hilog.info(0x0000, TAG, '空格键长按触发翻译');
      this.sendTranslateRequest();
    }, 500);
  }

  /**
   * 空格键抬起
   */
  private onSpaceKeyUp(): void {
    // 如果长按计时器还在，清除它
    if (this.spaceLongPressTimer !== null) {
      clearTimeout(this.spaceLongPressTimer);
      this.spaceLongPressTimer = null;
      
      // 发送普通空格
      this.insertText(' ');
    }
  }

  /**
   * 插入文本到输入框
   * @param text 要插入的文本
   */
  private insertText(text: string): void {
    hilog.info(0x0000, TAG, '插入文本: %{public}s', text);
    
    this.currentText += text;
    
    // 调用输入法引擎插入文本
    try {
      const inputMethodAbility = inputMethod.getController();
      inputMethodAbility.insertText(text);
    } catch (error) {
      hilog.error(0x0000, TAG, '插入文本失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 删除最后一个字符
   */
  private deleteBackward(): void {
    hilog.info(0x0000, TAG, '删除字符');
    
    if (this.currentText.length > 0) {
      this.currentText = this.currentText.slice(0, -1);
    }
    
    try {
      const inputMethodAbility = inputMethod.getController();
      inputMethodAbility.deleteBackward();
    } catch (error) {
      hilog.error(0x0000, TAG, '删除字符失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 切换键盘模式
   */
  private toggleMode(): void {
    hilog.info(0x0000, TAG, '切换键盘模式，当前: %{public}d', this.currentMode);
    
    if (this.currentMode === KeyboardMode.QWERTY_LOWER) {
      this.currentMode = KeyboardMode.QWERTY_UPPER;
    } else if (this.currentMode === KeyboardMode.QWERTY_UPPER) {
      this.currentMode = KeyboardMode.NUMERIC;
    } else if (this.currentMode === KeyboardMode.NUMERIC) {
      this.currentMode = KeyboardMode.SYMBOL;
    } else {
      this.currentMode = KeyboardMode.QWERTY_LOWER;
    }
  }

  /**
   * 切换大小写
   */
  private toggleCase(): void {
    if (this.currentMode === KeyboardMode.QWERTY_LOWER) {
      this.currentMode = KeyboardMode.QWERTY_UPPER;
    } else if (this.currentMode === KeyboardMode.QWERTY_UPPER) {
      this.currentMode = KeyboardMode.QWERTY_LOWER;
    }
  }

  /**
   * 获取字母按键数据
   */
  private getLetterKeys(): KeyData[][] {
    const rows: KeyData[][] = [];
    
    if (this.currentMode === KeyboardMode.QWERTY_LOWER) {
      rows.push([
        { label: 'q', value: 'q', type: 'letter' },
        { label: 'w', value: 'w', type: 'letter' },
        { label: 'e', value: 'e', type: 'letter' },
        { label: 'r', value: 'r', type: 'letter' },
        { label: 't', value: 't', type: 'letter' },
        { label: 'y', value: 'y', type: 'letter' },
        { label: 'u', value: 'u', type: 'letter' },
        { label: 'i', value: 'i', type: 'letter' },
        { label: 'o', value: 'o', type: 'letter' },
        { label: 'p', value: 'p', type: 'letter' }
      ]);
      rows.push([
        { label: 'a', value: 'a', type: 'letter' },
        { label: 's', value: 's', type: 'letter' },
        { label: 'd', value: 'd', type: 'letter' },
        { label: 'f', value: 'f', type: 'letter' },
        { label: 'g', value: 'g', type: 'letter' },
        { label: 'h', value: 'h', type: 'letter' },
        { label: 'j', value: 'j', type: 'letter' },
        { label: 'k', value: 'k', type: 'letter' },
        { label: 'l', value: 'l', type: 'letter' }
      ]);
      rows.push([
        { label: '⇧', value: 'shift', type: 'special', width: 1.5 },
        { label: 'z', value: 'z', type: 'letter' },
        { label: 'x', value: 'x', type: 'letter' },
        { label: 'c', value: 'c', type: 'letter' },
        { label: 'v', value: 'v', type: 'letter' },
        { label: 'b', value: 'b', type: 'letter' },
        { label: 'n', value: 'n', type: 'letter' },
        { label: 'm', value: 'm', type: 'letter' },
        { label: '⌫', value: 'backspace', type: 'special', width: 1.5 }
      ]);
    } else {
      // 大写模式
      rows.push([
        { label: 'Q', value: 'Q', type: 'letter' },
        { label: 'W', value: 'W', type: 'letter' },
        { label: 'E', value: 'E', type: 'letter' },
        { label: 'R', value: 'R', type: 'letter' },
        { label: 'T', value: 'T', type: 'letter' },
        { label: 'Y', value: 'Y', type: 'letter' },
        { label: 'U', value: 'U', type: 'letter' },
        { label: 'I', value: 'I', type: 'letter' },
        { label: 'O', value: 'O', type: 'letter' },
        { label: 'P', value: 'P', type: 'letter' }
      ]);
      rows.push([
        { label: 'A', value: 'A', type: 'letter' },
        { label: 'S', value: 'S', type: 'letter' },
        { label: 'D', value: 'D', type: 'letter' },
        { label: 'F', value: 'F', type: 'letter' },
        { label: 'G', value: 'G', type: 'letter' },
        { label: 'H', value: 'H', type: 'letter' },
        { label: 'J', value: 'J', type: 'letter' },
        { label: 'K', value: 'K', type: 'letter' },
        { label: 'L', value: 'L', type: 'letter' }
      ]);
      rows.push([
        { label: '⇪', value: 'capslock', type: 'special', width: 1.5 },
        { label: 'Z', value: 'Z', type: 'letter' },
        { label: 'X', value: 'X', type: 'letter' },
        { label: 'C', value: 'C', type: 'letter' },
        { label: 'V', value: 'V', type: 'letter' },
        { label: 'B', value: 'B', type: 'letter' },
        { label: 'N', value: 'N', type: 'letter' },
        { label: 'M', value: 'M', type: 'letter' },
        { label: '⌫', value: 'backspace', type: 'special', width: 1.5 }
      ]);
    }
    
    return rows;
  }

  /**
   * 获取数字按键数据
   */
  private getNumberKeys(): KeyData[][] {
    return [
      [
        { label: '1', value: '1', type: 'number' },
        { label: '2', value: '2', type: 'number' },
        { label: '3', value: '3', type: 'number' },
        { label: '4', value: '4', type: 'number' },
        { label: '5', value: '5', type: 'number' },
        { label: '6', value: '6', type: 'number' },
        { label: '7', value: '7', type: 'number' },
        { label: '8', value: '8', type: 'number' },
        { label: '9', value: '9', type: 'number' },
        { label: '0', value: '0', type: 'number' }
      ],
      [
        { label: '-', value: '-', type: 'symbol' },
        { label: '/', value: '/', type: 'symbol' },
        { label: ':', value: ':', type: 'symbol' },
        { label: ';', value: ';', type: 'symbol' },
        { label: '(', value: '(', type: 'symbol' },
        { label: ')', value: ')', type: 'symbol' },
        { label: '$', value: '$', type: 'symbol' },
        { label: '&', value: '&', type: 'symbol' },
        { label: '@', value: '@', type: 'symbol' },
        { label: '"', value: '"', type: 'symbol' }
      ],
      [
        { label: '#+=', value: 'symbol', type: 'special', width: 1.5 },
        { label: '.', value: '.', type: 'symbol' },
        { label: ',', value: ',', type: 'symbol' },
        { label: '?', value: '?', type: 'symbol' },
        { label: '!', value: '!', type: 'symbol' },
        { label: "'", value: "'", type: 'symbol' },
        { label: '⌫', value: 'backspace', type: 'special', width: 1.5 }
      ]
    ];
  }

  /**
   * 获取符号按键数据
   */
  private getSymbolKeys(): KeyData[][] {
    return [
      [
        { label: '[', value: '[', type: 'symbol' },
        { label: ']', value: ']', type: 'symbol' },
        { label: '{', value: '{', type: 'symbol' },
        { label: '}', value: '}', type: 'symbol' },
        { label: '#', value: '#', type: 'symbol' },
        { label: '%', value: '%', type: 'symbol' },
        { label: '^', value: '^', type: 'symbol' },
        { label: '*', value: '*', type: 'symbol' },
        { label: '+', value: '+', type: 'symbol' },
        { label: '=', value: '=', type: 'symbol' }
      ],
      [
        { label: '_', value: '_', type: 'symbol' },
        { label: '\\', value: '\\', type: 'symbol' },
        { label: '|', value: '|', type: 'symbol' },
        { label: '~', value: '~', type: 'symbol' },
        { label: '<', value: '<', type: 'symbol' },
        { label: '>', value: '>', type: 'symbol' },
        { label: '€', value: '€', type: 'symbol' },
        { label: '£', value: '£', type: 'symbol' },
        { label: '¥', value: '¥', type: 'symbol' },
        { label: '·', value: '·', type: 'symbol' }
      ],
      [
        { label: '123', value: 'number', type: 'special', width: 1.5 },
        { label: '!', value: '!', type: 'symbol' },
        { label: '/', value: '/', type: 'symbol' },
        { label: '?', value: '?', type: 'symbol' },
        { label: '😀', value: 'emoji', type: 'special' },
        { label: '⌫', value: 'backspace', type: 'special', width: 1.5 }
      ]
    ];
  }

  /**
   * 处理按键点击
   * @param key 按键数据
   */
  private onKeyClick(key: KeyData): void {
    hilog.info(0x0000, TAG, '按键点击: %{public}s', key.value);
    
    switch (key.value) {
      case 'shift':
        this.toggleCase();
        break;
      case 'capslock':
        this.toggleCase();
        break;
      case 'backspace':
        this.deleteBackward();
        break;
      case 'number':
        this.currentMode = KeyboardMode.NUMERIC;
        break;
      case 'symbol':
        this.currentMode = KeyboardMode.SYMBOL;
        break;
      case 'abc':
        this.currentMode = KeyboardMode.QWERTY_LOWER;
        break;
      case 'emoji':
        // PoC阶段不做emoji键盘
        this.insertText('😀');
        break;
      default:
        this.insertText(key.value);
        // 输入字母后自动切换回小写
        if (this.currentMode === KeyboardMode.QWERTY_UPPER) {
          this.currentMode = KeyboardMode.QWERTY_LOWER;
        }
    }
  }

  /**
   * 构建页面UI
   */
  build() {
    Column() {
      // 候选词栏
      Row() {
        ForEach(this.candidates, (candidate: string) => {
          Text(candidate)
            .fontSize(16)
            .fontColor('#333333')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => {
              this.currentText = candidate;
              this.insertText(candidate);
            });
        });
      }
      .width('100%')
      .height(40)
      .backgroundColor('#F0F0F0')
      .alignItems(VerticalAlign.Center);

      // 翻译结果显示区
      if (this.showTranslateResult) {
        Row() {
          if (this.isTranslating) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color('#1890FF');
            Text('翻译中...')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 8 });
          } else {
            Text(this.translateResult)
              .fontSize(14)
              .fontColor('#1890FF')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.insertText(this.translateResult);
                this.showTranslateResult = false;
              });
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor('#E6F7FF')
        .padding({ left: 12, right: 12 })
        .alignItems(VerticalAlign.Center);
      }

      // 键盘主体
      Column() {
        // 根据模式显示不同的按键布局
        if (this.currentMode === KeyboardMode.QWERTY_LOWER || this.currentMode === KeyboardMode.QWERTY_UPPER) {
          this.buildLetterKeyboard();
        } else if (this.currentMode === KeyboardMode.NUMERIC) {
          this.buildNumberKeyboard();
        } else {
          this.buildSymbolKeyboard();
        }

        // 底部功能键行
        this.buildBottomRow();
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 4, bottom: 4 });
    }
    .width('100%')
    .backgroundColor('#D1D5DB');
  }

  /**
   * 构建字母键盘
   */
  @Builder
  buildLetterKeyboard() {
    Column() {
      ForEach(this.getLetterKeys(), (row: KeyData[], rowIndex: number) => {
        Row() {
          ForEach(row, (key: KeyData) => {
            this.buildKey(key);
          });
        }
        .width('100%')
        .justifyContent(FlexAlign.Center);
      });
    }
  }

  /**
   * 构建数字键盘
   */
  @Builder
  buildNumberKeyboard() {
    Column() {
      ForEach(this.getNumberKeys(), (row: KeyData[], rowIndex: number) => {
        Row() {
          ForEach(row, (key: KeyData) => {
            this.buildKey(key);
          });
        }
        .width('100%')
        .justifyContent(FlexAlign.Center);
      });
    }
  }

  /**
   * 构建符号键盘
   */
  @Builder
  buildSymbolKeyboard() {
    Column() {
      ForEach(this.getSymbolKeys(), (row: KeyData[], rowIndex: number) => {
        Row() {
          ForEach(row, (key: KeyData) => {
            this.buildKey(key);
          });
        }
        .width('100%')
        .justifyContent(FlexAlign.Center);
      });
    }
  }

  /**
   * 构建底部功能键行
   */
  @Builder
  buildBottomRow() {
    Row() {
      // 切换到数字键盘
      Button('123')
        .fontSize(14)
        .fontColor('#333333')
        .backgroundColor('#AEB4BE')
        .borderRadius(5)
        .width(48)
        .height(this.KEY_HEIGHT)
        .onClick(() => {
          this.currentMode = KeyboardMode.NUMERIC;
        });

      // 中英文切换（PoC简化版）
      Button('中/英')
        .fontSize(14)
        .fontColor('#333333')
        .backgroundColor('#AEB4BE')
        .borderRadius(5)
        .width(48)
        .height(this.KEY_HEIGHT)
        .onClick(() => {
          hilog.info(0x0000, TAG, '切换中英文输入模式');
        });

      // 空格键（长按触发翻译）
      Row() {
        if (this.isTranslating) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#1890FF');
        } else {
          Text('空格')
            .fontSize(14)
            .fontColor('#333333')
            .fontStyle(FontStyle.Normal);
        }
      }
      .width('50%')
      .height(this.KEY_HEIGHT)
      .backgroundColor('#FFFFFF')
      .borderRadius(5)
      .justifyContent(FlexAlign.Center)
      .gesture(
        // 长按手势触发翻译
        LongPressGesture()
          .onAction(() => {
            hilog.info(0x0000, TAG, '空格键长按');
            this.sendTranslateRequest();
          })
      )
      .onTouch((event) => {
        if (event.type === TouchType.Down) {
          this.onSpaceKeyDown();
        } else if (event.type === TouchType.Up) {
          this.onSpaceKeyUp();
        }
      });

      // 回车键
      Button('⏎')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#1890FF')
        .borderRadius(5)
        .width(64)
        .height(this.KEY_HEIGHT)
        .onClick(() => {
          this.insertText('\n');
        });
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 4, right: 4, top: 4 });
  }

  /**
   * 构建单个按键
   * @param key 按键数据
   */
  @Builder
  buildKey(key: KeyData) {
    let keyWidth: Length = 32;
    
    if (key.width) {
      keyWidth = 32 * key.width + (key.width - 1) * 4;
    }

    Button(key.label)
      .fontSize(18)
      .fontColor('#333333')
      .backgroundColor(key.type === 'special' ? '#AEB4BE' : '#FFFFFF')
      .borderRadius(5)
      .width(keyWidth)
      .height(this.KEY_HEIGHT)
      .onClick(() => {
        this.onKeyClick(key);
      });
  }
}
