WITH PostSummary AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    GROUP BY 
        PostTypeId
)


, UserReputation AS (
    SELECT 
        p.OwnerUserId,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.OwnerUserId
)


, CommentSummary AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)


SELECT 
    p.PostTypeId,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalScore,
    ur.AverageReputation,
    cs.CommentCount
FROM 
    PostSummary ps
LEFT JOIN 
    Posts p ON ps.PostTypeId = p.PostTypeId
LEFT JOIN 
    UserReputation ur ON p.OwnerUserId = ur.OwnerUserId
LEFT JOIN 
    CommentSummary cs ON p.Id = cs.PostId
ORDER BY 
    ps.TotalPosts DESC;