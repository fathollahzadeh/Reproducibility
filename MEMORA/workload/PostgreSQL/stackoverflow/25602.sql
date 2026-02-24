WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(b.Class) AS TotalBadgeClass,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AverageScore,
    ur.DisplayName AS TopUser,
    ur.TotalBadgeClass,
    ur.AverageReputation
FROM 
    TagStats ts
JOIN 
    UserReputation ur ON ur.AverageReputation = (SELECT MAX(AverageReputation) FROM UserReputation)
WHERE 
    ts.PostCount > 0
ORDER BY 
    ts.PostCount DESC, ts.AverageScore DESC;
