WITH RECURSIVE PostHierarchy AS (
    SELECT Id, ParentId, Title, CreationDate, Score, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL  

    UNION ALL

    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, p.Score, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE 
            WHEN ph.Level = 0 THEN 2 * p.Score      
            WHEN ph.Level = 1 THEN p.Score            
            ELSE 0 END) AS ReputationScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHierarchy ph ON p.Id = ph.Id
    GROUP BY u.Id, u.DisplayName
),
ActiveBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges b
    WHERE b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY b.UserId
),
FinalUserStats AS (
    SELECT 
        u.DisplayName,
        COALESCE(ur.ReputationScore, 0) AS Reputation,
        COALESCE(ab.GoldCount, 0) AS GoldBadges,
        COALESCE(ab.SilverCount, 0) AS SilverBadges,
        COALESCE(ab.BronzeCount, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN ActiveBadges ab ON u.Id = ab.UserId
)
SELECT 
    f.DisplayName, 
    f.Reputation,
    f.GoldBadges, 
    f.SilverBadges, 
    f.BronzeBadges,
    CASE 
        WHEN f.Reputation >= 1000 THEN 'Expert'
        WHEN f.Reputation >= 100 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM FinalUserStats f
ORDER BY f.Reputation DESC
LIMIT 10
OFFSET 5;