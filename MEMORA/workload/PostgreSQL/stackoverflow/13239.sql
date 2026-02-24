WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentTotal,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.CreationDate, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerReputation,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS RankScore
    FROM 
        PostStats
)
SELECT 
    tp.PostId,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    tp.OwnerReputation,
    tp.RankScore
FROM 
    TopPosts tp
WHERE 
    tp.RankScore <= 10;