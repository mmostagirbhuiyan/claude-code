---
description: Fork the current conversation to a different working directory
argument-hint: /path/to/new/directory
allowed-tools: ["Bash", "Read", "AskUserQuestion"]
---

# Fork Conversation to New Directory

Fork (copy) the current conversation to a different working directory so you can continue it there with full history preserved.

## Your Task

### Step 1: Validate Target Directory

The user wants to fork this conversation to: `$ARGUMENTS`

**If $ARGUMENTS is empty:**
Use AskUserQuestion to ask:
- question: "Where would you like to fork this conversation to?"
- description: "Enter the absolute path to the target directory (e.g., ~/Documents/my-project)"

Once you have the target path:

1. Expand the path (resolve `~` and relative paths) using:
   ```
   target_dir=$(eval echo "$ARGUMENTS") && echo "$target_dir"
   ```
2. Verify the target directory exists:
   ```
   test -d "$target_dir" && echo "Directory exists" || echo "Directory does not exist"
   ```
3. If it does not exist, ask the user if they want to create it. If yes, create it with `mkdir -p`.

### Step 2: Identify Current Session

Get the current session ID and source project directory:

```bash
# Get the current working directory encoded as Claude stores it
cwd="$(pwd)"
encoded_cwd=$(echo "$cwd" | sed 's|/|-|g')
project_dir="$HOME/.claude/projects/$encoded_cwd"
echo "Source project dir: $project_dir"
ls -lt "$project_dir"/*.jsonl 2>/dev/null | head -5
```

The most recently modified `.jsonl` file is the current (or most recent) conversation session.

### Step 3: Identify Target Project Directory

```bash
# Encode the target directory path the same way Claude does
encoded_target=$(echo "$target_dir" | sed 's|/|-|g')
target_project_dir="$HOME/.claude/projects/$encoded_target"
echo "Target project dir: $target_project_dir"
```

### Step 4: Show Summary and Confirm

Before copying, show the user a summary:

- Source directory: `{cwd}`
- Target directory: `{target_dir}`
- Session file to copy: `{session_file}`
- File size: `{size}`

Use AskUserQuestion to confirm:
- question: "Ready to fork this conversation?"
- description: "This will copy the conversation to the target directory. The original stays intact. You can resume it by running `claude --resume` from the new directory."

### Step 5: Fork the Conversation

Execute the fork:

```bash
# Create the target project directory if it doesn't exist
mkdir -p "$target_project_dir"

# Copy the session JSONL file
cp "$project_dir/$session_file" "$target_project_dir/$session_file"

# Copy the session companion directory if it exists (contains subagent data, tool results)
if [ -d "$project_dir/${session_file%.jsonl}" ]; then
  cp -r "$project_dir/${session_file%.jsonl}" "$target_project_dir/${session_file%.jsonl}"
fi

echo "Fork complete!"
```

### Step 6: Update CWD References in Forked Conversation

After copying, update the `cwd` fields in the forked conversation so Claude associates it with the new directory:

```bash
# Update cwd references in the copied JSONL file
# Use sed to replace the old cwd with the new target directory
sed -i.bak "s|\"cwd\":\"$cwd\"|\"cwd\":\"$target_dir\"|g" "$target_project_dir/$session_file"
rm -f "$target_project_dir/$session_file.bak"
echo "Updated cwd references in forked conversation"
```

### Step 7: Confirm Success

Tell the user:

**Conversation forked successfully!**

- Original: `{cwd}` (unchanged)
- Fork: `{target_dir}`

To resume the forked conversation:
```
cd {target_dir}
claude --resume
```

The forked conversation has full history preserved. Both the original and the fork can continue independently.
