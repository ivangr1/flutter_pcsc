import 'package:flutter_pcsc_linux/src/pcsc_bindings.dart';
import 'package:flutter_pcsc_platform_interface/flutter_pcsc_platform_interface.dart';


class PcscLinux extends PcscPlatform {
  static void registerWith() {
    PcscPlatform.instance = PcscLinux();
  }

  static final PCSCBinding _binding = PCSCBinding();

  /*
   * Not really asynchronous (the C call is synchronous), but it will be easier to use if a Future is returned
   * The only true asynchronous methods are:
   * - waitForCardPresent
   * - waitForCardRemoved
   * which uses an Isolate to really be async
   */

  @override
  Future<int> establishContext(int scope) {
    return _binding.establishContext(scope);
  }

  @override
  Future<List<String>> listReaders(int context) {
    return _binding.listReaders(context);
  }

  @override
  Future<Map> cardConnect(
      int context, String reader, int shareMode, int protocol) {
    return _binding.cardConnect(context, reader, shareMode, protocol);
  }

  @override
  Future<List<int>> transmit(
      int hCard, int activeProtocol, List<int> commandBytes,
      {bool newIsolate = false}) {
    return _binding.transmit(hCard, activeProtocol, commandBytes,
        newIsolate: newIsolate);
  }

  @override
  Future<void> cardDisconnect(int hCard, int disposition) {
    return _binding.cardDisconnect(hCard, disposition);
  }

  @override
  Future<void> releaseContext(int context) {
    return _binding.releaseContext(context);
  }

  @override
  Future<Map> waitForCardPresent(int context, String readerName) {
    return _binding.waitForCardPresent(context, readerName);
  }

  @override
  Future<void> waitForCardRemoved(int context, String readerName) {
    return _binding.waitForCardRemoved(context, readerName);
  }
}
