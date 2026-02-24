
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
        p.AnswerCount, p.CommentCount, p.FavoriteCount, u.Reputation
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerReputation,
        VoteCount,
        ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerReputation,
    VoteCount
FROM 
    RecentPosts
WHERE 
    Rank <= 10;
