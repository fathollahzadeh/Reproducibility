
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2020-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT * 
    FROM RankedPosts
    WHERE ScoreRank <= 5 
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.OwnerDisplayName,
    p.CommentCount,
    ph.UserDisplayName AS LastEditor,
    ph.CreationDate AS LastEditDate
FROM 
    TopRankedPosts p
LEFT JOIN 
    PostHistory ph ON p.PostId = ph.PostId 
WHERE 
    ph.PostHistoryTypeId IN (4, 5) 
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
