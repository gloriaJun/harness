# Status: Devlog Summary

현재 devlogs 루트의 모든 태스크 상태를 출력한다. devlog 없이 즉시 실행.

## Process

### 1. Devlog 루트 감지

SKILL.md의 Devlog Path Detection 규칙 적용:

| cwd contains | devlogs root |
|---|---|
| `GitHubWork` | `~/Documents/GitHubWork/_claude/devlogs/` |
| `GitHubPrivate` | `~/Documents/GitHubPrivate/_claude/devlogs/` |
| neither | 사용자에게 확인 |

### 2. _state.json 스캔

devlogs 루트 하위 디렉토리에서 `_state.json` 파일을 모두 찾는다.

각 파일에서 추출:
- `taskName`
- `currentStep`
- `completedSteps`
- `history` 마지막 항목의 `timestamp` (최근 활동일)

### 3. 활성/완료 분류

- **active**: `currentStep NOT IN completedSteps`
- **done**: `currentStep IN completedSteps`

### 4. 단계명 매핑

| currentStep | 단계명 |
|-------------|--------|
| 0 | entry |
| 1 | idea |
| 2 | plan |
| 3 | design |
| 4 | breakdown |
| 5 | build |
| 6 | complete |
| 7 | retro |
| 8 | wiki |

### 5. 출력

```
Active devlogs (<workspace>):

  <task-name>   step <N> (<step-name>)   <YYYY-MM-DD>
  ...

Done:
  <task-name>   step <N> (<step-name>)   <YYYY-MM-DD>
  ...

No devlogs found.   ← devlog 없을 때
```

규칙:
- active 태스크를 먼저 출력, done 태스크는 그 아래
- done 태스크가 없으면 Done 섹션 생략
- timestamp는 `history` 마지막 항목에서 `YYYY-MM-DD`만 표시
- timestamp 없으면 디렉토리명의 날짜 prefix 사용
- 태스크명은 `taskName` 필드 사용; 없으면 디렉토리명에서 날짜 prefix 제거
