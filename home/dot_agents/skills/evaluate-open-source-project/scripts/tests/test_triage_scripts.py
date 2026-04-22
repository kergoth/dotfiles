from datetime import date

from triage.contributors import summarize_contributors
from triage.issues import summarize_issues
from triage.prs import summarize_prs
from triage.releases import summarize_releases


def test_summarize_releases_reports_recent_gap():
    releases = [
        {"published_at": date(2026, 4, 10)},
        {"published_at": date(2026, 3, 1)},
    ]

    summary = summarize_releases(releases, today=date(2026, 4, 22))

    assert summary["count"] == 2
    assert summary["days_since_latest"] == 12


def test_summarize_issues_reports_stale_open_count():
    issues = [
        {"state": "open", "days_to_first_response": 1, "days_open": 45},
        {"state": "closed", "days_to_first_response": 4, "days_open": 10},
    ]

    summary = summarize_issues(issues)

    assert summary["stale_open"] == 1
    assert summary["median_first_response_days"] == 2.5


def test_summarize_prs_reports_external_merge_ratio():
    prs = [
        {"author_association": "CONTRIBUTOR", "merged": True, "days_to_review": 2},
        {"author_association": "OWNER", "merged": False, "days_to_review": 0},
        {"author_association": "CONTRIBUTOR", "merged": False, "days_to_review": 30},
    ]

    summary = summarize_prs(prs)

    assert summary["external_prs"] == 2
    assert summary["external_merged"] == 1
    assert summary["stale_external_prs"] == 1


def test_summarize_contributors_reports_top_author_share():
    contributors = [
        {"author": "alice", "commits": 8},
        {"author": "bob", "commits": 2},
    ]

    summary = summarize_contributors(contributors)

    assert summary["distinct_authors"] == 2
    assert summary["top_author_share"] == 0.8
