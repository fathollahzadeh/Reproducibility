WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(b.Count, 0) AS BadgeCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Most Recent'
            ELSE 'Previous'
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS Count FROM Badges GROUP BY UserId) b ON u.Id = b.UserId 
)
SELECT 
    Title,
    CreationDate,
    OwnerDisplayName,
    OwnerReputation,
    ViewCount,
    Score,
    BadgeCount,
    PostStatus
FROM 
    CombinedData
ORDER BY 
    ViewCount DESC
LIMIT 10;