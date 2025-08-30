class ICloudFile {
  final String relativePath;
  final int sizeInBytes;
  final DateTime creationDate;
  final DateTime contentChangeDate;
  final bool isDownloading;
  final DownloadStatus downloadStatus;
  final bool isUploading;
  final bool isUploaded;
  final bool hasUnresolvedConflicts;

  ICloudFile.fromMap(Map<dynamic, dynamic> map)
    : relativePath = (map['relativePath'] as String?) ?? '',
      sizeInBytes = (map['sizeInBytes'] as num?)?.toInt() ?? 0,
      creationDate = _toDateFromSecondsEpoch(map['creationDate']),
      contentChangeDate = _toDateFromSecondsEpoch(map['contentChangeDate']),
      isDownloading = (map['isDownloading'] as bool?) ?? false,
      downloadStatus = _mapToDownloadStatusFromNSKeys(
        map['downloadStatus'] as String?,
      ),
      isUploading = (map['isUploading'] as bool?) ?? false,
      isUploaded = (map['isUploaded'] as bool?) ?? false,
      hasUnresolvedConflicts =
          (map['hasUnresolvedConflicts'] as bool?) ?? false;

  static DateTime _toDateFromSecondsEpoch(dynamic v) {
    // iCloud suele dar segundos (double), pero a veces puede llegar int/double/null
    final seconds = (v is num) ? v.toDouble() : 0.0;
    return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
  }

  static DownloadStatus _mapToDownloadStatusFromNSKeys(String? key) {
    switch (key) {
      case 'NSMetadataUbiquitousItemDownloadingStatusNotDownloaded':
        return DownloadStatus.notDownloaded;
      case 'NSMetadataUbiquitousItemDownloadingStatusDownloaded':
        return DownloadStatus.downloaded;
      case 'NSMetadataUbiquitousItemDownloadingStatusCurrent':
        return DownloadStatus.current;
      default:
        // Si viene null o un valor nuevo de Apple, evita lanzar y usa algo sensato
        return DownloadStatus.current;
    }
  }
}

/// Download status of the File
enum DownloadStatus {
  /// Corresponding to NSMetadataUbiquitousItemDownloadingStatusNotDownloaded
  /// This item has not been downloaded yet.
  notDownloaded,

  /// Corresponding to NSMetadataUbiquitousItemDownloadingStatusDownloaded
  /// There is a local version of this item available.
  /// The most current version will get downloaded as soon as possible.
  downloaded,

  /// Corresponding to NSMetadataUbiquitousItemDownloadingStatusCurrent
  /// There is a local version of this item and it is the most up-to-date
  /// version known to this device.
  current,
}
