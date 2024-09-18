import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

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
  late final WebViewController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    // Initialize the WebView controller and load the Vimeo player page
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'VideoState',
        onMessageReceived: (message) {
          if (message.message == 'play') {
            _enterFullScreen();
          } else if (message.message == 'pause' || message.message == 'ended') {
            _exitFullScreen();
          }
        },
      )
      ..loadRequest(_videoPage(widget.videoId));
  }

  @override
  void dispose() {
    _exitFullScreen(); // Ensure that we exit full-screen when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _exitFullScreen(); // Exit full-screen on back press
          return false; // Prevent the default back behavior
        }
        return true; // Allow normal back behavior
      },
      child: WebViewWidget(
        controller: _controller,
      ),
    );
  }

  /// Enter full-screen mode and rotate to landscape
  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });
    // Rotate to landscape and hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Exit full-screen mode and rotate back to portrait
  void _exitFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
    // Rotate back to portrait and show system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
              overflow: hidden;
            }
          </style>
          <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
          <meta http-equiv="Content-Security-Policy"
          content="default-src * gap:; script-src * 'unsafe-inline' 'unsafe-eval'; connect-src *;
          img-src * data: blob: android-webview-video-poster:; style-src * 'unsafe-inline';">
          <script src="https://player.vimeo.com/api/player.js"></script>
        </head>
        <body>
          <iframe 
          id="vimeoPlayer"
          src="https://player.vimeo.com/video/$videoId?loop=0&autoplay=0" 
          width="100%" height="100%" frameborder="0" allow="fullscreen" 
          allowfullscreen></iframe>
          <script>
            var iframe = document.getElementById('vimeoPlayer');
            var player = new Vimeo.Player(iframe);

            // Detect when the video starts playing
            player.on('play', function() {
              VideoState.postMessage('play');
            });

            // Detect when the video is paused or stopped
            player.on('pause', function() {
              VideoState.postMessage('pause');
            });

            player.on('ended', function() {
              VideoState.postMessage('pause');
            });
          </script>
        </body>
      </html>
    ''';
    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(html));
    return Uri.parse('data:text/html;base64,$contentBase64');
  }
}
