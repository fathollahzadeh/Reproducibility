
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        CommentCount,
        VoteCount,
        OwnerDisplayName,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        RecentPosts
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    CommentCount,
    VoteCount,
    OwnerDisplayName
FROM 
    TopPosts
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
