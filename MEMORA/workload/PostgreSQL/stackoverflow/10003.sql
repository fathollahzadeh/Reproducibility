WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments,
        MIN(p.CreationDate) AS EarliestPostDate,
        MAX(p.LastActivityDate) AS MostRecentActivity
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserStats AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(u.Reputation) AS TotalReputation,
        AVG(u.UpVotes) AS AverageUpVotes,
        AVG(u.DownVotes) AS AverageDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.TotalViews,
    ps.AverageScore,
    ps.AcceptedAnswers,
    ps.TotalAnswers,
    ps.TotalComments,
    us.DisplayName,
    us.PostsCreated,
    us.TotalBadges,
    us.TotalReputation,
    us.AverageUpVotes,
    us.AverageDownVotes
FROM 
    PostStats ps
CROSS JOIN 
    UserStats us
ORDER BY 
    ps.PostCount DESC, 
    us.TotalReputation DESC;