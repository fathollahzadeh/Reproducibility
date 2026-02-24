
WITH UserReputation AS (
    SELECT Id, Reputation, UpVotes, DownVotes,
           (UpVotes - DownVotes) AS NetVotes,
           CreationDate AS AccountAge
    FROM Users
), 
PostStats AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(ViewCount) AS TotalViews,
           SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
BadgeCounts AS (
    SELECT UserId, COUNT(*) AS TotalBadges,
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT u.DisplayName, ur.Reputation, ur.NetVotes, ur.AccountAge,
       ps.TotalPosts, ps.Questions, ps.Answers, ps.TotalViews, ps.TotalScore,
       COALESCE(bc.TotalBadges, 0) AS TotalBadges,
       COALESCE(bc.GoldBadges, 0) AS GoldBadges,
       COALESCE(bc.SilverBadges, 0) AS SilverBadges,
       COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
FROM UserReputation ur
JOIN PostStats ps ON ur.Id = ps.OwnerUserId
LEFT JOIN BadgeCounts bc ON ur.Id = bc.UserId
JOIN Users u ON ur.Id = u.Id
WHERE ur.Reputation > 1000
ORDER BY ur.Reputation DESC, ps.TotalViews DESC
LIMIT 50;
