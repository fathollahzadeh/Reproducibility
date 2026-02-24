
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CommentCount) AS AvgComments,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)

SELECT 
    p.PostTypeId,
    ps.TotalPosts,
    ps.PositiveScorePosts,
    ps.AvgPostScore,
    ps.TotalViews,
    ps.AvgComments,
    ps.AcceptedAnswers,
    COUNT(DISTINCT us.UserId) AS ActiveUsers,
    SUM(us.TotalBadges) AS TotalBadgesEarned,
    SUM(us.TotalUpVotes) AS TotalUserUpVotes,
    SUM(us.TotalDownVotes) AS TotalUserDownVotes
FROM 
    PostStats ps
JOIN 
    Posts p ON ps.PostTypeId = p.PostTypeId
LEFT JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
GROUP BY 
    p.PostTypeId, ps.TotalPosts, ps.PositiveScorePosts, ps.AvgPostScore, ps.TotalViews, ps.AvgComments, ps.AcceptedAnswers
ORDER BY 
    p.PostTypeId;
