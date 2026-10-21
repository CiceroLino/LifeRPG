import unittest
from security_audit import pub_queries, maven_queries


class DependencyInventoryTest(unittest.TestCase):
    def test_pub_inventory_uses_resolved_versions_and_skips_sdk(self):
        lock = '''packages:
  archive:
    source: hosted
    version: "4.0.9"
  flutter:
    source: sdk
    version: "0.0.0"
sdks:
  dart: ">=3.11.0 <4.0.0"
'''
        self.assertEqual(pub_queries(lock), [{
            'package': {'name': 'archive', 'ecosystem': 'Pub'}, 'version': '4.0.9',
        }])

    def test_unresolved_maven_graph_cannot_pass_scan(self):
        for report in ['+--- org.example:core:1.0 FAILED',
                       '+--- org.example:core:1.0 -> 1.2 FAILED']:
            with self.subTest(report=report), self.assertRaises(ValueError):
                maven_queries(report)

    def test_maven_inventory_uses_the_selected_version(self):
        report = '+--- org.example:core:1.0 -> 1.2\n\\--- org.example:core:1.2 (*)\n'
        self.assertEqual(maven_queries(report), [{
            'package': {'name': 'org.example:core', 'ecosystem': 'Maven'}, 'version': '1.2',
        }])


if __name__ == '__main__':
    unittest.main()
