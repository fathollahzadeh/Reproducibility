WITH UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS BadgeCount, 
           MAX(CASE WHEN Class = 1 THEN Name END) AS GoldBadge, 
           MAX(CASE WHEN Class = 2 THEN Name END) AS SilverBadge, 
           MAX(CASE WHEN Class = 3 THEN Name END) AS BronzeBadge
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS TotalPosts, 
           COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions, 
           COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
           SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT u.Id, 
           u.DisplayName, 
           COALESCE(b.BadgeCount, 0) AS BadgeCount, 
           ps.TotalPosts, 
           ps.Questions, 
           ps.Answers, 
           ps.TotalScore
    FROM Users u
    LEFT JOIN UserBadges b ON u.Id = b.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE u.Reputation > 1000
),
RankedUsers AS (
    SELECT Id, 
           DisplayName, 
           BadgeCount, 
           TotalPosts, 
           Questions, 
           Answers, 
           TotalScore,
           RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
           DENSE_RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM ActiveUsers
)
SELECT *,
       CASE WHEN BadgeCount > 0 THEN 'Active Contributor' ELSE 'Non-contributor' END AS ContributorStatus
FROM RankedUsers
WHERE ScoreRank <= 10
ORDER BY ScoreRank, BadgeRank;
