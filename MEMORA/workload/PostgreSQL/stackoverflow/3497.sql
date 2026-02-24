
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 YEAR'
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AvgScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No views'
        ELSE CONCAT(CAST(rp.ViewCount AS TEXT), ' views')
    END AS FormattedViewCount
FROM 
    UserPostStats ups
LEFT JOIN 
    RecentPosts rp ON ups.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.AvgScore DESC
LIMIT 10;
