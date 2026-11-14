#!/usr/bin/env python3
"""Service desk ticket report.

Reads a ticket export (CSV) and prints a Markdown summary:
  - ticket volume by category
  - average resolution time per priority and SLA compliance
  - first-contact resolution rate (tickets not escalated)
  - recurring issue candidates for problem management

Usage:
    python ticket_report.py ../data/sample_tickets.csv > report.md

Expected columns: ticket_id, category, priority, opened, resolved, escalated
Timestamps use the format YYYY-MM-DD HH:MM. The sample data is fictional.
"""
import csv
import sys
from collections import Counter, defaultdict
from datetime import datetime

# Example SLA targets in hours (adjust to your organisation's service levels)
SLA_HOURS = {"P1": 4, "P2": 8, "P3": 24, "P4": 72}
FMT = "%Y-%m-%d %H:%M"
RECURRING_THRESHOLD = 10  # category with this many tickets is flagged for review


def load(path):
    tickets = []
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            opened = datetime.strptime(row["opened"], FMT)
            resolved = datetime.strptime(row["resolved"], FMT)
            row["hours"] = (resolved - opened).total_seconds() / 3600
            tickets.append(row)
    return tickets


def main(path):
    tickets = load(path)
    total = len(tickets)
    if total == 0:
        print("No tickets found.")
        return

    print("# Service Desk Report\n")
    print(f"Total tickets: **{total}**\n")

    by_cat = Counter(t["category"] for t in tickets)
    print("## Volume by category\n")
    print("| Category | Tickets | Share |")
    print("|---|---|---|")
    for cat, n in by_cat.most_common():
        print(f"| {cat} | {n} | {n / total:.0%} |")

    print("\n## Resolution time and SLA by priority\n")
    print("| Priority | Tickets | Avg hours | SLA (h) | Within SLA |")
    print("|---|---|---|---|---|")
    groups = defaultdict(list)
    for t in tickets:
        groups[t["priority"]].append(t)
    for pr in sorted(groups):
        items = groups[pr]
        avg = sum(i["hours"] for i in items) / len(items)
        sla = SLA_HOURS.get(pr)
        ok = sum(1 for i in items if sla and i["hours"] <= sla)
        pct = f"{ok / len(items):.0%}" if sla else "n/a"
        print(f"| {pr} | {len(items)} | {avg:.1f} | {sla} | {pct} |")

    fcr = sum(1 for t in tickets if t["escalated"].strip().lower() == "no")
    print(f"\n## First-contact resolution\n\n{fcr} of {total} tickets "
          f"({fcr / total:.0%}) were resolved without escalation.\n")

    print("## Problem management candidates\n")
    flagged = [(c, n) for c, n in by_cat.most_common() if n >= RECURRING_THRESHOLD]
    if flagged:
        for cat, n in flagged:
            print(f"- **{cat}**: {n} tickets. Review for root cause, a knowledge base article or self-service.")
    else:
        print("- No category reached the recurring-issue threshold.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python ticket_report.py <tickets.csv>")
    main(sys.argv[1])
