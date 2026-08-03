# Architecture

## Overview

OpenZap is designed as a modular Flutter application that can support multiple Smart TV brands without tightly coupling brand-specific implementations to the user interface.

The architecture prioritizes maintainability, testability and long-term extensibility while keeping the codebase simple and easy to understand.

---

# Design Principles

The project follows these principles:

* Clean Architecture
* Feature-First organization
* SOLID principles
* Separation of concerns
* Dependency inversion
* Composition over inheritance where appropriate

Every architectural decision should favor clarity and maintainability over unnecessary abstraction.

---

# High-Level Architecture

The application is divided into independent layers.

```text
Presentation
    ↓
Application
    ↓
Domain
    ↓
Data / Integrations
    ↓
Core
```

Each layer has a single responsibility and communicates only with adjacent layers.

---

# Project Structure

The project is organized around features rather than technical types.

```text
lib/
├── app/
├── core/
├── features/
├── integrations/
├── shared/
└── main.dart
```

## app

Application-level configuration.

Examples:

* App initialization
* Routing
* Dependency registration
* Global providers

## core

Reusable infrastructure shared across the entire project.

Examples:

* Networking
* Storage
* Logging
* Routing
* Theme
* Localization
* Exceptions
* Utilities

Core must never contain business logic for a specific TV brand.

## features

Each feature is self-contained and follows the same internal architecture.

```text
feature/
├── presentation/
├── application/
├── domain/
└── data/
```

Features should communicate through well-defined interfaces.

## integrations

Contains brand-specific implementations.

Examples:

* Vestel
* Samsung
* LG
* Sony

Integrations implement shared contracts defined by the domain layer.

No integration should directly manipulate the user interface.

## shared

Reusable UI components, models and helpers that are not tied to a specific feature.

Avoid placing business logic in this layer.

---

# Feature Architecture

Each feature follows the same structure.

## Presentation

Responsible for:

* UI
* User interaction
* State observation

Contains no business logic.

---

## Application

Coordinates use cases.

Responsible for:

* Feature workflows
* Interaction between presentation and domain
* Business orchestration

---

## Domain

Contains business rules and contracts.

The domain layer must not depend on Flutter or infrastructure implementations.

---

## Data

Responsible for:

* Repository implementations
* Data sources
* Mapping
* Communication with integrations and core services

---

# Integrations

Every supported TV brand implements a common abstraction.

The application should interact with the abstraction rather than a specific brand implementation.

Adding a new TV brand should require minimal or no modification to existing features.

---

# Networking

Networking is divided into independent responsibilities.

## Discovery

Responsible for locating compatible devices on the local network.

Discovery may combine multiple strategies depending on platform and protocol.

## Communication

Responsible for establishing connections and exchanging data with devices.

Communication details must remain hidden from higher layers.

## Protocol

Each integration is responsible for implementing the protocol required by the corresponding TV brand.

Protocol details must not leak into features or presentation.

---

# State Management

Riverpod is used throughout the project.

State should remain local whenever possible.

Global state should be introduced only when multiple features genuinely depend on the same information.

---

# Dependency Injection

Dependencies should be registered centrally.

Prefer constructor injection over service locators inside business logic.

Implementations should depend on abstractions whenever practical.

---

# Localization

Localization uses ARB-based resources.

All user-facing text must be localized.

Hardcoded strings in the UI should be avoided.

---

# Testing Strategy

Testing should be performed at multiple levels.

Priority order:

1. Unit Tests
2. Repository Tests
3. Widget Tests
4. Integration Tests

Critical networking and protocol logic should be designed to be easily testable.

---

# Future Extensibility

The architecture is expected to evolve without major structural changes.

Future additions may include:

* Additional Smart TV brands
* New discovery methods
* New communication protocols
* New remote capabilities

New functionality should integrate into the existing architecture instead of introducing parallel systems.

Architectural consistency is preferred over feature-specific optimizations.
