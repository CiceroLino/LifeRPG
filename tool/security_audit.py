#!/usr/bin/env python3
"""Query OSV for resolved Pub/Maven dependencies; inventory bundled Web assets."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
import urllib.request


def pub_queries(lock):
    queries = []
    for name, body in re.findall(r'^  ([a-zA-Z0-9_]+):\n(.*?)(?=^  [a-zA-Z0-9_]+:|^sdks:|\Z)', lock, re.M | re.S):
        if not re.search(r'^    source: hosted$', body, re.M):
            continue
        version = re.search(r'^    version: "([^"]+)"$', body, re.M)
        if not version:
            raise ValueError(f'Missing resolved version: {name}')
        queries.append({'package': {'name': name, 'ecosystem': 'Pub'}, 'version': version[1]})
    if not queries:
        raise ValueError('No hosted packages found; refusing an empty scan.')
    return queries


def maven_queries(report):
    selected = set()
    pattern = r'\b([\w.-]+):([\w.-]+):([^\s()]+)(?: -> ([^\s()]+))?'
    for group, artifact, requested, resolved in re.findall(pattern, report):
        version = resolved or requested
        if ':' in version:
            group, artifact, version = version.split(':', 2)
        if version in {'FAILED', 'unspecified'} or '+' in version:
            raise ValueError(f'Unresolved dependency: {group}:{artifact}:{version}')
        selected.add((group + ':' + artifact, version))
    if not selected:
        raise ValueError('No Maven dependencies found; refusing an empty scan.')
    return [{'package': {'name': name, 'ecosystem': 'Maven'}, 'version': version}
            for name, version in sorted(selected)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gradle-report', type=Path)
    parser.add_argument('--output', type=Path, default=Path('build/security/audit.json'))
    args = parser.parse_args()
    queries = pub_queries(Path('pubspec.lock').read_text())
    wrapper = Path('android/gradle/wrapper/gradle-wrapper.properties').read_text()
    gradle = re.search(r'gradle-([0-9.]+)-(?:all|bin)\.zip', wrapper)
    if not gradle:
        raise ValueError('Cannot determine Gradle version.')
    queries.append({'package': {'name': 'org.gradle:gradle-core', 'ecosystem': 'Maven'}, 'version': gradle[1]})
    if args.gradle_report:
        queries.extend(maven_queries(args.gradle_report.read_text()))
    request = urllib.request.Request(
        'https://api.osv.dev/v1/querybatch',
        data=json.dumps({'queries': queries}).encode(),
        headers={'Content-Type': 'application/json', 'User-Agent': 'LifeRPG-security-audit'},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        results = json.load(response)['results']
    if len(results) != len(queries) or any(r.get('next_page_token') for r in results):
        raise ValueError('Incomplete OSV response; scan cannot pass.')
    findings = [dict(query=q, advisories=r['vulns']) for q, r in zip(queries, results) if r.get('vulns')]
    assets = {str(f): hashlib.sha256(f.read_bytes()).hexdigest()
              for f in [Path('web/sqlite3.wasm'), Path('web/sqflite_sw.js')]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({
        'queries': queries, 'findings': findings, 'webAssetSha256': assets,
        'coverage': 'Resolved Pub packages, Gradle, and Maven when --gradle-report is supplied. Native engine reachability requires separate review.',
    }, indent=2) + '\n')
    print(f'Queried {len(queries)} package versions; {len(findings)} affected versions. Report: {args.output}')
    for finding in findings:
        print(finding['query']['package']['name'], ', '.join(v['id'] for v in finding['advisories']))
    return 1 if findings else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError) as error:
        print(f'Security scan failed: {error}', file=sys.stderr)
        sys.exit(2)
