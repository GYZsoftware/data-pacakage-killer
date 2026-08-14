/**
 * 关于页面 - 应用信息与联系方式
 */

import router from '@ohos.router';
import { Want, common } from '@kit.AbilityKit';

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor($r('app.color.accent_blue'))
          .padding({ left: 8, right: 16, top: 8, bottom: 8 })
          .onClick((): void => {
            router.back();
          })

        Text('关于')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 56 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .backgroundColor($r('app.color.card_background'))

      // 内容区域
      Scroll() {
        Column() {
          // 应用图标和名称
          Column() {
            Text('流量消耗器')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 6 })

            Text('Traffic Consumer v1.0.0')
              .fontSize(14)
              .fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .padding({ top: 32, bottom: 24 })
          .alignItems(HorizontalAlign.Center)

          // 应用说明
          Text('网络流量测试工具 — 通过并发HTTP下载持续消耗流量，支持自定义链接、流量限额、实时网速计量与自动重连。')
            .fontSize(14)
            .fontColor($r('app.color.text_body'))
            .lineHeight(22)
            .width('100%')
            .margin({ bottom: 24 })

          // 分隔线
          Divider()
            .width('100%')
            .color($r('app.color.progress_bg'))
            .margin({ bottom: 20 })

          // 作者介绍
          Text('作者介绍')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ bottom: 12 })

          Text('kut，一个略懂点信息技术的初中历史教师。这个作品是作者初试AI辅助编程（vibe coding）后的第二个作品……')
            .fontSize(14)
            .fontColor($r('app.color.text_body'))
            .lineHeight(22)
            .width('100%')
            .margin({ bottom: 24 })

          // 分隔线
          Divider()
            .width('100%')
            .color($r('app.color.progress_bg'))
            .margin({ bottom: 20 })

          // 联系方式
          Text('联系方式')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ bottom: 12 })

          // 邮箱
          Row() {
            Text('📧')
              .fontSize(16)
              .margin({ right: 10 })

            Text('kut@kut.hn.cn')
              .fontSize(14)
              .fontColor($r('app.color.accent_blue'))
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .onClick((): void => {
            let want: Want = {
              uri: 'mailto:kut@kut.hn.cn'
            };
            try {
              (getContext() as common.UIAbilityContext).startAbility(want);
            } catch (_) {}
          })

          // 分隔线
          Divider()
            .width('100%')
            .color($r('app.color.progress_bg'))
            .margin({ top: 4, bottom: 12 })

          // 开源主页
          Text('开源主页')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ bottom: 12 })

          // GitHub
          Row() {
            Text('🌐')
              .fontSize(16)
              .margin({ right: 10 })

            Column() {
              Text('GitHub')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))

              Text('https://github.com/GYZsoftware')
                .fontSize(12)
                .fontColor($r('app.color.accent_blue'))
                .fontFamily('monospace')
            }
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .onClick((): void => {
            let want: Want = {
              uri: 'https://github.com/GYZsoftware'
            };
            try {
              (getContext() as common.UIAbilityContext).startAbility(want);
            } catch (_) {}
          })

          // Gitee
          Row() {
            Text('🌐')
              .fontSize(16)
              .margin({ right: 10 })

            Column() {
              Text('Gitee')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))

              Text('https://gitee.com/kut2005503')
                .fontSize(12)
                .fontColor($r('app.color.accent_blue'))
                .fontFamily('monospace')
            }
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .onClick((): void => {
            let want: Want = {
              uri: 'https://gitee.com/kut2005503'
            };
            try {
              (getContext() as common.UIAbilityContext).startAbility(want);
            } catch (_) {}
          })
        }
        .width('92%')
        .margin({ top: 8, bottom: 24 })
      }
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}