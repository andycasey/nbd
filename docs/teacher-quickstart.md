# Teacher Quickstart Guide

Complete walkthrough for creating and distributing your first assignment using the Jupyter Notebook Grading System.

## Prerequisites

Before starting, make sure you've completed:
- [x] GCP setup ([setup/gcp-setup.md](../setup/gcp-setup.md))
- [x] Apps Script deployed and tested
- [x] nbgrader installed locally: `pip install nbgrader`

## One-Time Setup: nbgrader Course

### 1. Initialize nbgrader Course Directory

```bash
# Create course directory
mkdir -p ~/my-course
cd ~/my-course

# Initialize nbgrader
nbgrader quickstart my-course --force
```

This creates the following structure:
```
my-course/
├── source/           # Instructor notebooks (with solutions)
├── release/          # Student notebooks (solutions removed)
├── submitted/        # Student submissions (for local grading)
├── autograded/       # Graded notebooks
├── feedback/         # Feedback for students
└── nbgrader_config.py
```

### 2. Configure nbgrader

Edit `nbgrader_config.py`:

```python
c = get_config()

# Course information
c.CourseDirectory.course_id = "my-course"

# DB settings (using SQLite for local development)
c.CourseDirectory.db_url = "sqlite:///gradebook.db"

# Execution timeout (increase for complex notebooks)
c.ExecutePreprocessor.timeout = 300

# Allow cells to raise errors during execution
c.ExecutePreprocessor.allow_errors = True
```

## Creating Your First Assignment

### Step 1: Create Instructor Notebook (30-60 minutes)

1. **Start Jupyter:**
   ```bash
   cd ~/my-course/source
   mkdir assignment1
   cd assignment1
   jupyter notebook
   ```

2. **Create new notebook:** `assignment1.ipynb`

3. **Enable nbgrader toolbar:**
   - View → Cell Toolbar → Create Assignment

4. **Create assignment content:**

Example structure:

**Cell 1 - Instructions (Markdown):**
```markdown
# Assignment 1: Introduction to Python

Complete the following exercises. Do not modify the test cells.

## Problem 1: Basic Math (5 points)

Write a function `add_numbers(a, b)` that returns the sum of two numbers.
```

**Cell 2 - Solution Cell (Code):**
```python
### BEGIN SOLUTION
def add_numbers(a, b):
    """Add two numbers and return the result."""
    return a + b
### END SOLUTION
```

In the nbgrader toolbar for this cell:
- Select: "Autograded answer"
- Grade ID: `problem1`
- Points: `0` (points are in the test, not the solution)

**Cell 3 - Test Cell (Code):**
```python
# Test cases for problem1
assert add_numbers(2, 3) == 5, "Failed: 2 + 3 should equal 5"
assert add_numbers(-1, 1) == 0, "Failed: -1 + 1 should equal 0"
assert add_numbers(0, 0) == 0, "Failed: 0 + 0 should equal 0"
print("✓ All tests passed!")
```

In the nbgrader toolbar for this cell:
- Select: "Autograded tests"
- Grade ID: `problem1_tests`
- Points: `5`

**Repeat for additional problems...**

5. **Save notebook:** Ctrl+S / Cmd+S

### Step 2: Validate Notebook (2 minutes)

Test that your notebook works:

```bash
cd ~/my-course
nbgrader validate source/assignment1/assignment1.ipynb
```

Should output:
```
[ValidateApp | INFO] Validating 'source/assignment1/assignment1.ipynb'
[ValidateApp | INFO] ✓ All tests passed!
```

If validation fails:
- Check for syntax errors
- Verify all test cells execute successfully
- Make sure nbgrader metadata is set correctly

### Step 3: Generate Student Version (30 seconds)

```bash
cd ~/my-course
nbgrader generate_assignment assignment1
```

This creates: `release/assignment1/assignment1.ipynb`

**What changed:**
- Solution code replaced with:
  ```python
  def add_numbers(a, b):
      # YOUR CODE HERE
      raise NotImplementedError()
  ```
- Hidden test cells removed (if any)
- Checksums added to prevent tampering

**Preview student version:**
```bash
jupyter notebook release/assignment1/assignment1.ipynb
```

### Step 4: Upload to Google Drive (2 minutes)

**Option A: Manual Upload**

