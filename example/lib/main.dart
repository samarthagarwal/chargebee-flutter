import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:chargebee_flutter/chargebee_flutter.dart';
import 'package:chargebee_flutter_sdk_example/product_listview.dart';
import 'package:chargebee_flutter_sdk_example/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Constants.dart';
import 'alertDialog.dart';
import 'package:chargebee_flutter/src/utils/product.dart';

import 'product_listview.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(Constants.menu, title: 'Chargebee-Flutter SDK'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<String> cbMenu;

  const MyHomePage(this.cbMenu, {Key? key, required this.title})
      : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(cbMenu);
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState(this.cbMenu);

  late List<String> cbMenu;

  List<Product> cbProductList = [];
  List<Product> products = [];

  final TextEditingController siteNameController = TextEditingController();
  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController sdkKeyController = TextEditingController();
  late String siteNameText, apiKeyText, sdkKeyText;

  final TextEditingController productIdTextFieldController =
      TextEditingController();
  late String productIDs;
  late Map<String, String> queryParams = {"channel": "app_store"};
  late String userInput;
  late ProgressBarUtil mProgressBarUtil;

  @override
  void initState() {
    // For both iOS and Android
    authentication("your-site", "publishable_api_key", "ResourceID/SDK Key");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mProgressBarUtil = ProgressBarUtil(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chargebee- Flutter SDK Example"),
      ),
      body: ListView.builder(
        itemCount: cbMenu.length,
        itemBuilder: (context, pos) {
          return Card(
            child: ListTile(
              title: Text(cbMenu[pos]),
              onTap: () {
                onItemClick(cbMenu[pos]);
              },
            ),
          );
        },
      ),
    );
  }

  onItemClick(String menuItem) {
    switch (menuItem) {
      case Constants.config:
        showAuthenticationDialog(context);
        break;

      case Constants.getProducts:
        showSkProductDialog(context);
        break;

      case Constants.getSubscriptionStatus:
        showSubscriptionDialog(context);
        break;

      default:
        break;
    }
  }

  Future<void> authentication(String siteName, String apiKey, String sdkKey,
      [String? packageName = ""]) async {
    try {
      await Chargebee.configure(siteName, apiKey, sdkKey, packageName);
    } on PlatformException catch (e) {
      log('PlatformException : ${e.message}');
    }
  }

  Future<void> getProductIdList(List<String> productIDsList) async {
    try {
      cbProductList = await Chargebee.retrieveProducts(productIDsList);
      log('result : $cbProductList');

      if (mProgressBarUtil.isProgressBarShowing()) {
        mProgressBarUtil.hideProgressDialog();
      }
      if (cbProductList.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => ProductListView(cbProductList,
                  title: 'Google Play-Product List'),
            ));
      } else {
        log('Items not avilable to buy');
        _showDialog(context, "Items not avilable to buy");
      }
    } catch (e) {
      log('Exception : ${e.toString()}');
      if (mProgressBarUtil.isProgressBarShowing()) {
        mProgressBarUtil.hideProgressDialog();
      }
    }
  }

  _showDialog(BuildContext context, String message) {
    BaseAlertDialog alert = BaseAlertDialog("Chargebee", message);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showSkProductDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Please enter Product Ids(Comma separated)'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  productIDs = value.trim();
                });
              },
              controller: productIdTextFieldController,
              decoration: const InputDecoration(hintText: "Product ID's"),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Colors.red,
                    textStyle:
                    const TextStyle(fontStyle: FontStyle.normal)),
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Colors.green,
                    textStyle:
                    const TextStyle(fontStyle: FontStyle.normal)),

                child: Text('OK'),
                onPressed: () {
                  setState(() {
                    try {
                      Navigator.pop(context);
                      log('productIDs with comma from user : $productIDs');
                      mProgressBarUtil.showProgressDialog();

                      List<String> listItems = productIDs.split(',');
                      getProductIdList(listItems);
                      productIdTextFieldController.clear();
                    } catch (e) {
                      log('error : ${e.toString()}');
                    }
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> showSubscriptionDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Please enter the queryParameters'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  userInput = value;
                });
              },
              controller: productIdTextFieldController,
              decoration: const InputDecoration(hintText: "Key value pair"),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Colors.red,
                    textStyle:
                    const TextStyle(fontStyle: FontStyle.normal)),
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Colors.green,
                    textStyle:
                    const TextStyle(fontStyle: FontStyle.normal)),
                child: Text('OK'),
                onPressed: () {
                  setState(() {
                    try {
                      Navigator.pop(context);
                      log('QueryParam from user : $queryParams');
                      mProgressBarUtil.showProgressDialog();
                      //Sample queryParam "channel":"app_store", "customer_id":"1234"
                      Map<String, dynamic> queryMap = jsonDecode(userInput.toString().trim());
                      log('queryMap : $queryMap');

                      retrieveSubscriptions(queryMap);
                      productIdTextFieldController.clear();
                    } catch (e) {
                      log('error : ${e.toString()}');
                    }
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> retrieveSubscriptions(Map<String, dynamic> queryparam) async {
    try {
      final result = await Chargebee.retrieveSubscriptions(queryparam);
      log('result : $result');

      if (mProgressBarUtil.isProgressBarShowing()) {
        mProgressBarUtil.hideProgressDialog();
      }
      if (result.length > 0) {
        _showDialog(context, "Subscriptions retrieved successfully!");
      } else {
        log('Subscription not found in Chargebee System');
        _showDialog(context, "Subscription not found in Chargebee System");
      }
    } catch (e) {
      log('Exception : ${e.toString()}');
      if (mProgressBarUtil.isProgressBarShowing()) {
        mProgressBarUtil.hideProgressDialog();
      }
    }
  }

  Future<void> showAuthenticationDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Chargebee'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    setState(() {
                      siteNameText = value;
                    });
                  },
                  controller: siteNameController,
                  decoration: const InputDecoration(hintText: "Site Name"),
                ),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      apiKeyText = value;
                    });
                  },
                  controller: apiKeyController,
                  decoration: const InputDecoration(hintText: "API Key"),
                ),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      sdkKeyText = value;
                    });
                  },
                  controller: sdkKeyController,
                  decoration: const InputDecoration(hintText: "SDK Key"),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Colors.red,
                    textStyle:
                    const TextStyle(fontStyle: FontStyle.normal)),
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Colors.green,
                    textStyle:
                    const TextStyle(fontStyle: FontStyle.normal)),
                child: const Text('Initialize'),
                onPressed: () {
                  Navigator.pop(context);
                  log('app details : $siteNameText, $apiKeyText, $sdkKeyText');
                  authentication(siteNameText, apiKeyText, sdkKeyText);
                  //});
                },
              ),
            ],
          );
        });
  }
}
