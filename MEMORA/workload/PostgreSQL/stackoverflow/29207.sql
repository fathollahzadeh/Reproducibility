
WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(u.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(u.DownVotes), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS Count
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Name
),
RankedBadges AS (
    SELECT 
        UserId,
        BadgeName,
        Count,
        RANK() OVER (PARTITION BY UserId ORDER BY Count DESC) AS BadgeRank
    FROM 
        TopBadges
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalViews,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    STRING_AGG(CONCAT(rb.BadgeName, ' (', rb.Count, ')') ORDER BY rb.Count DESC) AS UserBadges
FROM 
    UserPostStatistics ups
LEFT JOIN 
    RankedBadges rb ON ups.UserId = rb.UserId AND rb.BadgeRank <= 3
WHERE 
    ups.TotalPosts > 0
GROUP BY 
    ups.UserId, ups.DisplayName, ups.TotalPosts, ups.Questions, ups.Answers, ups.TotalViews, ups.TotalUpVotes, ups.TotalDownVotes
ORDER BY 
    ups.TotalViews DESC, ups.TotalPosts DESC
LIMIT 10;
