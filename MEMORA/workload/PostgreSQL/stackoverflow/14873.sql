WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS QuestionsWithScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(p.CreationDate) AS LatestPost
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        AVG(COALESCE(u.Views, 0)) AS AvgViews,
        AVG(COALESCE(u.UpVotes, 0)) AS AvgUpVotes,
        AVG(COALESCE(u.DownVotes, 0)) AS AvgDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Reputation
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.QuestionsWithScore,
    ps.AvgViewCount,
    ps.AvgScore,
    us.Reputation,
    us.BadgeCount,
    us.AvgViews,
    us.AvgUpVotes,
    us.AvgDownVotes
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.Reputation > 1000 
ORDER BY 
    ps.TotalPosts DESC, us.Reputation DESC;