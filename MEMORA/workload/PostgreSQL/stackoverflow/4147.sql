WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
), 
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
), 
UserPostDetails AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.PostCount,
        ps.TotalViews,
        ps.AverageScore,
        ROW_NUMBER() OVER (PARTITION BY ur.ReputationRank ORDER BY ur.Reputation DESC) AS RankWithinTier
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
), 
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(ph.Id) AS ClosedCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    upd.DisplayName,
    upd.Reputation,
    COALESCE(upd.PostCount, 0) AS PostCount,
    COALESCE(upd.TotalViews, 0) AS TotalViews,
    COALESCE(upd.AverageScore, 0) AS AverageScore,
    COALESCE(cp.ClosedCount, 0) AS ClosedPostCount,
    CASE 
        WHEN upd.RankWithinTier IS NULL THEN 'Unranked'
        ELSE CAST(upd.RankWithinTier AS VARCHAR)
    END AS RankInTier
FROM 
    UserPostDetails upd
LEFT JOIN 
    ClosedPosts cp ON upd.UserId = cp.OwnerUserId
WHERE 
    (upd.Reputation > 5000 OR cp.ClosedCount > 0)
ORDER BY 
    upd.Reputation DESC, 
    upd.PostCount DESC
LIMIT 100;