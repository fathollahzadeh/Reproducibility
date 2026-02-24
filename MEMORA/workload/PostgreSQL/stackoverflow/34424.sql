
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        Score,
        CreationDate,
        OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY Score DESC) AS Rank1
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ph.Rank
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 8) 
    GROUP BY 
        u.Id, u.DisplayName
),
LatestEdits AS (
    SELECT 
        p.Id AS PostId,
        COUNT(h.Id) AS EditCount,
        MAX(h.CreationDate) AS LastEditDate
    FROM 
        Posts p 
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    WHERE 
        h.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalBounty,
    u.PositivePosts,
    ph.Title AS TopPost,
    ph.Score AS TopPostScore,
    le.EditCount,
    le.LastEditDate
FROM 
    UserEngagement u
LEFT JOIN 
    PostHierarchy ph ON u.UserId = ph.OwnerUserId AND ph.Rank = 1
LEFT JOIN 
    LatestEdits le ON ph.Id = le.PostId
WHERE 
    u.PostCount > 10
ORDER BY 
    u.TotalBounty DESC, u.PositivePosts DESC;
