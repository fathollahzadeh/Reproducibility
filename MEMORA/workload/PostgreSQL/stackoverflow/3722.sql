
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Anonymous') AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year')
),

RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 month')
    GROUP BY 
        c.PostId
),

PostHistoryFiltered AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '6 months')
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Author,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    rc.LastCommentDate,
    COALESCE(phf.HistoryComments, 'No history') AS PostHistory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    PostHistoryFiltered phf ON rp.PostId = phf.PostId
WHERE 
    rp.rn = 1 
    AND rp.Score > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
