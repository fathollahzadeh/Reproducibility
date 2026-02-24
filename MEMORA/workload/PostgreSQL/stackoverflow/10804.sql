
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        CommentCount,
        VoteCount,
        RANK() OVER (ORDER BY VoteCount DESC) AS VoteRank,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    VoteCount,
    CommentCount,
    VoteRank,
    CommentRank
FROM 
    TopPosts
WHERE 
    VoteRank <= 10 OR CommentRank <= 10
ORDER BY 
    VoteRank, CommentRank;
