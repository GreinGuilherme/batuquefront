# 🥁 Guia de Arquitetura do Projeto Batuque

Este documento traz uma explicação simplificada e direta de como o aplicativo **Batuque** está estruturado, como as peças se conectam e exatamente **onde encontrar e alterar cores, textos, imagens e ícones**.

---

## 📐 1. Visão Geral da Arquitetura

O projeto utiliza o framework **Flutter** com linguagem **Dart**, seguindo o padrão de arquitetura em camadas limpas com gerenciamento de estado via **Provider**.

```
┌─────────────────────────────────────────────────────────┐
│              INTERFACE DE USUÁRIO (UI)                  │
│   Screens (Telas)  &  Widgets (Componentes visuais)     │
└────────────────────────────┬────────────────────────────┘
                             │ escuta alterações e dispara ações
┌────────────────────────────▼────────────────────────────┐
│              GERENCIAMENTO DE ESTADO                    │
│      Providers (Entidades, Pontos, Playlists, etc)      │
└────────────────────────────┬────────────────────────────┘
                             │ solicita dados / envia requisições
┌────────────────────────────▼────────────────────────────┐
│               CAMADA DE SERVIÇOS & API                  │
│       Services (HTTP REST)  &  ApiConfig / MockData     │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 2. Estrutura de Pastas e Arquivos (`lib/`)

Toda a lógica e visual em Flutter do aplicativo fica dentro da pasta **`lib/`**:

```text
lib/
├── main.dart                  # Ponto de entrada do aplicativo (inicializa Providers e Tema)
├── models/                    # Modelos de dados (classes Dart)
│   ├── entidade.dart          # Modelo de Entidade (ex: Exu, Pombagira, Caboclo, etc.)
│   ├── playlist.dart          # Modelo de Playlist
│   ├── ponto_cantado.dart     # Modelo de Ponto Cantado
│   └── ponto_item.dart        # Item da playlist
├── providers/                 # Estado reativo da aplicação (Provider)
│   ├── audio_player_provider.dart  # Controle da reprodução de áudio
│   ├── entidades_provider.dart     # Lista e ações de Entidades
│   ├── playlists_provider.dart     # Lista e ações de Playlists
│   ├── pontos_provider.dart        # Lista e ações de Pontos Cantados
│   └── theme_provider.dart         # Alternância entre Modo Claro/Escuro
├── screens/                   # Telas completas do app
│   ├── home_screen.dart            # Tela principal com aba de navegação inferior
│   ├── entidades_screen.dart       # Lista de Entidades
│   ├── pontos_screen.dart          # Lista de Pontos Cantados
│   ├── playlists_screen.dart       # Lista de Playlists
│   ├── ponto_detail_screen.dart    # Detalhes e letra do ponto
│   └── playlist_detail_screen.dart # Detalhes da playlist
├── services/                  # Comunicação com Backend / API REST
│   ├── api_config.dart        # URL base e tempo limite da API
│   ├── entidade_service.dart  # Requisições HTTP de Entidades
│   ├── playlist_service.dart  # Requisições HTTP de Playlists
│   ├── ponto_service.dart     # Requisições HTTP de Pontos Cantados
│   └── mock_data.dart         # Dados simulados (se a API estiver desativada)
├── theme/                     # Cores, fontes e temas do app
│   └── app_theme.dart         # Definição do Tema Claro e Escuro (Material 3)
└── widgets/                   # Componentes reutilizáveis da UI
    ├── audio_player_bottom_bar.dart # Player de áudio fixo no rodapé
    ├── entidade_card.dart           # Card de exibição da entidade
    ├── ponto_card.dart              # Card de exibição do ponto
    ├── entidade_form_dialog.dart    # Formulário para criar/editar entidade
    ├── ponto_form_dialog.dart       # Formulário para criar/editar ponto
    └── playlist_form_dialog.dart    # Formulário para criar/editar playlist
