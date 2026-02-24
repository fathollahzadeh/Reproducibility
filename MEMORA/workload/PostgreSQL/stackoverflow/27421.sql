
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '> %') 
            OR p.Tags LIKE CONCAT('<', t.TagName, '> %') 
            OR p.Tags LIKE CONCAT('% <', t.TagName, '>') 
            OR p.Tags LIKE CONCAT('%<', t.TagName, '>') 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
MostActiveUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    ORDER BY 
        TotalPosts DESC
    LIMIT 5
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AverageReputation,
    mau.DisplayName AS MostActiveUser,
    mau.Reputation AS ActiveUserReputation,
    mau.TotalPosts
FROM 
    TagStats ts
LEFT JOIN 
    MostActiveUsers mau ON ts.QuestionCount > 0
ORDER BY 
    ts.PostCount DESC, ts.AverageReputation DESC;
