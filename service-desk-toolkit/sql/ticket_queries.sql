-- Example reporting queries for a service desk ticket table.
-- Table: tickets(ticket_id, category, priority, opened, resolved, escalated)
-- Tested with SQLite using data/sample_tickets.csv.

-- 1. Ticket volume by category
SELECT category, COUNT(*) AS tickets
FROM tickets
GROUP BY category
ORDER BY tickets DESC;

-- 2. Average resolution time (hours) by priority
SELECT priority,
       COUNT(*) AS tickets,
       ROUND(AVG((julianday(resolved) - julianday(opened)) * 24), 1) AS avg_hours
FROM tickets
GROUP BY priority
ORDER BY priority;

-- 3. Tickets that breached the example SLA
SELECT ticket_id, priority,
       ROUND((julianday(resolved) - julianday(opened)) * 24, 1) AS hours
FROM tickets
WHERE (priority = 'P1' AND (julianday(resolved) - julianday(opened)) * 24 > 4)
   OR (priority = 'P2' AND (julianday(resolved) - julianday(opened)) * 24 > 8)
   OR (priority = 'P3' AND (julianday(resolved) - julianday(opened)) * 24 > 24)
   OR (priority = 'P4' AND (julianday(resolved) - julianday(opened)) * 24 > 72);

-- 4. First-contact resolution rate
SELECT ROUND(100.0 * SUM(CASE WHEN escalated = 'No' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fcr_percent
FROM tickets;

-- 5. Recurring issues (candidates for problem management)
SELECT category, COUNT(*) AS tickets
FROM tickets
GROUP BY category
HAVING COUNT(*) >= 10
ORDER BY tickets DESC;
