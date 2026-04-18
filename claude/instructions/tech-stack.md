# Tech Stack Preferences

## Package Manager
- pnpm preferred for all projects

## Node.js Version Manager

- mise를 기본 Node.js 버전 관리 도구로 사용한다
- 전역 설정(`~/.config/mise/config.toml`)에 `legacy_version_file = true` 활성화
  → mise가 `.nvmrc`를 자동 인식

### 프로젝트 적용 규칙

| 상황 | 처리 방식 |
|------|-----------|
| `.nvmrc` 없음 | 프로젝트 루트에 `.mise.toml` 생성 |
| `.nvmrc` 있음 | `.mise.toml`로 전환하고 `.nvmrc` 삭제 |

### `.mise.toml` 형식

```toml
[tools]
node = "22"   # 메이저 버전 고정 (mise가 최신 패치 자동 선택)
```

## General
- Specific frameworks and libraries are defined per project in each repo's CLAUDE.md
- This file covers cross-project preferences only
