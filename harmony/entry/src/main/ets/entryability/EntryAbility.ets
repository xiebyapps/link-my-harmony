import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import hilog from '@ohos.hilog';
import { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { captureSharedUrlFromWant } from '../common/ShareIntent';

const DOMAIN = 0x0001;
const TAG = 'Folio';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want): void {
    hilog.info(DOMAIN, TAG, 'onCreate action=%{public}s uri=%{public}s', want?.action ?? '', want?.uri ?? '');
    const url = captureSharedUrlFromWant(want);
    if (url.length > 0) {
      hilog.info(DOMAIN, TAG, 'Captured shared URL in onCreate: %{public}s', url);
    } else {
      hilog.info(DOMAIN, TAG, 'No shared URL extracted in onCreate');
    }
    this.syncSystemColorMode(this.context?.config?.colorMode);
  }

  onNewWant(want: Want): void {
    hilog.info(DOMAIN, TAG, 'onNewWant action=%{public}s uri=%{public}s', want?.action ?? '', want?.uri ?? '');
    const url = captureSharedUrlFromWant(want);
    if (url.length > 0) {
      hilog.info(DOMAIN, TAG, 'Captured shared URL in onNewWant: %{public}s', url);
    } else {
      hilog.info(DOMAIN, TAG, 'No shared URL extracted in onNewWant');
    }
  }

  onConfigurationUpdate(config: Configuration): void {
    this.syncSystemColorMode(config.colorMode);
  }

  onForeground(): void {
    this.syncSystemColorMode(this.context?.config?.colorMode);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      const mainWin = windowStage.getMainWindowSync();
      mainWin.setWindowLayoutFullScreen(true);

      mainWin.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          const h = px2vp(data.area.topRect.height);
          AppStorage.setOrCreate<number>('safeAreaTop', h > 0 ? h : 44);
        }
      });

      const avoidArea = mainWin.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const topH = px2vp(avoidArea.topRect.height);
      AppStorage.setOrCreate<number>('safeAreaTop', topH > 0 ? topH : 44);
    } catch (e) {
      AppStorage.setOrCreate<number>('safeAreaTop', 44);
    }
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load page: %{public}s', JSON.stringify(err));
      }
    });
  }

  private syncSystemColorMode(colorMode: ConfigurationConstant.ColorMode | undefined): void {
    const isDark = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate<boolean>('deviceDarkMode', isDark);
  }
}
