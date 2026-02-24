WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 AND 
        rp.Score > 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.Title,
    u.DisplayName AS Owner,
    fp.CreationDate,
    fp.Score,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEditDate,
    (SELECT 
        string_agg(DISTINCT c.UserDisplayName, ', ') 
     FROM 
        Comments c 
     WHERE 
        c.PostId = fp.Id) AS Commenters,
    CASE 
        WHEN fp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryStats phs ON fp.Id = phs.PostId
WHERE 
    fp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
ORDER BY 
    fp.Score DESC
LIMIT 50;