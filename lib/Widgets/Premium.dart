
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:provider/provider.dart';
import 'Providers/UserState.dart';
import 'Shared/MSnackBar.dart';

class Premium extends StatelessWidget {
  purchaseButtonClick() async {
    final bool available = await InAppPurchase.instance.isAvailable();

    if (!available) {
      MSnackBar.showSnackBar("Not available now. Please try later", false);

      return;
    }

    const Set<String> _kIds = {'premium_purchase'};
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      MSnackBar.showSnackBar("Not available now. Please try later.", false);

      return;
    }

    ProductDetails product = response.productDetails.first;

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey globalKey = new GlobalKey();

    if (ModalRoute.of(context)!.isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

    final userState = Provider.of<UserState>(context);

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Premium',
          style: Theme.of(context).textTheme.headlineSmall,
        )
      ],
    );

    final titleText = Text(
      'Thanks for your interest in MovieDiary!',
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Theme.of(context).indicatorColor,
          fontSize: 20,
          fontWeight: FontWeight.bold),
    );

    final subTitleText = Text(
      'If you like MovieDiary you can support the project by unlocking the Premium features:',
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Theme.of(context).hintColor,
          fontSize: 18,
          fontWeight: FontWeight.bold),
    );

    final themeFeature = Column(
      children: <Widget>[
        Icon(
          FontAwesome5.paint_brush,
          color: Theme.of(context).indicatorColor,
          size: 40,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'Changing themes',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).indicatorColor,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        )
      ],
    );

    final supportFeature = Column(
      children: <Widget>[
        Icon(
          FontAwesome5.hands_helping,
          color: Theme.of(context).indicatorColor,
          size: 40,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'Support MovieDiary Team',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).indicatorColor,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        )
      ],
    );

    final removeAdFeature = Column(
      children: <Widget>[
        Icon(
          FontAwesome5.ad,
          color: Theme.of(context).indicatorColor,
          size: 40,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'Remove Ads',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).indicatorColor,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        )
      ],
    );

    return Scaffold(
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(AdManager.premiumBannerAd!),
                ),
                automaticallyImplyLeading: false,
                elevation: 0.7,
              )
            : PreferredSize(preferredSize: Size(0, 0), child: Container()),
        body: Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          appBar: AppBar(
            title: headingField,
          ),
          body: Container(
            key: globalKey,
            child: SingleChildScrollView(
              child: Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  color: Theme.of(context).primaryColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      titleText,
                      SizedBox(
                        height: 20,
                      ),
                      subTitleText,
                      SizedBox(
                        height: 20,
                      ),
                      removeAdFeature,
                      SizedBox(
                        height: 20,
                      ),
                      themeFeature,
                      SizedBox(
                        height: 20,
                      ),
                      supportFeature,
                    ],
                  )),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
              color: Theme.of(context).primaryColor,
              child: Container(
                margin: EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: MButton(
                  onPressedCallback: () => purchaseButtonClick(),
                  prependIconColor: userState.isPremium
                      ? Colors.green.withOpacity(0.4)
                      : Colors.green,
                  prependIcon:
                      userState.isPremium ? Icons.check : Icons.monetization_on,
                  height: 50,
                  borderRadius: 25,
                  text: 'Unlock Premium Features',
                  active: !userState.isPremium,
                ),
              )),
        ));
  }
}
