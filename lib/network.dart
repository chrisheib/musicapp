import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:musicapp/main.dart';

enum ConnectionStatus {
  none,
  mobile,
  wlan,
}

DateTime? lastOfflineTimestamp;

Future<ConnectionStatus> getConnectionStatus() async {
  // if check within last 30 seconds failed, return none early to improve
  // responsibility
  if (lastOfflineTimestamp != null &&
      DateTime.now().difference(lastOfflineTimestamp!) <
          const Duration(seconds: 30)) {
    logger.info(
        "Connectivity: last failed connection was less then 30 secs ago, return none.");
    return ConnectionStatus.none;
  }

  var connectivityResult = await (Connectivity().checkConnectivity());
  ConnectionStatus out;

  if (connectivityResult == ConnectivityResult.mobile) {
    out = ConnectionStatus.mobile;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    out = ConnectionStatus.wlan;
  } else if (connectivityResult == ConnectivityResult.ethernet) {
    out = ConnectionStatus.wlan;
  } else if (connectivityResult == ConnectivityResult.bluetooth) {
    out = ConnectionStatus.mobile;
  } else {
    out = ConnectionStatus.none;
  }

  if (out != ConnectionStatus.none) {
    var response = await http.get(Uri.parse('https://music.stschiff.de/ping'));
    if (response.statusCode != 200 || response.body != "pong") {
      out = ConnectionStatus.none;
    }
  }

  if (out == ConnectionStatus.none) {
    lastOfflineTimestamp = DateTime.now();
  } else {
    lastOfflineTimestamp = null;
  }

  logger.info("Connectivity Result: $connectivityResult, Connection Status: $out");
  return out;
}

Future<bool> isConnected() async {
  var status = await getConnectionStatus();
  return status != ConnectionStatus.none;
}

Future<bool> isUsingFastConnection() async {
  var status = await getConnectionStatus();
  return status == ConnectionStatus.wlan;
}
