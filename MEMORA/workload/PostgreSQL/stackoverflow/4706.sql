
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(u.DisplayName, 'Anonymous') AS Owner
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5
),
CommentsSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        cs.CommentCount,
        cs.LastCommentDate,
        CASE 
            WHEN cs.CommentCount > 5 THEN 'Highly Discussed'
            WHEN cs.CommentCount BETWEEN 3 AND 5 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionType
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentsSummary cs ON tp.PostId = cs.PostId
)
SELECT 
    pd.*,
    COALESCE(ph.Comment, 'No history available') AS PostHistoryComment
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE 
    pd.Score > (
        SELECT AVG(Score) FROM Posts
    )
ORDER BY 
    pd.ViewCount DESC
LIMIT 10;