1. Open [Google Drive](https://drive.google.com)
2. Create folder: `Course Assignments` (if not exists)
3. Create subfolder: `assignment1`
4. Upload `release/assignment1/assignment1.ipynb`
5. Right-click notebook → Get link → Copy link
6. Extract file ID from URL:
   ```
   https://drive.google.com/file/d/FILE_ID_HERE/view
   ```

**Option B: Upload via Command Line (requires `gdrive` CLI)**

```bash
# Install gdrive: brew install gdrive
gdrive upload release/assignment1/assignment1.ipynb \
  --parent COURSE_FOLDER_ID
```

### Step 5: Create Invite Link (1 minute)

1. Open your [Teacher Dashboard](https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec)

2. Fill out "Create New Assignment" form:
   - Assignment Name: `Assignment 1 - Introduction to Python`
   - Notebook File ID: `FILE_ID_FROM_STEP_4`
   - Deadline: `2026-03-01T23:59` (optional)

3. Click "Create Assignment & Generate Link"

4. **Copy the invite link** - it looks like:
   ```
   https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec?assignment=UUID
   ```

### Step 6: Share with Students (5 minutes)

**Via LMS (Canvas/Moodle):**

1. Create new assignment in your LMS
2. Assignment name: `Assignment 1 - Introduction to Python`
3. Due date: Match the deadline you set
4. Instructions:
   ```
   Click the link below to access the assignment notebook.

   [Open Assignment in Google Colab](YOUR_INVITE_LINK)

   Instructions:
   1. Click the link above
   2. Grant Google Drive access when prompted
   3. Complete the assignment in Google Colab
   4. Save your work (Ctrl+S or Cmd+S)
   5. Your submission is automatically saved to your Google Drive
      and shared with the instructor

   Do not modify test cells or you will receive zero credit.
   ```

**Via Email:**

Subject: `Assignment 1 - Introduction to Python`
Body: (same as above)

## Monitoring Submissions

### Real-time Monitoring

1. Open Teacher Dashboard
2. Click "Refresh" in "Your Assignments" section
3. View list of students who have accessed the assignment
4. Check timestamps to see when they started

### Check Submissions in Google Sheets

1. Open your NBD Database Sheet
2. Go to "Submissions" tab
3. See all submissions with:
   - Assignment ID
   - Student email
   - Notebook File ID (link to student's work)
   - Timestamp
   - Grade (populated after grading)

### View Individual Student Work

1. In Submissions sheet, click on "Notebook File ID"
2. Opens student's notebook in Drive
3. Click "Open with Google Colab" to review their code

## Grading Submissions

### Option A: Automated Grading (Phase 2)

**Prerequisites:**
- Cloud Function deployed
- Function URL updated in Apps Script

**Steps:**

1. Open Teacher Dashboard
2. Find assignment in "Your Assignments"
3. Click "Grade All" button
4. Confirm grading action
5. Wait 2-5 minutes (depends on class size)
6. Check email for notification with CSV download link
7. Download CSV with grades

**CSV format:**
```csv
email,score,max_score,percentage,feedback
student1@example.com,45,50,90%,"problem1_tests: PASS (5/5); problem2_tests: PARTIAL (3/5)"
student2@example.com,50,50,100%,"problem1_tests: PASS (5/5); problem2_tests: PASS (5/5)"
```

### Option B: Manual Local Grading (Phase 1)

**Steps:**

1. **Download all submissions:**

In Teacher Dashboard, click "Download All" (or manually from Submissions sheet)

2. **Organize submissions:**

```bash
cd ~/my-course/submitted
mkdir -p assignment1

# For each student, create folder and place their notebook
mkdir -p student1@example.com/assignment1
# Move student1's notebook to this folder
mv ~/Downloads/student1_assignment1.ipynb \
  student1@example.com/assignment1/assignment1.ipynb

# Repeat for all students...
```

3. **Run autograde:**

```bash
cd ~/my-course
nbgrader autograde assignment1
```

4. **Generate feedback (optional):**

```bash
nbgrader feedback assignment1
```

5. **Export grades:**

```bash
nbgrader export
```

Creates `grades.csv` in the current directory.

## Adjusting Grades Manually

### In Google Sheets

1. Open NBD Database Sheet → Submissions tab
2. Find student row
3. Edit "Grade" column
4. Add notes in "Feedback" column

### In CSV

1. Download CSV from email/Drive
2. Open in Excel/Google Sheets
3. Edit scores as needed
4. Re-save as CSV for LMS import

## Importing to LMS

### Canvas

1. Go to assignment → Grades
2. Click "Import" → "Upload CSV"
3. Map columns:
   - `email` → Student Email
   - `score` → Grade
   - `feedback` → Comments
4. Review and confirm import

### Moodle

1. Go to Grades → Import → CSV file
2. Upload CSV
3. Map columns
4. Confirm import

### Gradescope (Manual)

1. Export grades from CSV
2. Manually enter in Gradescope
3. Or use Gradescope API for automation (future enhancement)

## Common Issues & Solutions

### "Invalid assignment link" when students click

**Cause:** Assignment ID not in database or typo in URL

**Fix:**
1. Check Assignments sheet for correct ID
2. Regenerate invite link
3. Make sure students use complete URL (no line breaks)

### Student can't save changes in Colab

**Cause:** Notebook not in student's Drive or permissions issue

**Fix:**
1. Have student click File → Save a copy in Drive
2. Student should grant Drive access when prompted
3. Verify notebook appears in student's Drive

### Test cells fail for all students

**Cause:** Error in test logic or instructor notebook

**Fix:**
1. Re-run instructor notebook locally
2. Verify tests pass with solution code
3. Regenerate student version if needed
4. Notify students of corrected version

### Grading fails with timeout error

**Cause:** Notebook execution takes too long

**Fix:**
1. Increase timeout in `nbgrader_config.py`:
   ```python
   c.ExecutePreprocessor.timeout = 600  # 10 minutes
   ```
2. Or in Cloud Function: Update `deploy.sh` timeout

### Cloud Function out of memory

**Cause:** Too many submissions or large notebooks

**Fix:**
1. Increase memory in `deploy.sh`:
   ```bash
   --memory=2048MB
   ```
2. Process submissions in batches (future enhancement)

## Best Practices

### Notebook Design

✅ **DO:**
- Start with easy problems, progress to harder ones
- Provide clear instructions in markdown cells
- Use descriptive variable names in tests
- Test edge cases (empty inputs, negatives, etc.)
- Give partial credit where possible
- Include expected output examples

❌ **DON'T:**
- Make notebooks too long (>20 problems)
- Use ambiguous test assertions
- Assume students know Jupyter shortcuts
- Skip instructions for non-obvious problems
- Overload single cell with multiple concepts

### Testing Strategy

**Unit tests:**
```python
assert function(input1) == expected1, "Failed case 1"
assert function(input2) == expected2, "Failed case 2"
```

**Type checking:**
```python
result = function(x)
assert isinstance(result, list), "Should return a list"
assert len(result) == 5, "Should have 5 elements"
```

**Approximate equality (for floats):**
```python
import math
result = compute_pi()
assert math.isclose(result, 3.14159, rel_tol=1e-5), "Pi approximation too far off"
```

### Student Communication

**First assignment announcement:**
```
Important: How to Access Assignments

1. All assignments will be distributed via Google Colab
2. You need a Google account (use your university email if possible)
3. Your work automatically saves to your Google Drive
4. Do NOT modify test cells - this will result in zero credit
5. Contact me if you have technical issues BEFORE the deadline

The first assignment link will be posted soon. Make sure you can
access Google Drive and Colab before then.
```

**Deadline reminders:**
- Send reminder 2 days before deadline
- Include link to assignment
- Remind about automatic saving
- Provide office hours for help

### Version Control

Keep instructor notebooks in Git:

```bash
cd ~/my-course
git init
git add source/
git commit -m "Initial assignment 1"
```

**Never commit:**
- Student submissions
- Service account keys
- `submitted/`, `autograded/`, `feedback/` directories

Add to `.gitignore`:
```
submitted/
autograded/
feedback/
gradebook.db
*.key.json
```

## Next Steps

- Create Assignment 2 following the same workflow
- Experiment with more complex nbgrader features (hidden tests, manual grading)
- Set up automated deadline enforcement
- Integrate plagiarism detection (Phase 4)

## Support

- **nbgrader docs:** [nbgrader.readthedocs.io](https://nbgrader.readthedocs.io/)
- **Apps Script help:** [developers.google.com/apps-script](https://developers.google.com/apps-script)
- **Report issues:** [GitHub Issues](https://github.com/yourusername/nbd/issues)
