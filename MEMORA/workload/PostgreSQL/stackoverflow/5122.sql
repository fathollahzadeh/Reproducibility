
WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
), 
PostStatistics AS (
    SELECT OwnerUserId, COUNT(*) AS PostCount, SUM(ViewCount) AS TotalViews, AVG(Score) AS AvgScore
    FROM Posts
    WHERE CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY OwnerUserId
),
CommentDetails AS (
    SELECT PostId, COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY PostId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, ub.BadgeCount, ps.PostCount, ps.TotalViews, ps.AvgScore, COALESCE(cd.CommentCount, 0) AS CommentCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN CommentDetails cd ON cd.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    WHERE u.Reputation > 1000
    ORDER BY u.Reputation DESC
    LIMIT 10
)
SELECT tu.DisplayName, tu.Reputation, tu.BadgeCount, tu.PostCount, tu.TotalViews, tu.AvgScore, tu.CommentCount
FROM TopUsers tu;
