# TODO Validation Plan

## Objective
Systematically audit all 56 TODO items to determine which should be kept, removed, or converted to work items.

## Validation Strategy

### Phase 1: Automated File Usage Analysis
**Goal:** Identify TODOs in dead/abandoned code

**Checks:**
1. **File Import Analysis**
   - Search codebase for files that import each TODO-containing file
   - Flag files with ZERO imports (likely dead code)
   - Check if file is in production code paths

2. **Class/Function Reference Analysis**
   - Extract class/function names from TODO-containing files
   - Grep for usage across codebase
   - Flag classes/functions with ZERO references

3. **Commented Code Detection**
   - Identify files that are >80% commented out
   - Flag entire class/file comment-outs (NostrVideoBridge, VideoPerformanceMonitor, etc.)

4. **Test Coverage**
   - Check if TODO-containing files have corresponding test files
   - Check if tests actually run (not skipped/commented out)

### Phase 2: Manual Validation Criteria
**Goal:** Categorize each TODO based on context

**Decision Tree:**

```
Is the entire file/class commented out?
├── YES → DELETE TODO (abandoned code)
└── NO → Continue...
    │
    Does TODO reference deleted interfaces/classes?
    ├── YES → DELETE TODO (no longer applicable)
    └── NO → Continue...
        │
        Is file actively imported/used?
        ├── NO → DELETE TODO (dead code)
        └── YES → Continue...
            │
            Is TODO blocking core features?
            ├── YES → CONVERT TO ISSUE (track as work item)
            └── NO → Continue...
                │
                Is TODO explanatory vs actionable?
                ├── Explanatory → CONVERT TO COMMENT
                └── Actionable → KEEP or CONVERT TO ISSUE
```

### Phase 3: Categorization Rules

**DELETE** - Remove TODO entirely:
- File is >80% commented out (NostrVideoBridge, VideoPerformanceMonitor)
- TODO references deleted interfaces (IVideoManager, VideoState, etc.)
- File has ZERO imports across codebase
- Class/function has ZERO references

**KEEP AS TODO** - Leave as inline comment:
- TODO is explanatory note about architecture decisions
- TODO marks intentional simplification for MVP
- TODO documents known limitations (not urgent)

**CONVERT TO ISSUE** - Create GitHub issue, keep TODO reference:
- TODO blocks core user features (video publishing, hashtag feeds, profile feeds)
- TODO represents significant refactoring work (>4 hours)
- TODO has clear implementation path and requirements

**CONVERT TO COMMENT** - Rewrite as regular comment:
- TODO is documentation, not actionable work
- TODO describes "why" not "what needs doing"
- Example: "TODO: This could be optimized but not needed for MVP"
  → Becomes: "// Note: Could be optimized in future if needed"

### Phase 4: Validation Script

**Purpose:** Automate file usage detection and categorization

**Script Functionality:**
1. Parse all TODO items from grep output
2. For each TODO:
   - Extract file path
   - Check if file is imported anywhere (`grep -r "import.*filename"`)
   - Extract class/function names and check references
   - Calculate "commented code percentage"
   - Flag potential dead code
3. Generate categorized report with recommendations

**Output Format:**
```
TODO: [description]
File: [path:line]
Status: [ACTIVE_CODE | LIKELY_DEAD | COMMENTED_OUT]
Imports: [N files import this]
References: [N references found]
Recommendation: [DELETE | KEEP | CONVERT_TO_ISSUE | CONVERT_TO_COMMENT]
Reason: [automated analysis + manual validation needed]
```

## Execution Plan

### Step 1: Run Validation Script
- Generate automated analysis of all 56 TODOs
- Flag high-confidence DELETE candidates (commented files, zero imports)
- Flag high-confidence CONVERT_TO_ISSUE candidates (core features)

### Step 2: Manual Review by Category
Review automated recommendations by category:

**Technical Debt (21 items):**
- Focus on NostrVideoBridge (6 TODOs) - file is 100% commented
- Focus on VideoPerformanceMonitor (5 TODOs) - depends on deleted IVideoManager
- Focus on VideoPreviewTile (4 TODOs) - check if actively used

**Critical Path (4 items):**
- Video publishing (vine_preview_screen_pure.dart:365)
- Platform notifications (notification_service.dart:93)
- Hashtag feeds (hashtag_feed_providers.dart:22)
- Profile feeds (profile_feed_providers.dart:22)
- **Action:** All should be CONVERT_TO_ISSUE

**User-Facing Features (10 items):**
- Manual review each for MVP priority
- Decide KEEP vs CONVERT_TO_ISSUE based on release timeline

### Step 3: Execute Cleanup
For each category:

**DELETE (estimated 15-20 TODOs):**
- Remove TODO comment entirely
- If entire file is dead, consider deleting file too

**CONVERT_TO_ISSUE (estimated 10-15 TODOs):**
- Create GitHub issue with:
  - Original TODO context
  - File location
  - Requirements (from detailed report)
  - Effort estimate
- Update TODO to reference issue: `// TODO(#123): Original text`

**CONVERT_TO_COMMENT (estimated 5-8 TODOs):**
- Rewrite as explanatory comment (no TODO keyword)

**KEEP (estimated 8-12 TODOs):**
- Leave as-is (intentional notes for future work)

### Step 4: Validation
- Run grep to confirm TODO count reduction
- Run `flutter analyze` to ensure no broken references
- Run `flutter test` to ensure all tests pass
- Update `/tmp/todo_report.md` with final state

## Success Metrics

**Before:**
- 56 total TODOs (31 excluding generated files)
- Mix of actionable work items and documentation notes
- Unclear which are valid vs abandoned

**After:**
- ~15-25 TODOs remaining (valid work items and notes)
- All remaining TODOs are in active code with clear purpose
- 10-15 GitHub issues created for trackable work
- Zero TODOs in commented-out or dead code

## Risk Assessment

**Low Risk:**
- Deleting TODOs from 100% commented files (NostrVideoBridge)
- Converting critical path items to issues (video publishing, hashtag/profile feeds)

**Medium Risk:**
- Deleting TODOs from files with low import count (need manual verification)
- Converting explanatory TODOs to comments (may lose searchability)

**High Risk:**
- Deleting TODOs that reference future architectural decisions
- Deleting TODOs in files with low usage but important edge cases

**Mitigation:**
- Run validation script first for high-confidence candidates
- Manual review for anything with medium/high risk
- Keep git history for easy revert if needed
- Ask Rabble before deleting any TODO in file with >2 imports

## Timeline Estimate

**Phase 1 (Automated Analysis):** 30 minutes
- Write validation script
- Run analysis
- Generate categorized report

**Phase 2 (Manual Review):** 1 hour
- Review automated recommendations
- Manual validation of medium-risk items
- Get Rabble approval for deletion candidates

**Phase 3 (Execution):** 1 hour
- Delete TODOs in dead code
- Create GitHub issues for work items
- Convert explanatory TODOs to comments
- Update documentation

**Phase 4 (Validation):** 15 minutes
- Run tests and analysis
- Verify TODO count reduction
- Update reports

**Total:** ~2.75 hours

## Next Steps

1. **Rabble Review:** Get approval on validation strategy and categorization rules
2. **Write Script:** Create Dart/Bash validation script for automated analysis
3. **Run Analysis:** Generate categorized recommendations
4. **Manual Review:** Present findings to Rabble for deletion approval
5. **Execute Cleanup:** Remove dead TODOs, create issues, convert comments
6. **Validate:** Confirm tests pass and TODO count reduced
