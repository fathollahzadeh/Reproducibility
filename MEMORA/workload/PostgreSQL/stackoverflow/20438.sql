
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, 
        ph.PostHistoryTypeId
    HAVING 
        COUNT(*) > 1
),
UserPostInfo AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.CreationDate) AS LastPostDate,
        MIN(p.CreationDate) AS FirstPostDate,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(ph.HistoryCount, 0)) AS TotalHistoryChanges
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryData ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.Views,
    ubc.BadgeCount,
    p.TotalPosts,
    p.PositivePosts,
    p.NegativePosts,
    p.AverageScore,
    pii.LastPostDate,
    pii.TotalHistoryChanges,
    CASE 
        WHEN pii.TotalPosts = 0 THEN 'No posts' 
        ELSE CAST((SELECT COUNT(*) FROM Comments c WHERE c.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.UserId)) AS TEXT) 
    END AS TotalComments
FROM 
    RankedUsers u
LEFT JOIN 
    UserBadgeCounts ubc ON u.UserId = ubc.UserId
LEFT JOIN 
    PostStats p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    UserPostInfo pii ON u.UserId = pii.OwnerUserId
WHERE 
    u.ReputationRank <= 50
ORDER BY 
    u.Reputation DESC NULLS LAST;
