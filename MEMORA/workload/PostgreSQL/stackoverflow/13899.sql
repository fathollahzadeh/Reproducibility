WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        u.Reputation,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Reputation, p.Score, p.ViewCount
)

SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    VoteCount,
    BadgeCount,
    Reputation,
    Score,
    ViewCount,
    RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank,
    RANK() OVER (ORDER BY VoteCount DESC) AS VoteRank,
    RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
FROM 
    BenchmarkData
ORDER BY 
    CreationDate DESC
LIMIT 100;
