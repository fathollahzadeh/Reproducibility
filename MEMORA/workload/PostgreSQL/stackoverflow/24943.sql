
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) OVER (PARTITION BY p.Id) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) OVER (PARTITION BY p.Id) AS DeletionCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '5 years')
    AND 
        p.ViewCount > 100
),
UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        UNNEST(SPLIT_PART(Tags, '><', NULL)::TEXT[]) AS Tag
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
)
SELECT 
    p.Title,
    p.Rank,
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    pt.Tag,
    p.ViewCount,
    CASE
        WHEN p.LastClosedDate IS NOT NULL THEN 'Closed post'
        WHEN p.DeletionCount > 0 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts p
JOIN 
    UserStats u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PopularTags pt ON p.Title ILIKE '%' || pt.Tag || '%'
WHERE 
    p.Rank <= 3
ORDER BY 
    p.ViewCount DESC,
    p.Score DESC;
