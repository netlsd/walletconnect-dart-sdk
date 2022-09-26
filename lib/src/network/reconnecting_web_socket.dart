import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnSocketOpen = void Function(bool reconnectAttempt);
typedef OnSocketClose = void Function();
typedef OnMessage = void Function(dynamic data);
typedef OnQueueSubscriptions = void Function();

class ReconnectingWebSocket {
  /// The URL as resolved by the constructor.
  /// This is always an absolute URL. Read only.
  final String url;

  /// The maximum number of reconnection attempts to make. Unlimited if null.
  final int? maxReconnectAttempts;

  /// Whether this instance should log debug messages.
  final bool debug;

  /// The number of attempted reconnects since starting, or the last successful
  /// connection. Read only.
  int _reconnectAttempts = 0;

  /// Whether the websocket is currently connected.
  bool _connected = false;

  /// Whether the app should try reconnecting.
  bool _reconnecting = false;

  /// Whether the app should try to reconnect
  bool _shouldReconnect = true;

  WebSocketChannel? _channel;

  StreamSubscription? _subscription;

  StreamSubscription? _reconnectSubscription;

  OnSocketOpen? onOpen;

  OnSocketClose? onClose;

  OnMessage? onMessage;

  OnQueueSubscriptions? onQueueSubscriptions;

  ReconnectingWebSocket({
    required this.url,
    this.maxReconnectAttempts,
    this.debug = false,
    this.onOpen,
    this.onClose,
    this.onMessage,
    this.onQueueSubscriptions,
  });

  void open(bool reconnectAttempt) {
    final maxReconnectAttempts = this.maxReconnectAttempts;
    if (reconnectAttempt) {
      if (maxReconnectAttempts != null &&
          _reconnectAttempts > maxReconnectAttempts) {
        return;
      }
    } else {
      _reconnectAttempts = 0;
    }

    if (debug) {
      print('attempt-connect');
    }

    // TODO migrate to IOWebSocketChannel? -> WebSocketChannel does not have
    // TODO a way to flag for ready/connection states
    // https://github.com/dart-lang/web_socket_channel/issues/25
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _onOpen(reconnectAttempt);

    // Listen for messages
    _subscription = _channel?.stream.listen(
      _onMessage,
      onError: (error) {
        _onClose();
      },
      onDone: _onClose,
    );
  }

  /// Send data on the WebSocket.
  bool send(dynamic data) {
    if (!connected) {
      return false;
    }

    try {
      _channel?.sink.add(data);
      return true;
    } catch (ex) {
      return false;
    }
  }

  /// Closes the web socket connection.
  Future close({bool forceClose = false}) async {
    _shouldReconnect = !forceClose;
    return _channel?.sink.close();
  }

  /// Check if the socket is currently connected.
  bool get connected => _connected;

  void _onOpen(bool reconnectAttempt) {
    _connected = true;
    _shouldReconnect = true;
    onOpen?.call(reconnectAttempt);
    onQueueSubscriptions?.call();
  }

  void _onClose() {
    onClose?.call();

    if (_reconnecting) {
      return;
    }

    _connected = false;

    if (!_shouldReconnect) {
      return;
    }

    _reconnecting = true;

    final duration = const Duration(seconds: 10);

    if (debug) {
      print('Reconnecting in: ${duration.inMilliseconds}');
    }

    _reconnectSubscription?.cancel();
    _reconnectSubscription =
        Future.delayed(duration).asStream().listen((event) {
      _subscription?.cancel();
      _reconnectAttempts++;
      _reconnecting = false;
      open(true);
    });
  }

  void _onMessage(event) {
    _reconnectAttempts = 0;
    onMessage?.call(event);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
