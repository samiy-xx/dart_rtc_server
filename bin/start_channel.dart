import 'dart:io';
import 'dart:json';
import 'dart:math';
import 'dart:isolate';

import '../lib/rtc_server.dart';
import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:args/args.dart';
import 'package:dart_rtc_common/rtc_common.dart';

/*
 * Starts a channel server
 */
void main() {
  Logger.root.level = Level.ALL;
  var pr = new PrintHandler();
  Logger.root.onRecord.listen((LogRecord lr) {
    pr.call(lr);
  });
  ArgParser argParser = new ArgParser();
  argParser.addOption('port', abbr: 'p', help: 'Port to use', defaultsTo: '8234');
  argParser.addOption('ip', abbr: 'i', help: 'Ip to use', defaultsTo: '0.0.0.0');
  var args = argParser.parse(new Options().arguments);
  
  String port = args['port'];
  int p = int.parse(port);
  
  String ip = args['ip'];
  
  Server server = new ChannelServer();
  try {
    server.listen(ip, p);
  } catch(e, s) {
    
  }
}

