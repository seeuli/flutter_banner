# flutter_banner

A Flutter banner widget, only build once after created.

## Getting Started
### 1、add dependency to you `pubspec.yaml`
```
    flutter_banner: ^1.1.0
```

### 2、user guide, see `example/example_main.dart` 
```
    import 'package:flutter_banner/banner_widget.dart'

    BannerWidget banner = BannerWidget(
        delegate: BannerDelegate(
            childAtIndex: (idx) => Container(),
            numberOfBanners: 5,
        ),
        pageIndicator: PageIndicator(),
    );
    banner.delegate.numberOfBanners.value = data.length;
    banner.pageIndicator.numberOfPages.value = data.length;

    return Container(
        child: banner,
        width: 200,
        height: 80,
    );
```

#### `PageIndicator` style
#### ①Replace PageIndicator default style
```
    PageIndicator.normalIndicatorStyle = IndicatorStyle(Size(), BoxDecoration());
    PageIndicator.selectedIndicatorStyle = IndicatorStyle(Size(), BoxDecoration());
```
#### ②Custom `PageIndicator` style
```
    static Widget indicatorBuilder() {
        return Container();
    }

    static Widget selectedIndicatorBuilder() {
        return Container();
    }
    PageIndicator(indicatorBuilder: indicatorBuilder, selectedIndicatorBuilder: selectedIndicatorBuilder,);
```

### 3、support autoloop，user draging