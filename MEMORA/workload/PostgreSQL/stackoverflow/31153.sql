
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    GROUP BY 
        u.Id
),
PostInteractions AS (
    SELECT 
        Ph.PostId,
        COUNT(CASE WHEN Ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN Ph.PostHistoryTypeId IN (1, 2, 4, 6) THEN 1 END) AS EditCount,  
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        PostHistory Ph
    LEFT JOIN 
        Comments c ON Ph.PostId = c.PostId
    GROUP BY 
        Ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    ur.TotalReputation,
    pi.CloseCount,
    pi.EditCount,
    pi.CommentCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostInteractions pi ON rp.PostId = pi.PostId
WHERE 
    rp.rn = 1  
ORDER BY 
    ur.TotalReputation DESC,
    rp.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
