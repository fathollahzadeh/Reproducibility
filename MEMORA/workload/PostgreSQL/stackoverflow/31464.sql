
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score, p.PostTypeId
), 
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        ph.PostId
), 
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS TotalLinks,
        SUM(CASE WHEN lt.Name = 'Duplicate' THEN 1 ELSE 0 END) AS DuplicateLinks
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.ViewCount,
    rp.Score,
    rp.RankScore,
    pha.UniqueEditors,
    pha.LastEditedDate,
    pha.EditComments,
    pls.TotalLinks,
    pls.DuplicateLinks
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
LEFT JOIN 
    PostLinksSummary pls ON rp.PostId = pls.PostId
WHERE 
    (rp.RankScore <= 3 OR rp.CommentCount > 5) 
    AND (rp.ViewCount > 100 OR rp.Score > 10)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;
