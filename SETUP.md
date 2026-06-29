# AppVault — Guia de Setup Completo

## Nome e Identidade
- **Nome:** AppVault
- **Bundle ID:** com.appvault.app
- **Tagline:** "Bloqueie qualquer app. Você decide quem acessa."
- **Categoria App Store:** Utilitários / Controle Parental
- **Classificação etária:** 4+

---

## Pré-requisitos
- Mac com Xcode 15+
- Conta Apple Developer (USD 99/ano)
- iPhone com iOS 16+ para testar (o simulador NÃO suporta FamilyControls)

---

## Passo 1 — Criar o Projeto no Xcode

1. Abra o Xcode → **File > New > Project**
2. Escolha **App** (iOS)
3. Preencha:
   - Product Name: `AppVault`
   - Bundle Identifier: `com.appvault.app`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 16.0**
4. Salve na pasta `C:\AppVault\` (ou copie os arquivos depois)

---

## Passo 2 — Adicionar a Shield Extension

1. No Xcode, menu **File > New > Target**
2. Escolha **Shield Configuration Extension**
3. Nome: `ShieldExtension`
4. Bundle ID: `com.appvault.ShieldExtension`
5. Repita para **Shield Action Extension**

---

## Passo 3 — Copiar os Arquivos de Código

Copie os arquivos das pastas:
```
AppVault/AppVault/   → Target: AppVault
AppVault/ShieldExtension/ → Target: ShieldExtension
```

### Estrutura esperada no Xcode:
```
AppVault/
├── AppVaultApp.swift
├── Models/
│   └── LockGroup.swift
├── Services/
│   ├── AppLockService.swift
│   ├── KeychainService.swift
│   └── AuthService.swift
├── Views/
│   ├── ContentView.swift
│   ├── OnboardingView.swift
│   ├── HomeView.swift
│   ├── AddGroupView.swift
│   ├── PinSetupView.swift
│   ├── PinEntryView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── PinPadView.swift
│       └── LockGroupCard.swift
├── Extensions/
│   └── Color+AppVault.swift
└── AppVault.entitlements

ShieldExtension/
├── ShieldConfigurationExtension.swift
├── ShieldActionExtension.swift
└── ShieldExtension.entitlements
```

---

## Passo 4 — Configurar Entitlements

### No target AppVault:
1. Selecione o target → **Signing & Capabilities**
2. Clique **+ Capability**
3. Adicione: **Family Controls**
4. Adicione: **App Groups** → `group.com.appvault.shared`
5. Adicione: **Keychain Sharing** → `com.appvault.app`

### No target ShieldExtension:
1. Mesmos passos acima (Family Controls + App Groups)

---

## Passo 5 — Info.plist

Adicione ao Info.plist do app principal:
```xml
<key>NSFaceIDUsageDescription</key>
<string>AppVault usa Face ID para desbloquear apps de forma segura e rápida.</string>
```

E adicione o URL scheme para receber chamadas da Shield Extension:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>appvault</string>
        </array>
    </dict>
</array>
```

---

## Passo 6 — Entitlement Especial (Distribuição)

Para publicar na App Store, você precisa solicitar o entitlement:
1. Acesse: https://developer.apple.com/contact/request/family-controls-distribution
2. Descreva o app como ferramenta de **autocontrole e produtividade**
3. A Apple aprova em 3-7 dias úteis
4. ⚠️ **Para desenvolvimento local, não precisa de aprovação**

---

## Passo 7 — Assets do App

### Ícone
- Abra `Assets/icon.svg` em Figma, Sketch, ou Pixelmator
- Exporte como PNG nos tamanhos:
  - 1024×1024 (App Store)
  - 180×180 (iPhone @3x)
  - 120×120 (iPhone @2x)
  - 87×87, 80×80, 60×60, 58×58, 40×40, 29×29
- Importe no `Assets.xcassets > AppIcon`

### Screenshots para App Store (obrigatório)
Tamanhos mínimos exigidos:
- **iPhone 6.9"** (iPhone 16 Pro Max): 1320×2868
- **iPhone 6.5"** (iPhone 14 Plus): 1284×2778
- **iPhone 5.5"** (opcional): 1242×2208
- Veja o conceito em `Assets/store_screenshot_concept.svg`

---

## Passo 8 — App Store Connect

1. Acesse: https://appstoreconnect.apple.com
2. Crie um novo app
3. Preencha:
   - **Nome:** AppVault
   - **Subtítulo:** Bloqueie qualquer app com senha
   - **Palavras-chave:** bloqueio, senha, segurança, screen time, foco, parental, app lock
   - **Descrição** (exemplo abaixo)
4. Upload do build via Xcode → Product → Archive → Distribute

### Descrição sugerida para App Store (PT-BR):
```
AppVault — Coloque senha em qualquer app.

Crie grupos de aplicativos e proteja cada um com um PIN diferente. Você controla quem acessa o quê, quando quiser.

✦ SENHAS DIFERENTES POR APP
Cada grupo tem seu próprio PIN de 4 ou 6 dígitos. Instagram, TikTok, jogos — cada um com uma senha única.

✦ FACE ID & TOUCH ID
Desbloqueie com biometria para máxima comodidade sem abrir mão da segurança.

✦ PROTEÇÃO TOTAL
Quando um app está bloqueado, uma tela de proteção aparece impedindo o acesso — mesmo que alguém tente forçar.

✦ FOCO E PRODUTIVIDADE
Bloqueie redes sociais durante o trabalho. Bloqueie jogos na hora de estudar. Você define as regras.

✦ SIMPLES DE USAR
Interface limpa e intuitiva. Configure em segundos, proteja para sempre.

Compatível com iPhone e requer iOS 16 ou superior.
```

---

## Arquitetura Técnica

```
┌─────────────────────────────────────┐
│           AppVault (Main App)        │
│                                      │
│  FamilyActivityPicker ──► Selection  │
│  ManagedSettingsStore ──► Block Apps │
│  Keychain ──────────────► PIN hashes │
│  LocalAuthentication ───► Biometrics │
└──────────────┬──────────────────────┘
               │ App Blocked → Shield appears
               ▼
┌─────────────────────────────────────┐
│         ShieldExtension              │
│                                      │
│  ShieldConfiguration ── Custom UI    │
│  ShieldAction ─────── Opens AppVault │
└─────────────────────────────────────┘
               │ URL: appvault://unlock
               ▼
┌─────────────────────────────────────┐
│      PinEntryView (in main app)      │
│  ► Verifica PIN no Keychain          │
│  ► Sucesso: remove bloqueio 5 min    │
│  ► Falha: registra tentativa         │
└─────────────────────────────────────┘
```

---

## Monetização Sugerida

- **Grátis** com 1 grupo
- **AppVault Pro** (R$ 14,90/mês ou R$ 89,90/ano):
  - Grupos ilimitados
  - Bloqueio por horário
  - Relatórios de tentativas de acesso
  - Backup de configurações iCloud
  - Tema personalizado

Use `StoreKit 2` (nativo Swift) para a assinatura.

---

## Suporte
- iOS 16.0+
- Xcode 15+
- Swift 5.9+
- Frameworks: SwiftUI, FamilyControls, ManagedSettings, LocalAuthentication, CryptoKit
