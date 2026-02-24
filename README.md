# 👋 hello-mac

새 Mac에서 **개발 환경을 한 번에 세팅**하는 스크립트입니다.

터미널, 에디터, 런타임, 시스템 설정까지 — 하나의 명령어로 개발을 시작할 수 있는 상태를 만들어 줍니다.

## 🚀 빠른 시작

```bash
git clone https://github.com/kennykr/hello-mac.git ~/hello-mac
cd ~/hello-mac
bash install.sh      # 인터랙티브 모드 (기본) — 항목별 선택
bash install.sh -f   # 전체 자동 설치
```

## 📦 무엇이 설치되나요?

| 카테고리                  | 내용                                                 |  기본  |
| ------------------------- | ---------------------------------------------------- | :----: |
| 🔧 Core CLI               | asdf, coreutils, eza, gh, gnupg                      |   ✅   |
| 🛠️ Utilities              | lazygit, imagemagick, mole (개별 선택)               |   ✅   |
| ☁️ Cloud CLI              | azure-cli, awscli, google-cloud-sdk (개별 선택)      |   ✅   |
| 🤖 AI CLI Tools           | gemini-cli, opencode, claude-code, codex (개별 선택) |   ✅   |
| 🔤 Font: D2Coding Nerd    | 한글 코딩 전용 폰트 (리가처)                         |   ✅   |
| 🔤 Font: Monoplex KR Nerd | IBM Plex Mono + 한글 합성 (Nerd Font)                |   ✅   |
| 🔤 Font: Sarasa Gothic    | CJK 다국어 고딕체                                    |   ✅   |
| 💻 Apps                   | Docker, Visual Studio Code, Ghostty (개별 선택)      |   ✅   |
| 📱 수동 설치 앱           | OpenUsage — AI 사용량 추적 (GitHub DMG)              |   ✅   |
| 🎨 Shell Theme            | Oh My Zsh + zplug + Powerlevel10k                    |   ✅   |
| ⬢ Node.js Runtime         | asdf로 Node.js, Yarn 설치                            |   ✅   |
| 👤 Git 설정               | 이름/이메일이 없으면 입력                            |  입력  |
| 🆚 VSCode 설정            | settings.json, keybindings.json                      |   ✅   |
| 🍎 macOS 설정             | Dock, Finder, 키보드, 트랙패드 등                    | 항목별 |

> ✅ = 엔터만 치면 설치

## 🍎 macOS 설정 상세

인터랙티브 모드에서 항목별로 선택할 수 있습니다.

| 설정               | 내용                                 | 기본 |
| ------------------ | ------------------------------------ | :--: |
| Dock 자동 숨기기   | 사용하지 않을 때 Dock 숨김           |  ✅  |
| Finder             | 리스트 뷰, 새 창 → Downloads         |  ✅  |
| 빠른 키 반복       | 기본보다 약 3배 빠른 키 반복 속도    |  ✅  |
| 자동 교정 비활성화 | 맞춤법, 대문자, 마침표, 따옴표, 대시 |  ✅  |
| 트랙패드           | 탭 클릭 + 세 손가락 드래그           |  ✅  |
| Hot Corner         | 우하단 → 빠른 메모                   |  —   |

## 📁 구조

```text
hello-mac/
├── install.sh              # 메인 설치 스크립트
├── Brewfile                # Homebrew 패키지 목록
├── scripts/
│   └── install_dmg.sh      # DMG 앱 설치 헬퍼
├── configs/
│   ├── zshrc.theme         # zplug + Powerlevel10k 설정 (append)
│   ├── .p10k.zsh           # Powerlevel10k 테마 (-f 모드 전용)
│   ├── .gitconfig          # Git 사용자 설정
│   ├── .tool-versions      # asdf 글로벌 버전
│   ├── ghostty/config      # Ghostty 터미널 설정 (→ ~/.config/ghostty/)
│   └── vscode/
│       ├── settings.json   # VSCode 에디터 설정
│       └── keybindings.json
├── .gitignore
└── README.md
```

## 🔄 설치 순서

| #   | 섹션                    | `-f` 모드                                 | 인터랙티브 모드                                    |
| --- | ----------------------- | ----------------------------------------- | -------------------------------------------------- |
| 1   | Xcode CLT               | 자동 설치                                 | 자동 설치                                          |
| 2   | Homebrew                | 자동 설치                                 | 자동 설치                                          |
| 3   | Oh My Zsh + Shell Theme | zplug + Oh My Zsh 설치                    | 설치 여부 선택                                     |
| 4   | Homebrew 패키지         | Brewfile 일괄 설치                        | 카테고리/항목별 선택                               |
| 5   | 수동 설치 앱            | OpenUsage 자동 설치                       | 설치 여부 선택                                     |
| 6   | asdf 런타임             | `.tool-versions` 복사 + 설치              | 설치 여부 선택                                     |
| 7   | .zshrc 설정             | 테마 + 전체 설정 append, `.p10k.zsh` 복사 | 테마 + 설치한 도구만 append, `p10k configure` 실행 |
| 8   | 설정 파일 복사          | .gitconfig, Ghostty, VSCode 복사          | Ghostty만 (Apps 설치 시)                           |
| 9   | Git 설정                | `.gitconfig` 복사                         | 이름/이메일 입력                                   |
| 10  | VSCode 설정             | 8번에서 처리                              | 설치 여부 선택 (기본 N)                            |
| 11  | macOS 설정              | 전체 적용                                 | 항목별 선택                                        |
| 12  | `.zshrc.local`          | 템플릿 생성                               | 동일                                               |

## 🔒 민감 정보

토큰, API 키 등은 `~/.zshrc.local`에 보관합니다. 이 파일은 git에 포함되지 않습니다.

```bash
# ~/.zshrc.local 예시
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxxxxxxxxxxx
```
