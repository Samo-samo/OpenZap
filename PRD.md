# OpenZap Product Requirements Document (PRD)

## 1. Overview

OpenZap is an open-source, cross-platform application that allows users to control compatible Smart TVs over a local network.

The project aims to provide a modern, lightweight and ad-free alternative to existing Smart TV remote applications, many of which rely on advertisements, unnecessary permissions or proprietary services.

OpenZap is designed with extensibility in mind. Support for additional TV brands and capabilities should be possible without requiring major changes to the application architecture.

---

# 2. Vision

Create a reliable, open-source Smart TV controller that is simple to use, easy to maintain and capable of supporting multiple Smart TV platforms through a modular architecture.

The project prioritizes long-term maintainability, clean design and practical usability over rapid feature expansion.

---

# 3. Goals

The initial goals of OpenZap are:

* Provide a responsive Smart TV remote experience.
* Support multiple Smart TV brands through a unified architecture.
* Remain completely open source.
* Contain no advertisements or unnecessary third-party services.
* Operate entirely within the user's local network.
* Be easy to extend with new TV integrations.

---

# 4. Project Scope

The first public milestone focuses on delivering a stable foundation and complete support for Vestel Smart TVs.

Core functionality includes:

* Device discovery on the local network
* Remote control
* Device management
* Wake-on-LAN
* Application launching (when supported)
* Sleep timer
* Basic settings and personalization

---

# 5. Supported Platforms

## Current

* Windows (Primary development platform)

## Planned

* Android

## Under Consideration

* Linux Desktop
* macOS
* iOS

Web is currently out of scope.

---

# 6. Supported TV Types

Currently, OpenZap targets:

* Smart TVs

Other device categories may be evaluated in future versions.

---

# 7. Supported Brands

| Brand                 | Status               |
| --------------------- | -------------------- |
| Vestel Smart TV       | In Development       |
| Samsung Smart TV      | Future Consideration |
| LG Smart TV           | Future Consideration |
| Sony Smart TV         | Future Consideration |

Additional brands may be evaluated based on community interest and protocol research.

---

# 8. Key Features

The first major release is expected to include:

* Local network device discovery
* Smart TV remote control
* Device management
* Wake-on-LAN
* Quick application launcher (supported devices)
* Sleep timer
* Light and dark themes
* Multiple language support

Feature availability may vary depending on TV brand and protocol capabilities.

---

# 9. Protocol Research

OpenZap is an independent implementation.

Existing open-source projects may be used as references for protocol research, validation and interoperability testing. However, implementation decisions are based on observed device behavior rather than reproducing another project's architecture or code.

Where necessary, network traffic analysis may be performed to understand communication between official remote applications and compatible televisions.

---

# 10. Future Considerations

Potential future improvements include:

* Additional Smart TV brands
* Android TV support
* Google TV support
* Text input
* Touchpad mode
* Advanced application management
* Automation features
* Developer diagnostics

Items listed here are exploratory and should not be interpreted as committed roadmap items.

---

# 11. Release Strategy

The project follows Semantic Versioning (SemVer).

Development will initially remain within the 0.x release series while the architecture and public APIs continue to evolve.

Version 1.0.0 represents the first stable release where the core architecture and primary functionality are considered production-ready.

---

# 12. Guiding Principles

Every technical and product decision should prioritize:

* Simplicity over unnecessary complexity.
* Maintainability over short-term convenience.
* Extensibility over hardcoded implementations.
* Transparency over hidden behavior.
* User experience over feature count.

OpenZap is developed primarily to be a useful tool for both its creator and the community, rather than to maximize popularity or commercial success.
