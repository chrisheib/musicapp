import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionStatus {
  none,
  mobile,
  wlan,
}

Future<ConnectionStatus> getConnectionStatus() async {
  String cType = "none";
  var connectivityResult = await (Connectivity().checkConnectivity());
  ConnectionStatus out;

  if (connectivityResult == ConnectivityResult.mobile) {
    cType = "Mobile Data";
    out = ConnectionStatus.mobile;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    cType = "Wifi Network";
    out = ConnectionStatus.wlan;
  } else if (connectivityResult == ConnectivityResult.ethernet) {
    cType = "Ethernet Network";
    out = ConnectionStatus.wlan;
  } else if (connectivityResult == ConnectivityResult.bluetooth) {
    cType = "Blutooth Data connection";
    out = ConnectionStatus.mobile;
  } else {
    cType = "none";
    out = ConnectionStatus.none;
  }

  print(cType); //Output: Wifi Network
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
