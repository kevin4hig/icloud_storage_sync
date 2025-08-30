import 'dart:core';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:icloud_storage_sync/icloud_storage_sync.dart';
import 'package:icloud_storage_sync/models/icloud_file.dart';
import 'package:path_provider/path_provider.dart';

/// Represents a file stored in iCloud
class CloudFiles {
  int? id;
  String title;
  String filePath;
  DateTime? fileDate;
  bool hasUploaded;
  int sizeInBytes;
  DateTime? lastSyncDt;

  /// Relative path of the file in iCloud
  String? relativePath;

  /// Constructor for CloudFiles
  CloudFiles(
    this.id,
    this.title,
    this.filePath,
    this.fileDate,
    this.sizeInBytes,
    this.lastSyncDt, {
    this.relativePath,
    this.hasUploaded = false,
  });

  /// Factory constructor to create a CloudFiles object from JSON
  factory CloudFiles.fromJson(Map<String, dynamic> json) => CloudFiles(
    json['id'] as int?,
    json['title'] as String? ?? '',
    json['filePath'] as String? ?? '',
    json['fileDate'] != null && json['fileDate'].toString().isNotEmpty
        ? DateTime.tryParse(json['fileDate'].toString())
        : null,
    (json['sizeInBytes'] as num?)?.toInt() ?? 0,
    json['lastSyncDt'] != null && json['lastSyncDt'].toString().isNotEmpty
        ? DateTime.tryParse(json['lastSyncDt'].toString())
        : null,
    relativePath: json['relativePath'] as String?,
    hasUploaded: (json['hasUploaded'] as bool?) ?? false,
  );

  /// Converts the CloudFiles object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileDate': fileDate?.toIso8601String(),
      'sizeInBytes': sizeInBytes,
      'lastSyncDt': lastSyncDt?.toIso8601String(),
      'relativePath': relativePath,
      'hasUploaded': hasUploaded,
    };
  }

  /// Overrides the toString method for debugging purposes
  @override
  String toString() {
    return '{id: $id, Title: $title, FilePath: $filePath, '
        'FileDate: $fileDate, sizeInBytes: $sizeInBytes, '
        'LastSyncDt: $lastSyncDt, relativePath: $relativePath, '
        'hasUploaded: $hasUploaded}';
  }
}

/// Extension on List<ICloudFile> to convert iCloud files to CloudFiles objects
extension ListICloudFileConvert on List<ICloudFile> {
  /// Converts a list of ICloudFile objects to CloudFiles objects
  Future<List<CloudFiles>> toFile(List<String> path, containerId) async {
    List<CloudFiles> icloudFiles = [];
    for (var e in this) {
      icloudFiles.add(await _iCloudFileTofile(e, containerId, path));
    }
    return icloudFiles;
  }

  /// Converts a single ICloudFile to a CloudFiles object
  Future<CloudFiles> _iCloudFileTofile(
    ICloudFile file,
    String containerId, [
    List<String> path = const [],
  ]) async {
    int index = path.indexWhere(
      (e) => e.contains(
        Uri.decodeComponent(file.relativePath.replaceAll('%20', ' ')),
      ),
    );
    String? newFilePath;
    String newPath = await _getDownloadPath(file.relativePath);

    if (await File(newPath).exists()) {
      newFilePath = Uri.decodeFull(newPath);
    } else if (index >= 0) {
      String? filepath = await getNewPath(path[index], file.relativePath);
      newFilePath = Uri.decodeFull(filepath);
    } else {
      newFilePath = await downloadFileFromICloud(
        file.relativePath,
        newPath,
        containerId,
      );
    }
    String fileName = (file.relativePath
            .split("/")
            .last
            .toString()
            .split(".")
            .first)
        .replaceAll('%20', ' ');

    await logFileSize(newFilePath ?? file.relativePath);
    return CloudFiles(
      file.hashCode,
      fileName,
      newFilePath ?? file.relativePath,
      file.creationDate,
      file.sizeInBytes,
      file.contentChangeDate,
      relativePath: file.relativePath,
    );
  }

  /// Gets the download path for a file
  Future<String> _getDownloadPath(String relativePath) async {
    final directory = await getTemporaryDirectory();
    return "${directory.path}/$relativePath";
  }

  /// Downloads a file from iCloud
  Future<String?> downloadFileFromICloud(
    String relativePath,
    String newPath,
    String containerId,
  ) async {
    try {
      await IcloudStorageSync().download(
        containerId: containerId,
        relativePath: Uri.decodeFull(relativePath).replaceAll('%20', ' '),
        destinationFilePath: Uri.decodeFull(newPath).replaceAll('%20', ' '),
        onProgress: (progress) async {},
      );
      return Uri.decodeFull(newPath).replaceAll('%20', ' ');
    } catch (e) {
      debugPrint('Error while downloading file from iCloud: ${e.toString()}');
      return null;
    }
  }

  /// Creates a new path for a file and copies its content
  Future<String> getNewPath(String path, String relativePath) async {
    String newPath = await _getDownloadPath(relativePath);
    await File(newPath).create(recursive: true);

    final response = await File(path).readAsBytes();
    await File(newPath).writeAsBytes(response);
    return newPath;
  }

  /// Logs the file size for debugging purposes
  Future<void> logFileSize(String filePath) async {
    if (kDebugMode) {
      try {
        final data = await File(filePath).readAsBytes();
        debugPrint("Length : ${data.length}");
      } catch (_) {
        // debugPrint("Failed to log file size : $filePath");
      }
    }
  }
}
