
WITH RecursiveTopUsers AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation > 0
),
UserBadges AS (
    SELECT b.UserId, 
           COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostSummary AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS TotalPosts,
           SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
JoinUserData AS (
    SELECT u.DisplayName, 
           u.Reputation, 
           COALESCE(ps.TotalPosts, 0) AS TotalPosts, 
           COALESCE(ps.TotalScore, 0) AS TotalScore,
           COALESCE(ub.GoldBadges, 0) AS GoldBadges,
           COALESCE(ub.SilverBadges, 0) AS SilverBadges,
           COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 1000
),
TopTenUsers AS (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM JoinUserData
)
SELECT tu.DisplayName,
       tu.TotalPosts,
       tu.TotalScore,
       tu.GoldBadges,
       tu.SilverBadges,
       tu.BronzeBadges,
       CASE 
           WHEN tu.TotalPosts > 0 THEN ROUND(tu.TotalScore / tu.TotalPosts, 2)
           ELSE 0 
       END AS AverageScorePerPost
FROM TopTenUsers tu
WHERE tu.UserRank <= 10
ORDER BY tu.Reputation DESC;
