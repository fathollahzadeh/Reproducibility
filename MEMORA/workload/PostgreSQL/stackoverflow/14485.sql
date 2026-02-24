
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Id AS OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS TotalComments,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, 
        u.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC) AS RankByScore,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS RankByViewCount,
        RANK() OVER (ORDER BY ps.AnswerCount DESC) AS RankByAnswerCount
    FROM 
        PostStats ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OwnerUserId,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.TotalComments,
    tp.LastVoteDate,
    tp.RankByScore,
    tp.RankByViewCount,
    tp.RankByAnswerCount
FROM 
    TopPosts tp
WHERE 
    tp.RankByScore <= 10 OR
    tp.RankByViewCount <= 10 OR
    tp.RankByAnswerCount <= 10
ORDER BY 
    tp.RankByScore, tp.RankByViewCount, tp.RankByAnswerCount;
