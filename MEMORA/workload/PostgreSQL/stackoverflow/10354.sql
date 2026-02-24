
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    u.UserId, 
    u.DisplayName, 
    u.PostCount, 
    u.Questions, 
    u.Answers, 
    u.PositiveScoredPosts, 
    u.AvgViewCount,
    t.TagName,
    t.PostCount AS TagPostCount
FROM 
    UserPostStats u
JOIN 
    TagStats t ON u.PostCount > 0
ORDER BY 
    u.PostCount DESC, 
    t.PostCount DESC
LIMIT 100;
