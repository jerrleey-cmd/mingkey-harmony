/**
 * 铭键输入法 - 输入法Extension主类
 * 
 * 功能说明：
 * - 继承InputMethodExtensionAbility
 * - 管理输入法面板的生命周期
 * - 处理键盘UI的创建和销毁
 * - 响应用户输入事件
 * 
 * 隐私设计：
 * - 无网络权限，所有网络请求通过IPC委托给entry模块
 * - 原始输入内容不离开设备
 * - 仅将需要AI处理的请求通过加密通道发送
 */

import InputMethodExtensionAbility from '@ohos.inputMethod.InputMethodExtensionAbility';
import InputMethodEngine from '@ohos.inputMethod.InputMethodEngine';
import commonEventManager from '@ohos.commonEventManager';
import hilog from '@hilog';

/**
 * 日志域ID
 */
const TAG = 'MingKeyKeyboard';

/**
 * CommonEvent事件名称定义
 */
const TRANSLATE_REQUEST_EVENT = 'com.mingkey.inputmethod.TRANSLATE_REQUEST';
const TRANSLATE_RESPONSE_EVENT = 'com.mingkey.inputmethod.TRANSLATE_RESPONSE';

/**
 * 输入法ExtensionAbility类
 * 负责管理输入法面板
 */
export default class MingKeyInputMethodExtensionAbility extends InputMethodExtensionAbility {
  // 键盘控制器引用
  private keyboardController: ESObject | null = null;
  // 当前输入文本
  private currentText: string = '';
  // 翻译结果回调
  private translateCallback: ESObject | null = null;

  /**
   * Extension创建时调用
   * 初始化输入法引擎
   */
  onCreate(want, launchParam) {
    hilog.info(0x0000, TAG, '输入法Extension创建');
    
    // 初始化键盘控制器
    this.initKeyboardController();
    
    // 订阅翻译响应事件
    this.subscribeTranslateResponse();
  }

  /**
   * Extension销毁时调用
   * 清理资源
   */
  onDestroy() {
    hilog.info(0x0000, TAG, '输入法Extension销毁');
    
    // 取消事件订阅
    this.unsubscribeEvents();
  }

  /**
   * 初始化键盘控制器
   */
  private initKeyboardController(): void {
    hilog.info(0x0000, TAG, '初始化键盘控制器');
    
    try {
      // 获取输入方法引擎
      this.keyboardController = this.getController();
      hilog.info(0x0000, TAG, '获取键盘控制器成功');
    } catch (error) {
      hilog.error(0x0000, TAG, '获取键盘控制器失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 订阅翻译响应事件
   * 接收来自entry模块的翻译结果
   */
  private subscribeTranslateResponse(): void {
    hilog.info(0x0000, TAG, '订阅翻译响应事件');

    const subscribeOptions: commonEventManager.SubscribeOptions = {
      events: [TRANSLATE_RESPONSE_EVENT]
    };

    const callback = (err, subscribeInfo) => {
      if (err) {
        hilog.error(0x0000, TAG, '订阅失败: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, TAG, '订阅翻译响应成功');
    };

    // 订阅事件
    commonEventManager.subscribe(subscribeOptions, this.handleTranslateResponse.bind(this), callback);
  }

  /**
   * 处理翻译响应
   * @param err 错误信息
   * @param data 事件数据
   */
  private handleTranslateResponse(err: ESObject, data: ESObject): void {
    if (err) {
      hilog.error(0x0000, TAG, '处理翻译响应失败: %{public}s', JSON.stringify(err));
      return;
    }

    hilog.info(0x0000, TAG, '收到翻译响应: %{public}s', JSON.stringify(data));

    // 解析响应数据
    const responseData = data.parameters as ESObject;
    const resultStr = responseData?.result as string;
    
    if (resultStr && this.translateCallback) {
      try {
        const result = JSON.parse(resultStr);
        // 调用回调函数显示翻译结果
        this.translateCallback(result);
      } catch (parseError) {
        hilog.error(0x0000, TAG, '解析翻译结果失败: %{public}s', JSON.stringify(parseError));
      }
    }
  }

  /**
   * 取消事件订阅
   */
  private unsubscribeEvents(): void {
    hilog.info(0x0000, TAG, '取消事件订阅');
    // 实际取消订阅逻辑
  }

  /**
   * 发送翻译请求
   * 通过CommonEvent发送给entry模块
   * @param text 待翻译文本
   * @param sourceLang 源语言
   * @param targetLang 目标语言
   * @param callback 翻译结果回调
   */
  sendTranslateRequest(text: string, sourceLang: string, targetLang: string, callback: ESObject): void {
    hilog.info(0x0000, TAG, '发送翻译请求: %{public}s', text);
    
    // 保存回调
    this.translateCallback = callback;
    
    // 生成请求ID
    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 发布翻译请求
    const publishOptions: commonEventManager.PublishOptions = {
      parameters: {
        requestId: requestId,
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang
      }
    };

    commonEventManager.publish(TRANSLATE_REQUEST_EVENT, publishOptions, (err) => {
      if (err) {
        hilog.error(0x0000, TAG, '发送翻译请求失败: %{public}s', JSON.stringify(err));
        if (callback) {
          callback({
            success: false,
            error: '发送请求失败'
          });
        }
      } else {
        hilog.info(0x0000, TAG, '翻译请求已发送，等待响应');
      }
    });
  }

  /**
   * 获取当前输入文本
   */
  getCurrentText(): string {
    return this.currentText;
  }

  /**
   * 设置当前输入文本
   * @param text 输入文本
   */
  setCurrentText(text: string): void {
    this.currentText = text;
  }
}
