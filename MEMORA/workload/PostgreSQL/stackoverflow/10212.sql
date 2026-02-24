
WITH UserPostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgPostScore,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation
    FROM Users u
)

SELECT
    ups.OwnerUserId,
    ups.PostCount,
    ups.AvgPostScore,
    ups.TotalComments,
    ur.Reputation
FROM UserPostStats ups
JOIN UserReputation ur ON ups.OwnerUserId = ur.UserId
ORDER BY ups.PostCount DESC, ur.Reputation DESC;
