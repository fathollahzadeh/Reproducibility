WITH PostStats AS (
    SELECT 
        p.PostTypeId, 
        COUNT(*) AS TotalPosts, 
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts, 
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoredPosts, 
        AVG(p.ViewCount) AS AverageViews, 
        AVG(p.AnswerCount) AS AverageAnswers,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPostsByUser,
        SUM(p.Score) AS TotalScoreByUser,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    pt.Name AS PostTypeName,
    ps.TotalPosts, 
    ps.PositiveScoredPosts, 
    ps.NegativeScoredPosts, 
    ps.AverageViews,
    ps.AverageAnswers,
    ps.LatestPostDate,
    us.UserId,
    us.TotalPostsByUser,
    us.TotalScoreByUser,
    us.AverageReputation
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
LEFT JOIN 
    UserStats us ON us.TotalPostsByUser > 0
ORDER BY 
    ps.TotalPosts DESC;