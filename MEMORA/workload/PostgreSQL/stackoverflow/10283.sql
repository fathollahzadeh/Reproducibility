WITH PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CommentCounts AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.UserId
)
SELECT 
    u.Id AS UserId,
    u.Reputation,
    COALESCE(pc.TotalPosts, 0) AS TotalPosts,
    COALESCE(pc.AverageScore, 0) AS AverageScore,
    COALESCE(cc.TotalComments, 0) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    PostCounts pc ON u.Id = pc.OwnerUserId
LEFT JOIN 
    CommentCounts cc ON u.Id = cc.UserId
ORDER BY 
    u.Reputation DESC;