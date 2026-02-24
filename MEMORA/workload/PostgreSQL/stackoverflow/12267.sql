
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        p.LastActivityDate,
        u.Id AS OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, p.CreationDate, p.LastActivityDate, u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        CreationDate,
        LastActivityDate,
        OwnerUserId,
        OwnerDisplayName,
        VoteCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    CreationDate,
    LastActivityDate,
    OwnerUserId,
    OwnerDisplayName,
    VoteCount
FROM 
    TopPosts
WHERE 
    Rank <= 10;
