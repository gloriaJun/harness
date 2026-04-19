# Step 3: Save to Vault

Save the approved retrospective note to the Obsidian vault.

## Target Path

```
~/Documents/obsidian-vault/02.Wiki/retrospect/YYYY-MM-DD-<task-name>-retrospect.md
```

- `YYYY-MM-DD`: today's date
- `<task-name>`: slug confirmed in Step 1

## Execution

1. Verify the target directory exists:
   - Glob `~/Documents/obsidian-vault/02.Wiki/retrospect/`
   - If missing: create it with `mkdir -p`
2. Write the note to the resolved path using the Write tool
3. Confirm success:

```
Saved: ~/Documents/obsidian-vault/02.Wiki/retrospect/YYYY-MM-DD-<task-name>-retrospect.md
```

## Error Handling

- If the vault path does not exist (`~/Documents/obsidian-vault/` missing): warn the user and ask for an alternative path
- If a file with the same name already exists: append `-2` suffix before saving
