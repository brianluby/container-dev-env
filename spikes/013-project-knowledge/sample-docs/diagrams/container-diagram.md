# Container Diagram

<!--
AI Agent Instructions:
- This diagram shows the major components inside the container
- Each component corresponds to a PRD in the project
- Components are layered: base → config → tools → IDE
-->

## Overview

The container is built in layers, each PRD adding functionality on top of the previous.

## Container Architecture

```mermaid
graph TB
    subgraph Container["Development Container"]
        subgraph Base["Base Layer (PRD-001)"]
            Debian["Debian Bookworm-slim"]
            DevTools["Dev Tools<br/>git, curl, make"]
            Runtimes["Runtimes<br/>Python, Node.js"]
        end

        subgraph Config["Configuration Layer"]
            Chezmoi["Dotfiles (PRD-002)<br/>Chezmoi"]
            Secrets["Secrets (PRD-003)<br/>age encryption"]
        end

        subgraph Storage["Storage Layer (PRD-004)"]
            Volumes["Volume Mounts<br/>code, cache, data"]
        end

        subgraph IDE["IDE Layer (PRD-008)"]
            CodeServer["code-server<br/>VS Code in browser"]
            Extensions["AI Extensions (PRD-009)<br/>Continue, Cline"]
        end

        subgraph AI["AI Layer"]
            MCP["MCP Servers (PRD-011)<br/>Tool integration"]
            Memory["Memory Bank (PRD-012)<br/>Session context"]
            Knowledge["Project Knowledge (PRD-013)<br/>Documentation"]
        end
    end

    Debian --> DevTools
    DevTools --> Runtimes
    Runtimes --> Chezmoi
    Chezmoi --> Secrets
    Secrets --> Volumes
    Volumes --> CodeServer
    CodeServer --> Extensions
    Extensions --> MCP
    MCP --> Memory
    Memory --> Knowledge
```

## Component Responsibilities

| Component | PRD | Responsibility |
|-----------|-----|----------------|
| **Base Image** | 001 | OS, system packages, runtimes |
| **Dotfiles** | 002 | Shell config, editor settings |
| **Secrets** | 003 | API keys, credentials |
| **Volumes** | 004 | Code, cache, persistent data |
| **IDE** | 008 | code-server, browser access |
| **AI Extensions** | 009 | Continue, Cline for AI assistance |
| **MCP** | 011 | Tool integration for AI |
| **Memory Bank** | 012 | Session context persistence |
| **Project Knowledge** | 013 | Documentation for AI |

## Layer Dependencies

```mermaid
graph LR
    PRD001["PRD-001<br/>Base Image"] --> PRD002["PRD-002<br/>Dotfiles"]
    PRD001 --> PRD003["PRD-003<br/>Secrets"]
    PRD001 --> PRD004["PRD-004<br/>Volumes"]
    PRD002 --> PRD008["PRD-008<br/>IDE"]
    PRD003 --> PRD008
    PRD004 --> PRD008
    PRD008 --> PRD009["PRD-009<br/>AI Extensions"]
    PRD009 --> PRD011["PRD-011<br/>MCP"]
    PRD011 --> PRD012["PRD-012<br/>Memory"]
    PRD012 --> PRD013["PRD-013<br/>Knowledge"]
```

## Volume Mount Structure

```mermaid
graph LR
    subgraph Host["Host Machine"]
        Code["~/code"]
        Cache["~/.cache"]
        SSH["~/.ssh"]
    end

    subgraph Container["Container"]
        WorkDir["/workspace"]
        ContCache["/home/dev/.cache"]
        ContSSH["/home/dev/.ssh"]
    end

    Code -->|"bind mount"| WorkDir
    Cache -->|"bind mount"| ContCache
    SSH -->|"bind mount (ro)"| ContSSH
```
