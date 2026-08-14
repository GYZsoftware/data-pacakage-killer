/**
 * 链接大全页面 - 提供可用于流量消耗器的下载链接
 */

import router from '@ohos.router';

interface LinkItem {
  name: string;
  url: string;
  description: string;
}

@Entry
@Component
struct LinksPage {
  private links: LinkItem[] = [
    {
      name: '哔哩哔哩',
      url: 'https://s1.hdslb.com/bfs/game-static/web/caster/static/script/vue/da3f37d7fd8339357ed671a94941757e/st.zip',
      description: 'B站静态资源包'
    },
    {
      name: '腾讯 WeGame',
      url: 'https://wegame.gtimg.com/g.55555-r.c4663/wegame-home/sc02-03.514d7db8.png',
      description: '腾讯WeGame图片资源'
    },
    {
      name: '腾讯视频',
      url: 'https://vm.gtimg.cn/thumbplayer/superplayer/1.35.4/superplayer.js',
      description: '腾讯视频播放器脚本'
    },
    {
      name: '爱奇艺',
      url: 'https://static.iqiyi.com/js/player_v3/pcweb.wonder.12.92.online.js',
      description: '爱奇艺播放器脚本'
    },
    {
      name: '阿里云',
      url: 'https://gw.alicdn.com/tfscom/TB1fASCxhjaK1RjSZKzXXXVwXXa.jpg',
      description: '阿里云CDN资源文件'
    }
  ];

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

        Text('链接大全')
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

      // 说明文字
      Text('点击右侧「使用」按钮，自动填入首页')
        .fontSize(13)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 链接列表
      List({ space: 12 }) {
        ForEach(this.links, (item: LinkItem, index: number) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ bottom: 4 })

                Text(item.description)
                  .fontSize(13)
                  .fontColor($r('app.color.text_tertiary'))
              }
              .layoutWeight(1)
              .margin({ right: 12 })

              Button('使用')
                .width(72)
                .height(36)
                .type(ButtonType.Capsule)
                .backgroundColor($r('app.color.accent_blue'))
                .fontSize(14)
                .onClick((): void => {
                  AppStorage.SetOrCreate('selectedLinkUrl', item.url);
                  router.back();
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding(16)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(12)
          }
        }, (item: LinkItem): string => item.url)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}