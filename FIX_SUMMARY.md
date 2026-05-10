# MingKey HarmonyOS - GitHub Actions CI Fix

## 修复内容

### EntryAbility.ets 修复
1. **Line 14**: `@hilog` → `@ohos.hilog` - 修正模块导入路径
2. **Line 43**: 添加 `Want` 和 `AbilityConstant.LaunchParam` 类型注解
3. **Line 102**: `SubscribeOptions` → `CommonEventSubscribeInfo` - 修正API类型
4. **Line 116**: 移除多余的callback参数，`subscribe()` 只接受2个参数
5. **Line 124**: `handleTranslateRequest` 使用 `CommonEventData` 类型
6. **Line 133**: 使用 `Record<string, Object>` 替代 `ESObject`
7. **Line 142, 147**: 使用显式类型 `TranslateResultData` 和 `Error`
8. **Line 167**: `PublishOptions` → `CommonEventPublishData` - 修正API类型
9. **Line 221**: Promise 显式指定泛型类型 `Promise<TranslateResultData>`
10. 添加接口定义：`TranslateRequestData`, `TranslateResultData`

### Index.ets 修复
1. **Line 13**: `@hilog` → `@ohos.hilog` - 修正模块导入路径
2. **Line 65**: `PublishOptions` → `CommonEventPublishData` - 修正API类型
3. **Line 66**: 对象字面量使用 `CommonEventPublishData` 接口
4. 添加接口定义：`TranslatePublishData`

## ArkTS 规范遵循
- 禁止使用 `any`/`unknown` 类型
- 对象字面量必须对应声明的 interface/class
- 泛型函数必须显式指定类型参数
- 使用 HarmonyOS API 12+ 标准导入路径
