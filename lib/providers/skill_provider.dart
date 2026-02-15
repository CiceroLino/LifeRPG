import 'package:flutter/foundation.dart';
import '../data/models/skill.dart';
import '../data/repositories/skill_repository.dart';

class SkillProvider extends ChangeNotifier {
  final SkillRepository _skillRepo = SkillRepository();

  List<Skill> _skills = [];
  bool _isLoading = false;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;

  Future<void> loadSkills() async {
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
  }

  Future<int?> addSkill(Skill skill) async {
    try {
      final id = await _skillRepo.insert(skill);
      await loadSkills();
      return id;
    } catch (e) {
      debugPrint('Erro ao adicionar skill: $e');
      return null;
    }
  }

  Future<void> updateSkill(Skill skill) async {
    try {
      await _skillRepo.update(skill);
      await loadSkills();
    } catch (e) {
      debugPrint('Erro ao atualizar skill: $e');
    }
  }

  Future<void> deleteSkill(int id) async {
    try {
      await _skillRepo.delete(id);
      await loadSkills();
    } catch (e) {
      debugPrint('Erro ao deletar skill: $e');
    }
  }
}
