
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        SUM(CASE WHEN p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' THEN 1 ELSE 0 END) AS PostsLastYear
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.UpVotes,
    ua.DownVotes,
    ua.TotalBadges,
    ua.PostsLastYear,
    ps.PostType,
    ps.PostCount,
    ps.AverageScore,
    ps.AverageViews,
    ps.TotalAnswers,
    ps.TotalComments
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.TotalPosts > 0
ORDER BY 
    ua.TotalPosts DESC, ps.PostCount DESC;
