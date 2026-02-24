WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE(UPPER(STRING_AGG(pt.Name, ', ')), 'No Post Type') AS PostTypeNames
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate,
        STRING_AGG(CASE WHEN CHAR_LENGTH(c.Text) < 40 THEN c.Text ELSE SUBSTRING(c.Text, 1, 37) || '...' END, '; ') AS SampleComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS TotalHistoryEntries,
        MAX(ph.CreationDate) AS LastHistoryChange
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rc.CommentCount,
    rc.LastCommentDate,
    rc.SampleComments,
    phd.HistoryTypes,
    phd.TotalHistoryEntries,
    phd.LastHistoryChange,
    (CASE 
        WHEN rp.RankScore <= 5 THEN 'Top Post'
        WHEN rp.RankScore <= 10 THEN 'Mid Tier Post'
        ELSE 'Low Tier Post' 
    END) AS PostRankCategory,
    (CASE 
        WHEN phd.TotalHistoryEntries IS NULL THEN 'No Changes'
        WHEN phd.LastHistoryChange < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Stale Post'
        ELSE 'Active Post' 
    END) AS PostActivityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Score > (SELECT AVG(Score) FROM Posts) 
    OR EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = rp.PostId AND v.VoteTypeId IN (2, 8) 
    )
    AND (rc.CommentCount IS NULL OR rc.CommentCount > 5)
ORDER BY 
    rp.Score DESC, rc.LastCommentDate DESC
LIMIT 100;