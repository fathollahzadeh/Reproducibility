
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score IS NULL THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(bb.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bb ON u.Id = bb.UserId
    WHERE 
        u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
), PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(p.CommentCount) AS TotalComments,
        COUNT(DISTINCT p.AcceptedAnswerId) AS AcceptedAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
    GROUP BY 
        pt.Name
)
SELECT 
    ua.DisplayName,
    ua.PostsCreated,
    ua.PositivePosts,
    ua.NegativePosts,
    ua.TotalBadges,
    ua.AvgReputation,
    ps.PostType,
    ps.PostCount,
    ps.AvgViewCount,
    ps.TotalComments,
    ps.AcceptedAnswers
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.PostsCreated > 0
ORDER BY 
    ua.AvgReputation DESC, ps.PostCount DESC
FETCH FIRST 100 ROWS ONLY;
