
WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(CASE WHEN p.CommentCount IS NOT NULL THEN p.CommentCount ELSE 0 END) AS AvgCommentCount,
        AVG(CASE WHEN p.FavoriteCount IS NOT NULL THEN p.FavoriteCount ELSE 0 END) AS AvgFavoriteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(b.Class) AS TotalBadgeClass,
        AVG(p.ViewCount) AS UserAvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName, u.Reputation
),
CommentStatistics AS (
    SELECT 
        COUNT(c.Id) AS TotalComments,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
)
SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AvgScore,
    ps.AvgViewCount,
    ps.AcceptedAnswers,
    ps.AvgCommentCount,
    ps.AvgFavoriteCount,
    us.DisplayName AS TopUser,
    us.Reputation AS TopUserReputation,
    us.BadgeCount AS TopUserBadgeCount,
    us.TotalBadgeClass AS TopUserTotalBadgeClass,
    us.UserAvgViewCount AS TopUserAvgViewCount,
    cs.TotalComments,
    cs.AvgCommentScore
FROM 
    PostStatistics ps
CROSS JOIN 
    (SELECT u.DisplayName, u.Reputation, u.BadgeCount, u.TotalBadgeClass, u.UserAvgViewCount
     FROM UserStatistics u
     ORDER BY u.Reputation DESC
     LIMIT 1) us
CROSS JOIN 
    CommentStatistics cs;
