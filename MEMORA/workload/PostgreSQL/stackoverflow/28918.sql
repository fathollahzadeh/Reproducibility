WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        t.Count > 0
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageReputation,
        TopUsers, 
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS RN
    FROM 
        TagStatistics
)

SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.AverageReputation,
    tt.TopUsers,
    (SELECT STRING_AGG(DISTINCT p.Title, ', ') 
     FROM Posts p 
     WHERE p.Tags LIKE '%' || tt.TagName || '%' 
       AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days') AS RecentPosts
FROM 
    TopTags tt
WHERE 
    tt.RN <= 10
ORDER BY 
    tt.PostCount DESC;