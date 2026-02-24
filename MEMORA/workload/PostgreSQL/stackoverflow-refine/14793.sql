WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(p.Score) AS ScoreFromPosts,
        SUM(p.ViewCount) AS ViewsFromPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    pth.Id AS PostTypeId,
    pth.Name AS PostTypeName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    ps.UniqueUsers,
    ps.AvgScore,
    ps.AvgViews,
    ps.LatestPostDate,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(DISTINCT PostId) FROM PostLinks) AS TotalLinks,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes
FROM 
    PostTypes pth
LEFT JOIN 
    PostStats ps ON pth.Id = ps.PostTypeId
ORDER BY 
    TotalPosts DESC;