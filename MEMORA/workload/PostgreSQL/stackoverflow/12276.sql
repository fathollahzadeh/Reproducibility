WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.CommentCount, 0)) AS AvgCommentsPerPost,
        AVG(COALESCE(p.AnswerCount, 0)) AS AvgAnswersPerPost,
        MAX(p.CreationDate) AS MostRecentPost
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserEngagement AS (
    SELECT 
        u.DisplayName AS User,
        COUNT(DISTINCT p.Id) AS TotalPostsByUser,
        SUM(v.BountyAmount) AS TotalBountyReceived,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.DisplayName
)
SELECT 
    p.PostType,
    p.TotalPosts,
    p.UniqueUsers,
    p.TotalScore,
    p.TotalViews,
    p.AvgCommentsPerPost,
    p.AvgAnswersPerPost,
    p.MostRecentPost,
    u.User,
    u.TotalPostsByUser,
    u.TotalBountyReceived,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.AvgReputation
FROM 
    PostStatistics p
JOIN 
    UserEngagement u ON u.TotalPostsByUser > 0
ORDER BY 
    p.TotalPosts DESC, u.TotalPostsByUser DESC;