// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

class ComputerInfo {
  final Computer computer;
  final Processor processor;
  final List<Memory> memories;
  final List<VideoController> videoControllers;
  final List<Disk> disks;

  ComputerInfo({required this.computer, required this.processor, required this.memories, required this.videoControllers, required this.disks});

  static Future<ComputerInfo> fetch() async {
    final info = await Future.wait([
      Computer.fetch(),
      Processor.fetch(),
      Memory.fetch(),
      VideoController.fetch(),
      Disk.fetch(),
    ]);

    return ComputerInfo(
      computer: info[0] as Computer,
      processor: info[1] as Processor,
      memories: info[2] as List<Memory>,
      videoControllers: info[3] as List<VideoController>,
      disks: info[4] as List<Disk>,
    );
  }
}

// Get-ComputerInfo
class Computer {
  final String osVersion; // OSDisplayVersion
  final String biosVersion; // BiosName
  final String mbModel; // CsModel
  final String mbManufacturer; // CsManufacturer
  final double totalMemorySize; // CsPhyicallyInstalledMemory, KiB -> GiB

  Computer({required this.osVersion, required this.biosVersion, required this.mbModel, required this.mbManufacturer, required this.totalMemorySize});

  static const _fetchCommand = 'Get-ComputerInfo | ConvertTo-Json';
  static Future<Computer> fetch() async {
    final result = await Process.run('powershell.exe', ['-Command', _fetchCommand]);
    if (result.exitCode != 0) {
      throw Exception('Failed to fetch Computer, (_fetchCommand)');
    }
    final json = jsonDecode(result.stdout);

    return Computer(
      osVersion: json['OSDisplayVersion'],
      biosVersion: json['BiosName'],
      mbModel: json['CsModel'],
      mbManufacturer: json['CsManufacturer'],
      totalMemorySize: json['CsPhyicallyInstalledMemory'] / 1048576,
    );
  }
}

// Get-WmiObject Win32_Processor
class Processor {
  final String name; // Name
  final int speed; // MaxClockSpeed (MHz)
  final int threads; // NumberOfLogicalProcessors
  final int cores; // NumberOfCores
  final String socket; // SocketDesignation

  Processor({required this.name, required this.speed, required this.threads, required this.cores, required this.socket});

  static const _fetchCommand = 'Get-WmiObject Win32_Processor | ConvertTo-Json';
  static Future<Processor> fetch() async {
    final result = await Process.run('powershell.exe', ['-Command', _fetchCommand]);
    if (result.exitCode != 0) {
      throw Exception('Failed to fetch Processor, ($_fetchCommand)');
    }
    final json = jsonDecode(result.stdout);

    return Processor(
      name: json['Name'],
      speed: json['MaxClockSpeed'],
      threads: json['NumberOfLogicalProcessors'],
      cores: json['NumberOfCores'],
      socket: json['SocketDesignation'],
    );
  }
}

// Get-WmiObject Win32_PhysicsMemory [i]
class Memory {
  final String bank; // BankLabel
  final double size; // Capacity, KiB -> GiB
  final int speed; // Speed (MHz)
  final MemoryType type; // MemoryType

  Memory({required this.bank, required this.size, required this.speed, required this.type});

  static const _fetchCommand = 'Get-WmiObject Win32_PhysicalMemory | ConvertTo-Json';
  static Future<List<Memory>> fetch() async {
    final result = await Process.run('powershell.exe', ['-Command', _fetchCommand]);
    if (result.exitCode != 0) {
      throw Exception('Failed to fetch Memories, ($_fetchCommand)');
    }
    final json = jsonDecode(result.stdout);

    return (json as List)
        .map((memory) => Memory(
              bank: memory['BankLabel'],
              size: memory['Capacity'] / 1048576,
              speed: memory['Speed'],
              type: MemoryType.values.elementAtOrNull(memory['MemoryType']) ?? MemoryType.Unknown,
            ))
        .toList();
  }
}

enum MemoryType {
  Unknown,
  Other,
  DRAM,
  Synchronous_DRAM,
  Cache_DRAM,
  EDO,
  EDRAM,
  VRAM,
  SRAM,
  RAM,
  ROM,
  Flash,
  EEPROM,
  FEPROM,
  EPROM,
  CDRAM,
  ThreeDRAM,
  SDRAM,
  SGRAM,
  RDRAM,
  DDR,
  DDR2,
  DDR2_FB_DIMM,
  DDR3,
  FBD2,
  DDR4,
}

// Get-WmiObject Win32_VideoController [i]
class VideoController {
  final String name; // Name
  final double vram; // AdapterRAM, KiB -> GiB

  VideoController({required this.name, required this.vram});

  static const _fetchCommand = 'Get-WmiObject Win32_VideoController | ConvertTo-Json';
  static Future<List<VideoController>> fetch() async {
    final result = await Process.run('powershell.exe', ['-Command', _fetchCommand]);
    if (result.exitCode != 0) {
      throw Exception('Failed to fetch VideoControllers, ($_fetchCommand)');
    }
    final json = jsonDecode(result.stdout);

    return (json as List)
        .map((videoController) => VideoController(
              name: videoController['Name'],
              vram: videoController['AdapterRAM'] / 1048576,
            ))
        .toList();
  }
}

// Get-PhysicalDisk [i]
class Disk {
  final String name; // FriendlyName
  final double size; // Size, Byte -> GB
  final DiskType type; // MediaType
  final DiskInterface interface; // BusType
  final DiskStatus status; // OperationalStatus
  final String health; // HealthStatus

  Disk({required this.name, required this.size, required this.type, required this.interface, required this.status, required this.health});

  static const _fetchCommand = 'Get-PhysicalDisk | ConvertTo-Json';
  static Future<List<Disk>> fetch() async {
    final result = await Process.run('powershell.exe', ['-Command', _fetchCommand]);
    if (result.exitCode != 0) {
      throw Exception('Failed to fetch Disks, ($_fetchCommand)');
    }
    final json = jsonDecode(result.stdout);

    return (json as List)
        .map((disk) => Disk(
              name: disk['FriendlyName'],
              size: disk['Size'] / 1073741824,
              type: DiskType.values.asNameMap()[disk['MediaType']] ?? DiskType.Other,
              interface: DiskInterface.values.asNameMap()[disk['BusType']] ?? DiskInterface.Other,
              status: DiskStatus.values.firstWhereOrNull((diskStatus) => diskStatus.value == disk['OperationalStatus']) ?? DiskStatus.Other,
              health: disk['HealthStatus'],
            ))
        .toList();
  }
}

enum DiskType {
  HDD,
  SSD,
  Other,
}

enum DiskInterface {
  SATA,
  NVMe,
  Other,
}

enum DiskStatus {
  OK('OK'),
  Error('Error'),
  Degraded('Degraded'),
  Unknown('Unknown'),
  Pred_Fail('Pred Fail'),
  Starting('Starting'),
  Stopping('Stopping'),
  Service('Service'),
  Stressed('Stressed'),
  NonRecover('NonRecover'),
  No_Contact('No Contact'),
  Lost_Comm('Lost Comm'),
  Other('');

  final String value;

  const DiskStatus(this.value);
}