```

---

## 🎨 3. Como Alterar Cores e Estilos Visual

Toda a paleta de cores e estilos de texto fica centralizada no arquivo:
👉 **[`lib/theme/app_theme.dart`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/theme/app_theme.dart)**

### Alterando as Cores Principais
No início de `app_theme.dart`, você encontra as constantes de cores:
```dart
static const Color darkBluePrimary = Color(0xFF0B192C); // Azul Escuro Principal
static const Color deepBlue        = Color(0xFF1A365D); // Azul Profundo
static const Color spiritualGold   = Color(0xFFD4AF37); // Dourado
static const Color brightGold      = Color(0xFFFFD700); // Dourado Brilhante
static const Color offWhite         = Color(0xFFF8F9FA); // Branco Suave
```
* Para mudar qualquer cor, basta trocar o código hexadecimal `0xFF...` (os últimos 6 dígitos representam a cor em HEX).

### Alterando o Tema Claro ou Escuro
Em `lightTheme` e `darkTheme`, você define:
* **Cores de Fundo**: `scaffoldBackgroundColor` e `surface`.
* **Cores de Botões**: `elevatedButtonTheme` e `floatingActionButtonTheme`.
* **Cores de Cartões**: `cardTheme`.
* **Estilos de Fonte**: `textTheme` (utiliza as fontes `Cinzel` para títulos e `Poppins` para corpo de texto).

---

## ✏️ 4. Como Alterar Textos / Escrita no Aplicativo

Os textos estão divididos nos arquivos de telas e componentes visuais:

1. **Título Principal e Abas do Rodapé**:
   👉 **[`lib/screens/home_screen.dart`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/screens/home_screen.dart)**
   * Altere `'Batuque'`, `'Entidades'`, `'Pontos Cantados'` e `'Playlists'`.

2. **Textos de Listagens e Botões das Telas**:
   👉 Telas em **[`lib/screens/`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/screens/)**
   * `entidades_screen.dart` (ex: barra de busca, mensagens de lista vazia).
   * `pontos_screen.dart` (ex: rótulos de filtro por categoria ou entidade).
   * `playlists_screen.dart` (ex: botão de criar playlist).

3. **Textos de Formulários e Mensagens**:
   👉 Diálogos em **[`lib/widgets/`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/widgets/)**
   * `entidade_form_dialog.dart`, `ponto_form_dialog.dart`, `playlist_form_dialog.dart`.

4. **Dados Iniciais / Fictícios**:
   👉 **[`lib/services/mock_data.dart`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/services/mock_data.dart)**
   * Caso o app esteja rodando sem conexão com servidor backend, os dados exibidos vêm deste arquivo.

---

## 🖼️ 5. Como Identificar e Alterar Imagens, Ícones e Logotipos

### A. Ícones do Aplicativo (Material Icons)
No Flutter, os ícones usados nas telas são ícones vetoriais da biblioteca Material Design:
* Exemplo em `home_screen.dart`: `Icon(Icons.person_rounded)`, `Icon(Icons.music_note_rounded)`.
* Para trocar um ícone, pesquise no site oficial [fonts.google.com/icons](https://fonts.google.com/icons) e substitua por outro ícone de `Icons.<NOME_DO_ICONE>`.

### B. Adicionar Imagens Locais (Assets)
Se quiser colocar logotipos, imagens de fundo ou fotos no aplicativo:
1. Crie uma pasta chamada `assets/images/` na raiz do projeto.
2. Coloque sua imagem lá (exemplo: `logo.png`).
3. Abra o arquivo **[`pubspec.yaml`](file:///C:/Users/grein/AndroidStudioProjects/batuque/pubspec.yaml)** e descomente/adicione a seção:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
   ```
4. No código Dart, exiba a imagem usando:
   ```dart
   Image.asset('assets/images/logo.png', width: 120, height: 120)
   ```

### C. Ícone de Lançamento do Aplicativo (App Icon no Celular)
Para mudar o ícone que aparece na gaveta de aplicativos do celular Android:
👉 As imagens estão localizadas na pasta Android:
* **[`android/app/src/main/res/mipmap-*/ic_launcher.png`](file:///C:/Users/grein/AndroidStudioProjects/batuque/android/app/src/main/res/)**
  *(Com subpastas hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi para cada resolução).*

### D. Tela de Carregamento (Splash Screen / Launch Background)
👉 Arquivo XML da tela inicial do Android:
* **[`android/app/src/main/res/drawable/launch_background.xml`](file:///C:/Users/grein/AndroidStudioProjects/batuque/android/app/src/main/res/drawable/launch_background.xml)**

---

## 🌐 6. Conexão com Servidor Backend / API REST

A configuração de rede fica em:
👉 **[`lib/services/api_config.dart`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/services/api_config.dart)**

```dart
class ApiConfig {
  // Altere este IP se for testar em celular físico na mesma rede Wi-Fi
  static String baseUrl = 'http://10.0.2.2:8080';
  
  static Duration timeout = const Duration(seconds: 10);
  
  // Se true, usa dados simulados de mock_data.dart caso a API falhe
  static bool enableMockFallback = false;
}
```

---

## 📱 7. Configurações Específicas do Android

Se precisar alterar o **nome exibido do app**, permissões de internet ou configurações nativas:
👉 **[`android/app/src/main/AndroidManifest.xml`](file:///C:/Users/grein/AndroidStudioProjects/batuque/android/app/src/main/AndroidManifest.xml)**
* `android:label="Batuque"`: Nome exibido no celular.
* `<uses-permission android:name="android.permission.INTERNET"/>`: Permissão para tocar áudios da internet e conectar ao servidor.

---

## 💡 Resumo Rápido

| O que você quer alterar? | Onde ir? |
| :--- | :--- |
| **Cores e Fontes** | [`lib/theme/app_theme.dart`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/theme/app_theme.dart) |
| **Textos das Telas** | [`lib/screens/`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/screens/) |
| **Textos das Caixas de Diálogo / Formulários** | [`lib/widgets/`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/widgets/) |
| **URL do Servidor / API** | [`lib/services/api_config.dart`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/services/api_config.dart) |
| **Dados Fictícios Sem Backend** | [`lib/services/mock_data.dart`](file:///C:/Users/grein/AndroidStudioProjects/batuque/lib/services/mock_data.dart) |
| **Ícones e Imagens Globais** | Material Icons no código ou pasta `assets/images/` |
| **Ícone do App no Celular** | [`android/app/src/main/res/mipmap-*/`](file:///C:/Users/grein/AndroidStudioProjects/batuque/android/app/src/main/res/) |
| **Nome do App no Android** | [`android/app/src/main/AndroidManifest.xml`](file:///C:/Users/grein/AndroidStudioProjects/batuque/android/app/src/main/AndroidManifest.xml) |

