
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.OwnerUserId, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    t.OwnerDisplayName,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(t.VoteCount) AS TotalVotes,
    SUM(t.CommentCount) AS TotalComments
FROM 
    TopPosts t
LEFT JOIN 
    Badges b ON t.PostId = b.UserId
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    TotalVotes DESC, TotalComments DESC;
