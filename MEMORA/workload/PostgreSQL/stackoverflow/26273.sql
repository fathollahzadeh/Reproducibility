
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),

RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        (SELECT STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', h.CreationDate, ')'), '; ') 
         FROM PostHistory h 
         JOIN Users u ON h.UserId = u.Id 
         WHERE h.PostId = p.Id 
         AND h.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')) AS RecentEdits,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id 
         AND c.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')) AS RecentCommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    ra.RecentEdits,
    ra.RecentCommentCount
FROM 
    RankedPosts rp
JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.PostRank <= 5  
ORDER BY 
    rp.CreationDate DESC;
