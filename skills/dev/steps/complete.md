# Complete: Task Wrap-up

When all features are done.

## Process

1. Final update of PRD and TRD to reflect any changes made during execution.
2. Update `_state.json` in the devlogs task subdirectory:
   - Set `currentStep` to `6`
   - Append `6` to `completedSteps`
3. If documents were saved in the task subdirectory (temporary):
   - Ask (follow Single Choice pattern):
     ```
     임시 저장된 파일을 어떻게 처리할까요?
     1. 삭제
     2. 유지
     3. 다른 위치로 이동

     > 번호 입력 또는 자유 응답
     ```
   - Delete only after explicit confirmation.
4. Present summary:
   - What was built
   - Files changed
   - Follow-up items
5. Run **insight**: Load and execute `skills/insight/SKILL.md` inline (in main context).
   This reviews the entire task workflow and suggests grimoire improvements.
6. Clean up `_state.json` in the devlogs directory: optionally archive or delete based on user preference.

## Next

After completion, run `/dev retro` to capture session retrospective and learnings.

## Session Handoff

Read `steps/_handoff.md` and follow the handoff instructions for this step.
