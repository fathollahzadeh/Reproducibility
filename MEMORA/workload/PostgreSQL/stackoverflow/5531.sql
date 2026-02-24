WITH UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount, MIN(b.Date) AS FirstBadgeDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(p.ViewCount) AS TotalViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT u.DisplayName, ub.BadgeCount, ps.PostCount, ps.QuestionCount, ps.AnswerCount, ps.TotalViewCount,
           RANK() OVER (ORDER BY ub.BadgeCount DESC, ps.TotalViewCount DESC) AS UserRank
    FROM Users u
    JOIN UserBadges ub ON u.Id = ub.UserId
    JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE ub.BadgeCount > 0 OR ps.PostCount > 0
)
SELECT * 
FROM TopUsers 
WHERE UserRank <= 10
ORDER BY UserRank;
