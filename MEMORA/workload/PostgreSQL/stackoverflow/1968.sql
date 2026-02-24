WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.AverageScore,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews
FROM 
    UserReputation ur
LEFT JOIN 
    PostStatistics ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN 
    TagStatistics ts ON ts.PostCount > 10
WHERE 
    ur.ReputationRank <= 10
ORDER BY 
    ur.Reputation DESC, ts.TotalViews DESC;
