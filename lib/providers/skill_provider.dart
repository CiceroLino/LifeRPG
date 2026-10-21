import '../data/database/data_operations.dart';
import 'package:flutter/foundation.dart';
import '../data/models/skill.dart';
import '../data/repositories/skill_repository.dart';

class SkillProvider extends ChangeNotifier {
  final SkillRepository _skillRepo = SkillRepository();

  List<Skill> _skills = [];
  bool _isLoading = false;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;

  Future<void> loadSkills() => DataOperations.instance.run(() async {
    _isLoading = true;
    notifyListeners();
    try {
      _skills = await _skillRepo.getAll();
    } catch (e) {
      debugPrint('Erro ao carregar skills: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }, readOnly: true);

  Future<int?> addSkill(Skill skill) => DataOperations.instance.run(() async {
    try {
      final id = await _skillRepo.insert(skill);
      await loadSkills();
      return id;
    } catch (e) {
      debugPrint('Erro ao adicionar skill: $e');
      return null;
    }
  }, readOnly: false);

  Future<void> updateSkill(Skill skill) =>
      DataOperations.instance.run(() async {
        try {
          await _skillRepo.update(skill);
          await loadSkills();
        } catch (e) {
          debugPrint('Erro ao atualizar skill: $e');
        }
      }, readOnly: false);

  Future<void> deleteSkill(int id) => DataOperations.instance.run(() async {
    try {
      await _skillRepo.delete(id);
      await loadSkills();
    } catch (e) {
      debugPrint('Erro ao deletar skill: $e');
    }
  }, readOnly: false);
}
