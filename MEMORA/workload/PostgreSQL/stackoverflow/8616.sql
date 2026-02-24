WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    r.OwnerDisplayName,
    COALESCE(pht.Name, 'N/A') AS PostHistoryType,
    COUNT(DISTINCT ph.Id) AS RevisionCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
FROM 
    RankedPosts r
LEFT JOIN 
    PostHistory ph ON r.PostId = ph.PostId 
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    Votes v ON r.PostId = v.PostId
WHERE 
    r.RankScore <= 5 
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount, r.AnswerCount, r.CommentCount, r.OwnerDisplayName, pht.Name 
ORDER BY 
    r.Score DESC, r.ViewCount DESC;