WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.Score > 0 AND 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT c.UserDisplayName) AS Commenters
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
CloseStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pc.Commenters[1], 'No Comments') AS FirstCommenter,
    cs.CloseCount,
    cs.LastClosed,
    CASE 
        WHEN cs.CloseCount IS NULL THEN 'Open'
        WHEN cs.CloseCount > 0 THEN 'Closed'
        ELSE 'N/A' 
    END AS Status,
    NULLIF(rp.RankScore, 0) AS RankScore,
    CASE 
        WHEN rp.RankScore > 10 THEN 'Very Popular'
        WHEN rp.RankScore BETWEEN 5 AND 10 THEN 'Moderately Popular'
        ELSE 'Not Popular'
    END AS PopularityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    CloseStats cs ON rp.PostId = cs.PostId
WHERE 
    rp.RankByUser = 1 
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
LIMIT 50;