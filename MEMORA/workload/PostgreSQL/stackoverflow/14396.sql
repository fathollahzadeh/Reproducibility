WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.OwnerUserId) AS TotalOwners
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        pt.Name
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalViews,
    us.DisplayName AS TopUser,
    us.TotalBadges,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStatistics ps
JOIN 
    UserStatistics us ON us.TotalUpVotes = (SELECT MAX(TotalUpVotes) FROM UserStatistics)
ORDER BY 
    ps.TotalPosts DESC;