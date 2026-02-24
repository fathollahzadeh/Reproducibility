WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(vs.TotalVotes, 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS TotalVotes FROM Votes GROUP BY PostId) vs ON p.Id = vs.PostId
)
SELECT 
    up.DisplayName,
    up.TotalPosts,
    up.TotalQuestions,
    up.TotalAnswers,
    up.TotalViews,
    up.TotalScore,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.AcceptedAnswerId,
    ps.CommentCount,
    ps.TotalVotes
FROM 
    UserPosts up
JOIN 
    PostStats ps ON up.UserId = ps.AcceptedAnswerId
ORDER BY 
    up.TotalScore DESC, up.TotalPosts DESC;