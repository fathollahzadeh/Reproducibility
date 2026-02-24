WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
TopUsers AS (
    SELECT UserId, Reputation
    FROM UserReputation
    WHERE ReputationRank <= 100
),
PostScore AS (
    SELECT 
        p.OwnerUserId, 
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
UserPosts AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS TotalPosts
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
    HAVING COUNT(p.Id) > 10
),
CombinedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(br.Reputation, 0) AS Reputation,
        COALESCE(ps.TotalScore, 0) AS PostScore,
        COALESCE(bd.BadgeCount, 0) AS BadgeCount,
        COALESCE(up.TotalPosts, 0) AS TotalPosts
    FROM Users u
    LEFT JOIN UserReputation br ON u.Id = br.UserId
    LEFT JOIN PostScore ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadges bd ON u.Id = bd.UserId
    LEFT JOIN UserPosts up ON u.Id = up.OwnerUserId
    WHERE u.Reputation > 0
),
FilteredResults AS (
    SELECT 
        cd.UserId,
        cd.DisplayName,
        cd.Reputation,
        cd.PostScore,
        cd.BadgeCount,
        cd.TotalPosts,
        CASE 
            WHEN cd.Reputation > 10000 THEN 'High'
            WHEN cd.Reputation > 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationCategory
    FROM CombinedData cd
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.PostScore,
    f.BadgeCount,
    f.TotalPosts,
    f.ReputationCategory,
    CASE 
        WHEN f.TotalPosts IS NULL THEN 'No Posts'
        WHEN f.TotalPosts BETWEEN 1 AND 10 THEN 'Few Posts'
        ELSE 'Active User' 
    END AS UserActivityStatus,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM FilteredResults f
LEFT JOIN Posts p ON f.UserId = p.OwnerUserId
LEFT JOIN LATERAL (
    SELECT 
        DISTINCT TRIM(UNNEST(REGEXP_SPLIT_TO_ARRAY(p.Tags, '><'))) AS TagName 
    ) t ON true 
WHERE f.PostScore > 100
GROUP BY 
    f.UserId, 
    f.DisplayName, 
    f.Reputation, 
    f.PostScore, 
    f.BadgeCount, 
    f.TotalPosts, 
    f.ReputationCategory
ORDER BY f.Reputation DESC, f.UserId;