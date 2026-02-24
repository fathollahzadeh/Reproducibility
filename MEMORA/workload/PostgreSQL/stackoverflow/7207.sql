WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score >= 10
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount
FROM 
    PostStatistics ps
JOIN 
    TopPosts tp ON ps.PostId = tp.PostId
ORDER BY 
    ps.UpvoteCount DESC, tp.Score DESC;