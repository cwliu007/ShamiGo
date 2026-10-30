# ShamiGo v0.10.394 (2026-10-28) — ZIP-executable CMD extraction regression fix

## Root cause and correction

- In v393, `Tools/Zip_CMD_Standalone_Runtime.ps1` used the **obsolete hardcoded v392 directory** in two embedded ZIP-member allowlists. Since v393 ZIP-contained files used v393 paths, the bootstrap rejected them as `Unsafe or unexpected ZIP member` before uninstall could even request UAC. This was a release packaging bug, not a malicious ZIP member or Windows permission failure.
- Both checks now derive Windows payload paths from the single runtime `$version` variable; embedded SHA-256 and extracted-file manifest still undergo full cryptographic verification before execution.
- In full and partially extracted mode, install/uninstall and Linux VM CMD entrypoints directly invoke their verified PowerShell scripts instead of requiring a second neighboring CMD that Explorer may not have temporarily extracted.
- Rebuilt all 14 independent Windows/VM ZIP-entry CMDs with v394 resources, ASCII/CRLF, fresh pinned SHA-256; `Check_Project.cmd` remains a lone-file developer ZIP selector.
- Retained v393 UAC diagnostics and the pre-UAC/pre-task-delete running-process checks during uninstall.
- Windows application and administrator EXEs are rebuilt for v394 with version string changes only; input method behavior and shared C++ algorithms unchanged.
- Frozen Linux v366 binary and VM payload remain unchanged.

## Runtime validation limits

- Static and cryptographic content validation can prove that embedded file names, dependency inventories and hashes are consistent, but cannot replace testing Explorer ZIP staging, UAC and ScheduledTasks on Windows 11.
- On Windows 11 test ZIP-direct uninstall and install separately, consent with the same Windows account, and preserve setup failure logs.
