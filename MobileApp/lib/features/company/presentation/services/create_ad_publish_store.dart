import 'dart:convert';
import 'dart:io';

import 'package:alrasmarket/core/platform/app_paths.dart';
import 'package:alrasmarket/features/company/presentation/services/create_ad_publish_job.dart';
import 'package:flutter/foundation.dart';

/// Disk-backed array of pending create-ad publish jobs.
///
/// Survives process death so uploads can resume after the app is swiped away.
class CreateAdPublishStore {
  CreateAdPublishStore._();

  static final CreateAdPublishStore instance = CreateAdPublishStore._();

  static const _fileName = 'create_ad_publish_queue.json';
  static const _lockFileName = 'create_ad_publish.lock';

  /// Must be short: if the UI isolate dies mid-compress while holding the lock,
  /// the FG isolate needs to steal it quickly.
  static const _lockStaleAfter = Duration(seconds: 25);

  Future<Directory?> _docsDir() async {
    if (kIsWeb) return null;
    final path = await appDocumentsPath();
    if (path == null) return null;
    return Directory(path);
  }

  Future<File?> _file() async {
    final docs = await _docsDir();
    if (docs == null) return null;
    return File('${docs.path}/$_fileName');
  }

  Future<File?> _lockFile() async {
    final docs = await _docsDir();
    if (docs == null) return null;
    return File('${docs.path}/$_lockFileName');
  }

  /// Cross-isolate mutex so main + FG service never create the same ad twice.
  Future<bool> tryAcquireProcessingLock() async {
    try {
      final lock = await _lockFile();
      if (lock == null) return false;
      if (await lock.exists()) {
        final age = DateTime.now().difference(await lock.lastModified());
        if (age < _lockStaleAfter) {
          return false;
        }
        debugPrint(
          '[CreateAdPublishStore] stealing stale lock (age=${age.inSeconds}s)',
        );
      }
      await lock.writeAsString(
        DateTime.now().toIso8601String(),
        flush: true,
      );
      return true;
    } catch (e) {
      debugPrint('[CreateAdPublishStore] lock acquire failed: $e');
      return false;
    }
  }

  /// Touch lock so long compress/upload does not look stale to the other isolate.
  Future<void> heartbeatProcessingLock() async {
    try {
      final lock = await _lockFile();
      if (lock == null || !await lock.exists()) return;
      await lock.writeAsString(
        DateTime.now().toIso8601String(),
        flush: true,
      );
    } catch (_) {}
  }

  Future<void> releaseProcessingLock() async {
    try {
      final lock = await _lockFile();
      if (lock == null) return;
      if (await lock.exists()) {
        await lock.delete();
      }
    } catch (e) {
      debugPrint('[CreateAdPublishStore] lock release failed: $e');
    }
  }

  Future<List<CreateAdPublishJob>> load() async {
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => CreateAdPublishJob.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[CreateAdPublishStore] load failed: $e');
      return [];
    }
  }

  Future<void> save(List<CreateAdPublishJob> jobs) async {
    try {
      final file = await _file();
      if (file == null) return;
      final payload = jsonEncode(jobs.map((j) => j.toJson()).toList());
      await file.writeAsString(payload, flush: true);
    } catch (e) {
      debugPrint('[CreateAdPublishStore] save failed: $e');
    }
  }

  Future<void> enqueue(CreateAdPublishJob job) async {
    final jobs = await load();
    if (jobs.any((j) => j.id == job.id)) {
      await save(jobs);
      return;
    }
    jobs.add(job);
    await save(jobs);
  }

  Future<CreateAdPublishJob?> peekFirst() async {
    final jobs = await load();
    if (jobs.isEmpty) return null;
    return jobs.first;
  }

  Future<void> removeById(String id) async {
    final jobs = await load();
    jobs.removeWhere((j) => j.id == id);
    await save(jobs);
  }

  Future<void> update(CreateAdPublishJob job) async {
    final jobs = await load();
    final index = jobs.indexWhere((j) => j.id == job.id);
    if (index < 0) {
      jobs.add(job);
    } else {
      jobs[index] = job;
    }
    await save(jobs);
  }

  Future<int> count() async => (await load()).length;
}
