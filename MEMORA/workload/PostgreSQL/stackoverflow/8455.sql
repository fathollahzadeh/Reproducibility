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
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
        AND p.Score > 0
), PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        RankedPosts rp
        LEFT JOIN Votes v ON rp.PostId = v.PostId
        LEFT JOIN Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.VoteCount,
    pm.CommentCount,
    pm.Upvotes,
    pm.Downvotes,
    rp.Rank
FROM 
    PostMetrics pm
    JOIN RankedPosts rp ON pm.PostId = rp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    pm.Upvotes DESC, pm.CommentCount DESC;
