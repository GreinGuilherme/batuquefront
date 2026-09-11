# Project Plan

Aplicativo para Programa de Gestão de Pontos de Umbanda (Batuque). Desenvolvido em Flutter com suporte cross-platform (Android/iOS), consumo de API RESTful Spring Boot (Java), gerência de estado (Provider/Riverpod), tema espiritual (tons de branco, azul escuro e dourado) com suporte a Dark Mode. Possui 3 domínios principais: Entidades (Orixás, Guias, Linhas), Pontos Cantados (com letras e Audio Player), e Playlists (Giras/Sequências com reordenação drag and drop).

## Project Brief

# Project Brief: Batuque - Gestão de Pontos de Umbanda

## Features
- **Catálogo de Entidades (Orixás, Guias e Linhas)**: Consulta e navegação por entidades espirituais organizadas por suas respectivas linhas e categorias.
- **Pontos Cantados com Áudio**: Exibição das letras dos pontos cantados com player de áudio integrado para reprodução contínua.
- **Gestão de Playlists para Giras**: Criação e organização de sequências de pontos cantados com suporte à reordenação por *drag-and-drop*.

## High-Level Tech Stack
- **Framework & Linguagem**: Flutter e Dart (para suporte multiplataforma Android e iOS).
- **Gerenciamento de Estado**: Riverpod / Provider.
- **Navegação & UI**: Flutter Router / Navigation com suporte a Material Design, tema customizado (tons de branco, azul escuro e dourado) e Dark Mode.
- **Rede / API**: Pacote `http` para integração com API RESTful Spring Boot.
- **Mídia**: Pacote `audioplayers` para reprodução das faixas de áudio dos pontos.

## Implementation Steps

### Task_1_CoreArchitectureThemeModelsServices: Configure app theme (Light/Dark with #0B192C dark blue and #D4AF37 gold), implement data models (Entidade, PontoCantado, Playlist, PontoItem) with JSON serialization, and set up HTTP services and State Management providers.
- **Status:** IN_PROGRESS
- **Acceptance Criteria:**
  - App theme configured with target color palette and Light/Dark support
  - Entidade, PontoCantado, Playlist, and PontoItem models implemented with JSON serialization
  - HTTP REST services and State Management providers established
  - build pass
- **StartTime:** 2026-09-10 17:33:12 GMT-03:00

### Task_2_EntidadesFeatureScreen: Implement the navigation structure and Entidades screen, including search bar, EntidadeCard widget, FAB modal for adding/editing Entidades, and state/API integration.
- **Status:** PENDING
- **Acceptance Criteria:**
  - Navigation bar/scaffold allows switching between core app sections
  - Entidades list screen displays styled EntidadeCard widgets with search filter
  - FAB opens modal dialog to add or edit Entidade details
  - build pass

### Task_3_PontosCantadosAudioPlayer: Implement Pontos Cantados list screen with search filter by Entidade, creation form with Entidade dropdown, detail view with lyrics, and AudioPlayerWidget using audioplayers package.
- **Status:** PENDING
- **Acceptance Criteria:**
  - Pontos Cantados screen lists items with search and Entidade filter dropdown
  - Creation form supports selecting Entidade from dropdown list
  - Detail view shows lyrics and bottom Audio Player bar with play/pause controls
  - build pass

### Task_4_PlaylistsDragAndDropPlayer: Implement Playlists (Giras) management screen, detail view with ReorderableListView for drag-and-drop item reordering, and sequential audio player controller.
- **Status:** PENDING
- **Acceptance Criteria:**
  - Playlists screen lists available Giras with options to create and manage
  - ReorderableListView allows drag-and-drop reordering of points in a playlist
  - Sequential audio playback transitions between playlist items automatically
  - build pass

### Task_5_RunAndVerify: Execute final build, run unit/integration tests, verify application stability, confirm alignment with user requirements, and verify UI and flow functionality without crashes.
- **Status:** PENDING
- **Acceptance Criteria:**
  - build pass
  - make sure all existing tests pass
  - app does not crash
  - App verified for stability and alignment with user requirements

