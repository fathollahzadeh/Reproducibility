
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),

PostLinksInfo AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerName,
    rp.CommentCount,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEditDate,
    COALESCE(pli.RelatedPostCount, 0) AS RelatedPostCount,
    CASE 
        WHEN rp.RankScore <= 5 THEN 'Top 5'
        WHEN rp.RankScore <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS PostRankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
LEFT JOIN 
    PostLinksInfo pli ON rp.Id = pli.PostId
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
