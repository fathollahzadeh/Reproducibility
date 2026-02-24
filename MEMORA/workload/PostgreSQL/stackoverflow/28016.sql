WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
ActivePosts AS (
    SELECT 
        p.Title,
        p.ViewCount,
        p.CreationDate,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.LastActivityDate > cast('2024-10-01' as date) - INTERVAL '30 days' 
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AverageReputation,
    ts.TopUsers,
    ap.Title AS TopActivePost,
    ap.ViewCount AS TopPostViews,
    ap.CreationDate AS TopPostCreation
FROM 
    TagStats ts
LEFT JOIN 
    ActivePosts ap ON ts.TagName = ap.TagName AND ap.Rank = 1
ORDER BY 
    ts.PostCount DESC, ts.AverageReputation DESC;