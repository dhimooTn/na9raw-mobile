import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/course_subcollections_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODULE SERVICE
// ════════════════════════════════════════════════════════════════════════════

class ModuleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _modulesCollection(String courseId) =>
      _db.collection('courses/$courseId/modules');

  // ──────────────────────────────────────────────────────────────────────────
  // GET MODULES (ordered by order field)
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<Module>> getModules(String courseId) async {
    try {
      final snapshot = await _modulesCollection(courseId)
          .orderBy('order')
          .get();
      return snapshot.docs.map((doc) => Module.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get modules: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD MODULE
  // ──────────────────────────────────────────────────────────────────────────
  Future<String> addModule(String courseId, Module module) async {
    try {
      final docRef = await _modulesCollection(courseId).add(module.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add module: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE MODULE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateModule(
      String courseId,
      String moduleId,
      Map<String, dynamic> data,
      ) async {
    try {
      await _modulesCollection(courseId).doc(moduleId).update(data);
    } catch (e) {
      throw Exception('Failed to update module: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE MODULE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteModule(String courseId, String moduleId) async {
    try {
      await _modulesCollection(courseId).doc(moduleId).delete();
    } catch (e) {
      throw Exception('Failed to delete module: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD LESSON TO MODULE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> addLessonToModule(
      String courseId,
      String moduleId,
      Lesson lesson,
      ) async {
    try {
      final moduleDoc = await _modulesCollection(courseId).doc(moduleId).get();

      if (!moduleDoc.exists) {
        throw Exception('Module not found');
      }

      final module = Module.fromFirestore(moduleDoc);
      final updatedLessons = [...module.lessons, lesson];

      await _modulesCollection(courseId).doc(moduleId).update({
        'lessons': updatedLessons.map((l) => l.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to add lesson: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE LESSON IN MODULE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateLessonInModule(
      String courseId,
      String moduleId,
      int lessonIndex,
      Map<String, dynamic> updatedLesson,
      ) async {
    try {
      final moduleDoc = await _modulesCollection(courseId).doc(moduleId).get();

      if (!moduleDoc.exists) {
        throw Exception('Module not found');
      }

      final module = Module.fromFirestore(moduleDoc);

      if (lessonIndex < 0 || lessonIndex >= module.lessons.length) {
        throw Exception('Lesson index out of bounds');
      }

      final updatedLessons = List<Lesson>.from(module.lessons);
      final currentLesson = updatedLessons[lessonIndex];

      updatedLessons[lessonIndex] = Lesson(
        id: updatedLesson['id'] ?? currentLesson.id,
        type: updatedLesson['type'] ?? currentLesson.type,
        title: updatedLesson['title'] ?? currentLesson.title,
        videoUrl: updatedLesson['videoUrl'] ?? currentLesson.videoUrl,
        thumbnailUrl: updatedLesson['thumbnailUrl'] ?? currentLesson.thumbnailUrl,
        duration: updatedLesson['duration'] ?? currentLesson.duration,
        description: updatedLesson['description'] ?? currentLesson.description,
        resourceUrl: updatedLesson['resourceUrl'] ?? currentLesson.resourceUrl,
        content: updatedLesson['content'] ?? currentLesson.content,
        order: updatedLesson['order'] ?? currentLesson.order,
        locked: updatedLesson['locked'] ?? currentLesson.locked,
      );

      await _modulesCollection(courseId).doc(moduleId).update({
        'lessons': updatedLessons.map((l) => l.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REMOVE LESSON FROM MODULE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> removeLessonFromModule(
      String courseId,
      String moduleId,
      int lessonIndex,
      ) async {
    try {
      final moduleDoc = await _modulesCollection(courseId).doc(moduleId).get();

      if (!moduleDoc.exists) {
        throw Exception('Module not found');
      }

      final module = Module.fromFirestore(moduleDoc);

      if (lessonIndex < 0 || lessonIndex >= module.lessons.length) {
        throw Exception('Lesson index out of bounds');
      }

      final updatedLessons = List<Lesson>.from(module.lessons);
      updatedLessons.removeAt(lessonIndex);

      await _modulesCollection(courseId).doc(moduleId).update({
        'lessons': updatedLessons.map((l) => l.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to remove lesson: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REORDER LESSONS
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> reorderLessons(
      String courseId,
      String moduleId,
      List<Lesson> updatedLessons,
      ) async {
    try {
      await _modulesCollection(courseId).doc(moduleId).update({
        'lessons': updatedLessons.map((l) => l.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to reorder lessons: $e');
    }
  }
}