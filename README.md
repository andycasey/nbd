# Jupyter Notebook Grading System (NBD)

Browser-based Jupyter notebook grading system for university courses using Google Apps Script, Cloud Functions, and nbgrader.

## Project Goal

Minimize teacher's local setup requirements by maximizing browser-based workflow while automating student notebook distribution and grading.

## Architecture

- **Notebook Preparation:** nbgrader CLI (local, one-time setup)
- **Distribution & UI:** Google Apps Script (browser-based, no server needed)
- **Grading Execution:** Cloud Functions with Python (serverless)
- **Storage:** Google Drive
- **Database:** Google Sheets
- **Authentication:** Google OAuth

## Directory Structure

```
nbd/
├── apps-script/          # Google Apps Script web app
│   ├── Code.gs          # Main logic (doGet handler, utilities)
│   ├── Dashboard.html   # Teacher UI
│   └── appsscript.json  # OAuth scopes and manifest
├── cloud-function/       # Automated grading (Phase 2)
│   ├── main.py          # Grading orchestration
│   ├── requirements.txt # Python dependencies
│   └── deploy.sh        # GCP deployment script
├── notebooks/           # Example notebooks
│   ├── example-instructor-notebook.ipynb
│   └── example-student-notebook.ipynb
├── setup/               # Deployment guides
│   └── gcp-setup.md     # GCP configuration steps
└── docs/                # User documentation
    └── teacher-quickstart.md
```

## Quick Start

See [docs/teacher-quickstart.md](docs/teacher-quickstart.md) for complete setup instructions.

### For Teachers

1. **Initial Setup** (one-time, ~30 minutes):
   - Follow [setup/gcp-setup.md](setup/gcp-setup.md) to configure Google Cloud
   - Deploy Apps Script from `apps-script/` directory
   - Install nbgrader locally: `pip install nbgrader`

2. **Per Assignment** (~5 minutes):
   - Create notebook locally with nbgrader
   - Upload student version to Google Drive
   - Generate invite link from teacher dashboard
   - Share link with students via LMS

3. **Grading** (~2-5 minutes):
   - Click "Grade All" button in dashboard
   - Receive CSV results via email
   - Import to LMS gradebook

### For Students

1. Click invite link from course website
2. Grant Google Drive access
3. Notebook opens automatically in Google Colab
4. Complete and save (auto-saves to your Drive)

## Implementation Phases

- **Phase 1** (Weeks 1-2): Core distribution - students get notebooks via link
- **Phase 2** (Weeks 3-4): Automated grading - click button to grade entire class
- **Phase 3** (Weeks 5-6): Enhanced UX - deadline tracking, manual overrides, feedback
- **Phase 4** (Optional): Advanced features - plagiarism detection, LMS integration

## Cost Estimate

**~$0.60 per semester** for 30 students, 10 assignments (Apps Script free, Cloud Functions ~$0.50)

Scales to ~$10/semester for 500 students.

## Development Status

**Current Phase:** Initial setup

See implementation plan in this README for detailed architecture and next steps.

## License

MIT License - See LICENSE file for details.
