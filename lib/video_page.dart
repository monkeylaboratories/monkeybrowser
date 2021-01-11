import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoPage extends StatefulWidget {
  @override
  VideoPageState createState() => VideoPageState();
}

class VideoPageState extends State<VideoPage> {
  WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    // 遷移元よりURLを取得
    final String movieUrl = ModalRoute.of(context).settings.arguments;
    print("Request URL:" + movieUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Good Choice Σd(T□T)",
          style: GoogleFonts.mPlus1p(),
        ),
      ),
      body: WebView(
        initialUrl: movieUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController controller) {
          _controller = controller;
        },
      ),
    );
  }
}