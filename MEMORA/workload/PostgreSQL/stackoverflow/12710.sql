
WITH PostsStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.OwnerUserId) AS TotalUsers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(EXTRACT(EPOCH FROM p.CreationDate)) AS AvgCreationDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UsersStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        AVG(u.Reputation) AS AvgReputation,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
),
BadgeStats AS (
    SELECT 
        COUNT(b.Id) AS TotalBadges, 
        COUNT(DISTINCT b.UserId) AS UsersWithBadges
    FROM 
        Badges b
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalUsers,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgCreationDate,
    us.TotalUsers AS OverallTotalUsers,
    us.AvgReputation,
    us.TotalUpVotes,
    us.TotalDownVotes,
    bs.TotalBadges,
    bs.UsersWithBadges
FROM 
    PostsStats ps,
    UsersStats us,
    BadgeStats bs
ORDER BY 
    ps.TotalPosts DESC;
