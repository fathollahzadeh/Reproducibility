WITH PostTypeCounts AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserActivity AS (
    SELECT 
        u.DisplayName AS UserName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ptc.PostTypeName,
    ptc.TotalPosts,
    ptc.PositiveScorePosts,
    ptc.AvgViewCount,
    ptc.AvgScore,
    ua.UserName,
    ua.TotalPosts AS UserTotalPosts,
    ua.PositiveScorePosts AS UserPositiveScorePosts,
    ua.AvgViewCount AS UserAvgViewCount,
    ua.AvgScore AS UserAvgScore
FROM 
    PostTypeCounts ptc
CROSS JOIN 
    UserActivity ua
ORDER BY 
    ptc.PostTypeName, ua.UserName;