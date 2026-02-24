
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Owner,
        tp.Score,
        tp.CommentCount,
        tp.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON v.PostId = tp.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Owner, tp.Score, tp.CommentCount, tp.AnswerCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Owner,
    ps.Score,
    ps.CommentCount,
    ps.AnswerCount,
    ps.Upvotes,
    ps.Downvotes,
    (ps.Upvotes - ps.Downvotes) AS NetVotes
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, ps.CommentCount DESC;
