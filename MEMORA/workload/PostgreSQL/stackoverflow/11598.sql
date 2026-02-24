
WITH PostStatistics AS (
    SELECT
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)), 0)) AS AvgPostAgeInSeconds
    FROM
        Posts p
    GROUP BY
        p.PostTypeId
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)
SELECT
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgPostAgeInSeconds,
    us.AvgReputation,
    us.TotalBadges
FROM
    PostTypes pt
JOIN
    PostStatistics ps ON pt.Id = ps.PostTypeId
LEFT JOIN
    UserStatistics us ON us.UserId IS NOT NULL
ORDER BY
    ps.TotalPosts DESC;
