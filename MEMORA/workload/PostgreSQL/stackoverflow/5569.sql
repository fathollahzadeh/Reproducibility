WITH UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, SUM(p.Score) AS TotalScore, 
           SUM(p.ViewCount) AS TotalViews, AVG(p.AnswerCount) AS AverageAnswers
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT ur.UserId, ur.DisplayName, ur.Reputation, ur.BadgeCount, 
           ps.PostCount, ps.TotalScore, ps.TotalViews, ps.AverageAnswers
    FROM UserReputation ur
    JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
)
SELECT cs.DisplayName, cs.Reputation, cs.BadgeCount, cs.PostCount, cs.TotalScore, 
       cs.TotalViews, cs.AverageAnswers
FROM CombinedStats cs
ORDER BY cs.Reputation DESC, cs.TotalScore DESC
LIMIT 10;