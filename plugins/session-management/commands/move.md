---
description: Move the current conversation to a different working directory
argument-hint: /path/to/new/directory
allowed-tools: ["Bash", "Read", "AskUserQuestion"]
---

# Move Conversation to New Directory

Move the current conversation to a different working directory. This is useful when you've reorganized your project files and want to continue the conversation from the new location.

## Your Task

### Step 1: Validate Target Directory

The user wants to move this conversation to: `$ARGUMENTS`

**If $ARGUMENTS is empty:**
Use AskUserQuestion to ask:
- question: "Where would you like to move this conversation to?"
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

### Step 4: Check for Conflicts

```bash
# Check if target already has conversations
if ls "$target_project_dir"/*.jsonl 2>/dev/null | head -1 > /dev/null 2>&1; then
  echo "WARNING: Target directory already has existing conversations"
  ls -lt "$target_project_dir"/*.jsonl | head -5
else
  echo "No existing conversations in target directory"
fi
```

### Step 5: Show Summary and Confirm

Before moving, show the user a summary:

- Source directory: `{cwd}`
- Target directory: `{target_dir}`
- Session file to move: `{session_file}`
- File size: `{size}`
- **Note**: The original conversation will be removed from the source directory

Use AskUserQuestion to confirm:
- question: "Ready to move this conversation? The original will be removed."
- description: "This moves the conversation to the target directory. You can resume it by running `claude --resume` from the new directory."

### Step 6: Move the Conversation

Execute the move:

```bash
# Create the target project directory if it doesn't exist
mkdir -p "$target_project_dir"

# Move the session JSONL file
mv "$project_dir/$session_file" "$target_project_dir/$session_file"

# Move the session companion directory if it exists (contains subagent data, tool results)
if [ -d "$project_dir/${session_file%.jsonl}" ]; then
  mv "$project_dir/${session_file%.jsonl}" "$target_project_dir/${session_file%.jsonl}"
fi

echo "Move complete!"
```

### Step 7: Update CWD References in Moved Conversation

After moving, update the `cwd` fields so Claude associates it with the new directory:

```bash
# Update cwd references in the moved JSONL file
sed -i.bak "s|\"cwd\":\"$cwd\"|\"cwd\":\"$target_dir\"|g" "$target_project_dir/$session_file"
rm -f "$target_project_dir/$session_file.bak"
echo "Updated cwd references in moved conversation"
```

### Step 8: Confirm Success

Tell the user:

**Conversation moved successfully!**

- From: `{cwd}`
- To: `{target_dir}`

To resume the moved conversation:
```
cd {target_dir}
claude --resume
```

The conversation retains full history. The original has been removed from the source directory.

**Important**: This current session is still running from the old directory. After this session ends, use the command above to continue from the new location.
