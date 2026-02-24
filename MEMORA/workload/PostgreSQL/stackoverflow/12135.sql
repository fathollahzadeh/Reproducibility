
WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.CommentCount,
        p.AnswerCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2023-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
        p.CommentCount, p.AnswerCount, u.Reputation, u.DisplayName, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.ViewCount,
    pe.Score,
    pe.CommentCount,
    pe.AnswerCount,
    pe.OwnerReputation,
    pe.OwnerDisplayName,
    pe.VoteCount,
    ua.UserId,
    ua.DisplayName AS UserDisplayName,
    ua.PostsCreated,
    ua.TotalBountySpent,
    ua.CommentsMade
FROM 
    PostEngagement pe
JOIN 
    UserActivity ua ON pe.OwnerUserId = ua.UserId
ORDER BY 
    pe.Score DESC, pe.ViewCount DESC;
