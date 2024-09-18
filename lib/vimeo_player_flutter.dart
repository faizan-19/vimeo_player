library vimeo_player_flutter;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart'; // For screen orientation control

/// Vimeo player for Flutter apps
/// Flutter plugin based on the [webview_flutter] plugin
/// [videoId] is the only required field to use this plugin
class VimeoPlayer extends StatefulWidget {
  const VimeoPlayer({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  final String videoId;

  @override
  State<VimeoPlayer> createState() => _VimeoPlayerState();
}

class _VimeoPlayerState extends State<VimeoPlayer> {
  final _controller = WebViewController();

  @override
  void initState() {
    super.initState();

    // Load the Vimeo video when the player is initialized
    _controller
      ..loadRequest(_videoPage(widget.videoId))
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    // Set the screen orientation to landscape when the video starts playing
    _rotateScreenToLandscape();
  }

  @override
  void dispose() {
    // Set the screen orientation back to portrait when the video ends or the player is disposed
    _rotateScreenToPortrait();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
    );
  }

  /// Rotate the screen to landscape mode
  void _rotateScreenToLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Rotate the screen back to portrait mode
  void _rotateScreenToPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Web page containing iframe of the Vimeo video
  Uri _videoPage(String videoId) {
    final html = '''
      <html>
        <head>
          <style>
            body {
              background-color: black;
              margin: 0px;
            }
          </style>
          <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
          <meta http-equiv="Content-Security-Policy"
          content="default-src * gap:; script-src * 'unsafe-inline' 'unsafe-eval'; connect-src *;
          img-src * data: blob: android-webview-video-poster:; style-src * 'unsafe-inline';">
        </head>
        <body>
          <iframe 
          src="https://player.vimeo.com/video/$videoId?loop=0&autoplay=0" 
          width="100%" height="100%" frameborder="0" allow="fullscreen" 
          allowfullscreen></iframe>
        </body>
      </html>
    ''';
    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(html));
    return Uri.parse('data:text/html;base64,$contentBase64');
  }
}
