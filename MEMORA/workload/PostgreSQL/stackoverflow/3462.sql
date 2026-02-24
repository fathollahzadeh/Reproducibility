WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 months'
    GROUP BY 
        c.PostId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(rv.VoteCount, 0) AS VoteCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(phi.LastEditDate, '1970-01-01') AS LastEditDate,
    COALESCE(phi.FirstEditDate, '1970-01-01') AS FirstEditDate,
    COALESCE(phi.EditCount, 0) AS EditCount,
    CASE 
        WHEN rp.Score >= 10 THEN 'High'
        WHEN rp.Score BETWEEN 5 AND 9 THEN 'Medium'
        ELSE 'Low'
    END AS PopularityLevel,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'Views data missing'
        WHEN rp.ViewCount < 50 THEN 'Low views'
        WHEN rp.ViewCount <= 200 THEN 'Moderate views'
        ELSE 'High views'
    END AS ViewCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistoryInfo phi ON rp.PostId = phi.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;