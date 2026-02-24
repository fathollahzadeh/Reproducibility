
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        p.FavoriteCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COUNT(c.Id) AS CommentCountAggregate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(h.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.Score, p.ViewCount, p.AnswerCount, p.FavoriteCount, u.Reputation
)
SELECT 
    PostId,
    PostTypeId,
    Score,
    ViewCount,
    AnswerCount,
    CommentCountAggregate AS CommentCount,
    FavoriteCount,
    OwnerReputation,
    UpVotes,
    DownVotes,
    HistoryCount
FROM 
    PostStats
ORDER BY 
    Score DESC, ViewCount DESC;
