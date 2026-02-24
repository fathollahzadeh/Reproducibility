WITH RecursiveTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation'
            WHEN u.Reputation >= 100 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationLevel
    FROM 
        Users u
),
ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment,
        u.DisplayName AS ClosedBy
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    p.Title AS PostTitle,
    p.ViewCount,
    t.TagCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    ur.ReputationLevel,
    pp.ClosedDate,
    pp.ClosedBy
FROM 
    Posts p
JOIN 
    RecursiveTagCounts t ON p.Id = t.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ClosedPostHistory pp ON p.Id = pp.PostId
WHERE 
    t.TagCount >= 3
    AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND (u.Reputation > 500 OR pp.ClosedDate IS NOT NULL)
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 50;