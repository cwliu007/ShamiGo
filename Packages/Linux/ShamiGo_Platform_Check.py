#!/usr/bin/env python3
"""Shared, read-only distribution gate for ShamiGo Linux v0.10.366-1.

One allowlist for local Debian/LMDE installers and Windows VM Guest Control.
No sudo, mutations, network traffic, execution of /etc/os-release, or shell eval.
"""
from __future__ import annotations

import argparse
import json
import re
import shlex
import subprocess
import sys
from pathlib import Path


class UnsupportedPlatform(ValueError):
    pass


def parse_os_release(text: str) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.split('=', 1)
        if not re.fullmatch(r'[A-Z][A-Z0-9_]*', key):
            continue
        try:
            tokens = shlex.split(value, posix=True, comments=False)
        except ValueError as exc:
            raise UnsupportedPlatform(f'Invalid os-release value for {key}: {exc}') from exc
        if len(tokens) != 1:
            raise UnsupportedPlatform(f'Invalid os-release value for {key}')
        if key in data:
            raise UnsupportedPlatform(f'Duplicate os-release key: {key}')
        data[key] = tokens[0]
    return data


def classify_os(data: dict[str, str], architecture: str) -> dict[str, str]:
    if architecture != 'amd64':
        raise UnsupportedPlatform(f'Only amd64 is supported (found {architecture!r})')
    distro_id = data.get('ID', '').lower()
    version = data.get('VERSION_ID', '')
    distro_codename = data.get('VERSION_CODENAME', '').lower()
    if distro_id == 'debian' and version == '13' and distro_codename in ('trixie', ''):
        return {'id': 'debian', 'name': 'Debian 13 (Trixie)', 'base': 'trixie', 'architecture': architecture}
    if (distro_id == 'linuxmint' and version == '7' and distro_codename in ('gigi', '')
            and data.get('DEBIAN_CODENAME', '').lower() == 'trixie'
            and 'debian' in data.get('ID_LIKE', '').lower().split()):
        return {'id': 'lmde', 'name': 'LMDE 7 (Gigi)', 'base': 'trixie', 'architecture': architecture}
    raise UnsupportedPlatform(
        f"Unsupported Linux (ID={distro_id!r}, VERSION_ID={version!r}, "
        f"VERSION_CODENAME={distro_codename!r}, DEBIAN_CODENAME={data.get('DEBIAN_CODENAME', '')!r}); "
        'supported: Debian 13 Trixie / LMDE 7 Gigi on amd64. '
        'Normal Ubuntu-based Linux Mint is not supported by this binary.'
    )


def check_host(os_release: Path = Path('/etc/os-release'), architecture: str | None = None) -> dict[str, str]:
    try:
        text = os_release.read_text(encoding='utf-8')
    except (OSError, UnicodeError) as exc:
        raise UnsupportedPlatform(f'Cannot read {os_release}: {exc}') from exc
    if architecture is None:
        try:
            architecture = subprocess.run(
                ['dpkg', '--print-architecture'], capture_output=True, text=True, check=True,
                timeout=10).stdout.strip()
        except (OSError, subprocess.SubprocessError) as exc:
            raise UnsupportedPlatform(f'Could not query dpkg architecture: {exc}') from exc
    return classify_os(parse_os_release(text), architecture)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description='Check ShamiGo Debian 13 / LMDE 7 runtime compatibility')
    ap.add_argument('--os-release', type=Path, default=Path('/etc/os-release'),
                    help='for isolated tests; normal installers use /etc/os-release')
    ap.add_argument('--arch', default=None, help='for isolated tests; default dpkg architecture')
    ap.add_argument('--json', action='store_true')
    args = ap.parse_args(argv)
    try:
        info = check_host(args.os_release, args.arch)
    except UnsupportedPlatform as exc:
        print(f'SHAmigo platform check failed: {exc}', file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(info, ensure_ascii=False, sort_keys=True))
    else:
        print(f"SHAMIGO_PLATFORM_OK: {info['name']} ({info['architecture']})")
    return 0


if __name__ == '__main__':
    sys.exit(main())
