WITH PostStatistics AS (
    SELECT 
        p.PostTypeId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.Id END) AS TotalAccepted,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStatistics AS (
    SELECT 
        u.Id,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.PostTypeId,
    ps.TotalPosts,
    ps.TotalAccepted,
    ps.TotalScore,
    ps.TotalViews,
    ps.TotalAnswers,
    ps.TotalComments,
    COUNT(DISTINCT us.Id) AS UserCount,
    SUM(us.TotalReputation) AS TotalUserReputation,
    SUM(us.BadgeCount) AS TotalBadges
FROM 
    PostStatistics ps
JOIN 
    Posts p ON ps.PostTypeId = p.PostTypeId
LEFT JOIN 
    UserStatistics us ON p.OwnerUserId = us.Id
GROUP BY 
    p.PostTypeId, ps.TotalPosts, ps.TotalAccepted, ps.TotalScore, ps.TotalViews, ps.TotalAnswers, ps.TotalComments
ORDER BY 
    p.PostTypeId;