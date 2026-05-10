/**
 * 铭键输入法 - 翻译服务模块
 * 负责处理翻译请求，支持多种翻译API
 * 
 * 设计说明：
 * - 运行在主应用进程（有网络权限）
 * - 通过CommonEvent接收来自keyboard模块的翻译请求
 * - 通过CommonEvent返回翻译结果
 * 
 * PoC阶段使用模拟翻译，完整版将集成：
 * - 免费翻译API（如Google Translate API Free）
 * - 自建翻译服务
 * - 链上翻译Agent
 */

import http from '@ohos.net.http';
import hilog from '@hilog';

/**
 * 日志域ID
 */
const TAG = 'TranslateService';

/**
 * 翻译API配置
 * PoC阶段使用模拟数据，正式版替换为真实API
 */
const API_CONFIG = {
  // 免费翻译API示例（PoC阶段不使用）
  // baseUrl: 'https://api.mymemory.translated.net/get',
  // timeout: 5000,
  
  // PoC阶段使用模拟模式
  mockMode: true
};

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
 * 翻译服务类
 * 提供文本翻译能力
 */
export class TranslateService {
  // 服务是否已初始化
  private initialized: boolean = false;

  /**
   * 初始化翻译服务
   */
  init(): void {
    hilog.info(0x0000, TAG, '翻译服务初始化');
    this.initialized = true;
  }

  /**
   * 执行翻译
   * @param text 源文本
   * @param sourceLang 源语言代码 (如: 'zh', 'en')
   * @param targetLang 目标语言代码 (如: 'zh', 'en')
   * @returns 翻译结果
   */
  async translate(text: string, sourceLang: string, targetLang: string): Promise<TranslateResult> {
    hilog.info(0x0000, TAG, '收到翻译请求: %{public}s -> %{public}s, 文本: %{public}s', 
      sourceLang, targetLang, text);

    if (!this.initialized) {
      return {
        success: false,
        original: text,
        translated: '',
        sourceLang: sourceLang,
        targetLang: targetLang,
        error: '翻译服务未初始化'
      };
    }

    if (!text || text.trim() === '') {
      return {
        success: false,
        original: text,
        translated: '',
        sourceLang: sourceLang,
        targetLang: targetLang,
        error: '文本不能为空'
      };
    }

    // PoC阶段使用模拟翻译
    if (API_CONFIG.mockMode) {
      return this.mockTranslate(text, sourceLang, targetLang);
    }

    // 正式版调用真实API
    return this.callTranslateAPI(text, sourceLang, targetLang);
  }

  /**
   * 调用真实翻译API
   * 正式版实现
   * @param text 源文本
   * @param sourceLang 源语言
   * @param targetLang 目标语言
   */
  private async callTranslateAPI(text: string, sourceLang: string, targetLang: string): Promise<TranslateResult> {
    hilog.info(0x0000, TAG, '调用翻译API');

    try {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 构建请求URL（使用免费翻译API示例）
      const langPair = `${sourceLang}|${targetLang}`;
      const encodedText = encodeURIComponent(text);
      const url = `${API_CONFIG.baseUrl}?q=${encodedText}&langpair=${langPair}`;

      // 发起请求
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: API_CONFIG.timeout,
        readTimeout: API_CONFIG.timeout
      });

      // 解析响应
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        const translatedText = result?.responseData?.translatedText || text;
        
        return {
          success: true,
          original: text,
          translated: translatedText,
          sourceLang: sourceLang,
          targetLang: targetLang
        };
      } else {
        return {
          success: false,
          original: text,
          translated: '',
          sourceLang: sourceLang,
          targetLang: targetLang,
          error: `API请求失败: ${response.responseCode}`
        };
      }
    } catch (error) {
      hilog.error(0x0000, TAG, '翻译API调用失败: %{public}s', JSON.stringify(error));
      return {
        success: false,
        original: text,
        translated: '',
        sourceLang: sourceLang,
        targetLang: targetLang,
        error: `翻译失败: ${error}`
      };
    }
  }

  /**
   * 模拟翻译（PoC阶段使用）
   * @param text 源文本
   * @param sourceLang 源语言
   * @param targetLang 目标语言
   */
  private mockTranslate(text: string, sourceLang: string, targetLang: string): TranslateResult {
    hilog.info(0x0000, TAG, '使用模拟翻译');

    // 简单的中英对照词典
    const zhEnDict: Record<string, string> = {
      '你好': 'Hello',
      '您好': 'Hello',
      '世界': 'World',
      '铭键': 'MingKey',
      '输入法': 'Input Method',
      '翻译': 'Translation',
      '谢谢': 'Thank you',
      '谢谢你': 'Thank you',
      '再见': 'Goodbye',
      '明天见': 'See you tomorrow',
      '早上好': 'Good morning',
      '晚上好': 'Good evening',
      '下午好': 'Good afternoon',
      '我爱你': 'I love you',
      '很高兴认识你': 'Nice to meet you',
      '请问': 'May I ask',
      '对不起': 'Sorry',
      '没关系': "It's okay",
      '是的': 'Yes',
      '不是': 'No',
      '请': 'Please',
      '谢谢': 'Thanks',
      '不用谢': "You're welcome",
      '再见': 'Bye',
      '嗨': 'Hi',
      '嘿': 'Hey',
      '最近怎么样': 'How have you been lately',
      '最近好吗': 'How are you recently'
    };

    // 简单的英中对照词典
    const enZhDict: Record<string, string> = {
      'hello': '你好',
      'hi': '嗨',
      'hey': '嘿',
      'world': '世界',
      'thank you': '谢谢',
      'thanks': '谢谢',
      'goodbye': '再见',
      'bye': '再见',
      'good morning': '早上好',
      'good evening': '晚上好',
      'good afternoon': '下午好',
      'i love you': '我爱你',
      'yes': '是的',
      'no': '不是',
      'please': '请',
      'sorry': '对不起',
      'ok': '好的',
      'okay': '好的'
    };

    let translated: string;

    if (sourceLang === 'zh' && targetLang === 'en') {
      // 中文转英文
      if (zhEnDict[text]) {
        translated = zhEnDict[text];
      } else {
        // 尝试匹配包含关系
        translated = this.findBestMatch(text, zhEnDict) || `[EN] ${text}`;
      }
    } else if (sourceLang === 'en' && targetLang === 'zh') {
      // 英文转中文
      if (enZhDict[text.toLowerCase()]) {
        translated = enZhDict[text.toLowerCase()];
      } else {
        translated = this.findBestMatch(text.toLowerCase(), enZhDict) || `[中] ${text}`;
      }
    } else {
      // 其他语言对，返回原文
      translated = text;
    }

    return {
      success: true,
      original: text,
      translated: translated,
      sourceLang: sourceLang,
      targetLang: targetLang
    };
  }

  /**
   * 查找最佳匹配
   * @param text 输入文本
   * @param dict 词典
   */
  private findBestMatch(text: string, dict: Record<string, string>): string | null {
    // 简单的包含匹配
    for (const [key, value] of Object.entries(dict)) {
      if (text.includes(key)) {
        return value;
      }
    }
    return null;
  }
}
