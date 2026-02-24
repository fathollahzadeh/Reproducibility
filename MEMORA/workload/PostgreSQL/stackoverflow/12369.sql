WITH PostMetrics AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalQuestionsWithScore,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount,
        AVG(p.FavoriteCount) AS AvgFavoriteCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
), 
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    pt.Name AS PostType,
    pm.TotalPosts,
    pm.TotalQuestionsWithScore,
    pm.AvgViewCount,
    pm.AvgAnswerCount,
    pm.AvgCommentCount,
    pm.AvgFavoriteCount,
    SUM(um.TotalBadges) AS TotalBadgesAwarded,
    SUM(um.TotalUpVotes) AS TotalUpVotes,
    AVG(um.AvgReputation) AS AvgUserReputation
FROM 
    PostTypes pt
JOIN 
    PostMetrics pm ON pt.Id = pm.PostTypeId
JOIN 
    UserMetrics um ON 1=1  
GROUP BY 
    pt.Name, pm.TotalPosts, pm.TotalQuestionsWithScore, pm.AvgViewCount, 
    pm.AvgAnswerCount, pm.AvgCommentCount, pm.AvgFavoriteCount
ORDER BY 
    pm.TotalPosts DESC;