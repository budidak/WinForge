# WinForge 🛠️

**WinForge** is a privacy- and performance-focused PowerShell automation suite 
designed to customize, optimize, and harden Windows environments.

It simplifies system administration by disabling unwanted telemetry, managing 
background services, configuring firewall rules, and enforcing security 
policies via Registry and Group Policy (GPO) tweaks — all while delivering a 
modern terminal setup.

---

## ✨ Key Features

* **🛡️ Security Hardening & Privacy:**
  * Disables Windows telemetry, diagnostic data, and tracking services.
  * Tweaks Group Policy (`gpedit.msc`) and Registry (`regedit`)
    settings for enhanced privacy.
  * Adjusts Windows Firewall rules and disables unnecessary
    background services.

* **🚀 Performance & Optimization:**
  * Removes background bloatware and optimizes system resource allocation.
  * Streamlines system services for low-latency performance.

* **🎨 Terminal Customization (`PoshTweak`):**
  * **Theme:** Catppuccin Macchiato palette
  * **Font:** Hack Nerd Font integration
  * **Prompt:** Modern, styled PowerShell prompt with environment tweaks

---

## 📦 Modules Included

### 🎨 `PoshTweak.ps1`

An all-in-one script for terminal personalization, prompt styling, 
environment variable configuration, and core registry optimizations.

> *Additional dedicated hardening and utility modules will be added*
> *as WinForge expands.*

---

## 🚀 Quick Start

> **Important:** WinForge scripts require **Administrator privileges** to apply 
> system tweaks, firewall rules, and profile changes.

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/budidak/WinForge.git
   cd WinForge
   ```

2. Run PowerShell as Administrator

   ```powershell
   # Standard execution (appends settings safely)
   .\PoshTweak.ps1

   # Force recreation of the terminal profile from scratch
   .\PoshTweak.ps1 -Force
   ```

## 🤝 Contributing

Contributions are welcome! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) 
for details on code style (80-character line limit, 3-space indentation, 
spacing rules, etc.) and submission guidelines.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) 
file for details.
