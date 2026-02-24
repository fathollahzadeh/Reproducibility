WITH PostsSummary AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(EXTRACT(EPOCH FROM (COALESCE(p.ClosedDate, cast('2024-10-01 12:34:56' as timestamp)) - p.CreationDate))) AS AvgLifecycleDurationInSeconds,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserSummary AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(COALESCE(b.Id, 0)) AS TotalBadges
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
    ps.TotalPosts,
    ps.AvgLifecycleDurationInSeconds,
    ps.TotalViews,
    ps.TotalScore,
    us.TotalPosts AS UserTotalPosts,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalBadges
FROM 
    PostsSummary ps
JOIN 
    UserSummary us ON us.TotalPosts > 0
ORDER BY 
    ps.TotalPosts DESC;