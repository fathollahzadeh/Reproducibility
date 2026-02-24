
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgePoints,
        SUM(v.BountyAmount) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.VoteTypeId IN (8, 9) 
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.TagName,
    ts.TotalPosts,
    ts.TotalQuestions,
    ts.TotalAnswers,
    ts.TotalComments,
    ur.DisplayName AS TopContributor,
    ur.TotalBadgePoints,
    ur.TotalBountyEarned
FROM 
    TagStatistics ts
JOIN 
    UserReputation ur ON ur.TotalBadgePoints = (SELECT MAX(TotalBadgePoints) FROM UserReputation)
ORDER BY 
    ts.TotalPosts DESC
LIMIT 10;
