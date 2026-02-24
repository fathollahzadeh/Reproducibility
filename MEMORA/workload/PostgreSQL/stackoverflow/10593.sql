WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        pt.Name AS PostType,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, pt.Name, u.Reputation
),
TopPosts AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        PostStats
)
SELECT 
    PostId, 
    Title, 
    CreationDate, 
    Score, 
    CommentCount, 
    VoteCount, 
    BadgeCount, 
    PostType, 
    UserReputation
FROM 
    TopPosts
WHERE 
    ScoreRank <= 100
ORDER BY 
    Score DESC;