WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank 
    FROM Users
),
PopularPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS OwnerPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
UserBadges AS (
    SELECT b.UserId, COUNT(b.Id) AS BadgeCount 
    FROM Badges b
    GROUP BY b.UserId
),
PostLinksCount AS (
    SELECT pl.PostId, COUNT(pl.RelatedPostId) AS LinkCount
    FROM PostLinks pl
    GROUP BY pl.PostId
),
TopUsers AS (
    SELECT u.Id as UserId, u.DisplayName, ur.Reputation, ub.BadgeCount 
    FROM UserReputation ur
    JOIN Users u ON ur.Id = u.Id
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId 
    WHERE ur.ReputationRank <= 10
)
SELECT tu.UserId, tu.DisplayName, tu.Reputation, tu.BadgeCount,
       COUNT(DISTINCT pp.Id) AS TotalPosts, 
       SUM(COALESCE(plc.LinkCount, 0)) AS TotalLinks,
       SUM(CASE WHEN pp.OwnerPostRank = 1 THEN 1 ELSE 0 END) AS MostViewedPostCount
FROM TopUsers tu
JOIN PopularPosts pp ON tu.UserId = pp.OwnerUserId
LEFT JOIN PostLinksCount plc ON pp.Id = plc.PostId
GROUP BY tu.UserId, tu.DisplayName, tu.Reputation, tu.BadgeCount
ORDER BY tu.Reputation DESC, TotalPosts DESC;
