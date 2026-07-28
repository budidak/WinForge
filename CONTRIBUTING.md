# Contributing to WinForge

Thank you for contributing to WinForge! To keep all scripts clean and
consistent, please follow these guidelines before opening a Pull Request.

---

## 1. Code Formatting & Spacing

* **Line Length:** Max 80 characters per line.
* **Indentation:** 3 spaces (no tabs).
* **Whitespace & Spacing:**
  * Put 1 space after keywords and before braces: `if ($condition) {`
  * Put 1 space around binary operators: `$a + $b`, `$x -eq $y`, `$a = $b`
  * No space for unary operators: `!$IsAdmin`, `++$i`
* **Quotes:** Single quotes `'text'` for literal strings; double quotes `" $var "`
  only when interpolating variables.
* **No Aliases:** Do not use `dir`, `gc`, `where`. Always use full cmdlet names
  (`Get-ChildItem`, `Get-Content`, `Where-Object`).
* **Trailing Spaces:** Clean up all trailing whitespace.
* **EOF:** End every file with exactly 1 blank line.

### Brace Placement & Structures

* **Functions:** Opening brace `{` on a **new line**.
* **Control Structures (`if`, `else`, `loops`):** Opening `{` on same line.
  Closing brace and `else` formatted as `} else {`.

```powershell
function Test-Admin
{
   # Function body
}

if ($condition) {
   $result = 1 + 2
} else {
   Write-Host "Failed"
}
```

## 2. Comments & Documentation

* **Block Headers:** Wrap major sections with `==` banners. Leave 2 blank
lines before the block and 1 blank line after.
* **Explanatory Comments:** Add clear comments explaining *why* changes are
made, especially for registry tweaks.

```powershell


# ==============================================================================
# Environment Setup
# ==============================================================================

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

## 3. PowerShell Best Practices

* **Naming Conventions:**
  * **Functions:** Mandatory `PascalCase` and `Verb-Noun` (e.g., `Set-Tweak`).
  * **Script Files:** Main module entry points may use tool names (e.g.,
  `PoshTweak.ps1`). Utility scripts should use `Verb-Noun`.
* **Idempotency:** Scripts must run safely multiple times without breaking.
* **Output Prefixes:** `[+]` Success, `[-]` Warning/Skipped, `[X]` Error.
* **Safety:** Use `[CmdletBinding()]` and explicit types (`[string]`, `[switch]`).

## 4. Submitting Pull Requests

1. Fork the repo and create a feature branch.
2. Ensure code strictly adheres to the 80-character line width limit.
3. Test thoroughly on a clean Windows environment.
4. Include test environment details in your PR description:
   * **OS Edition/Version:** (e.g., Windows 11 Pro 25H2)
   * **PowerShell Version:** `$PSVersionTable.PSVersion` (e.g., 5.1 / 7.4)
5. Submit your PR with a concise summary of changes.
