WITH UserBadgeCounts AS (
    SELECT ub.UserId, COUNT(ub.Id) AS BadgeCount
    FROM Badges ub
    GROUP BY ub.UserId
), PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, SUM(p.Score) AS TotalScore, SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
), UserActivity AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, u.CreationDate, 
           COALESCE(bc.BadgeCount, 0) AS BadgeCount, 
           COALESCE(ps.PostCount, 0) AS PostCount, 
           COALESCE(ps.TotalScore, 0) AS TotalScore, 
           COALESCE(ps.TotalViews, 0) AS TotalViews
    FROM Users u
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT 
    ua.UserId, 
    ua.DisplayName, 
    ua.Reputation, 
    ua.CreationDate, 
    ua.BadgeCount, 
    ua.PostCount, 
    ua.TotalScore, 
    ua.TotalViews,
    DENSE_RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank,
    DENSE_RANK() OVER (ORDER BY ua.BadgeCount DESC) AS BadgeRank,
    DENSE_RANK() OVER (ORDER BY ua.TotalScore DESC) AS ScoreRank
FROM UserActivity ua
WHERE ua.Reputation >= 100
ORDER BY ua.Reputation DESC, ua.TotalScore DESC
LIMIT 100;
