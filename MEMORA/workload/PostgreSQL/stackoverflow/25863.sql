
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT CASE WHEN u.Id IS NOT NULL THEN u.DisplayName END, ', ') AS ActiveUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgReputation,
        ActiveUsers
    FROM 
        TagStats
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.AvgReputation,
    tt.ActiveUsers,
    PH.EditCount,
    PH.LastEditDate,
    PT.Name AS PostTypeName
FROM 
    TopTags tt
LEFT JOIN (
    SELECT 
        p.Tags,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        p.Tags
) AS PH ON tt.TagName IN (SELECT unnest(string_to_array(PH.Tags, ', ')))
JOIN 
    PostTypes PT ON pt.Id = (SELECT DISTINCT p.PostTypeId FROM Posts p WHERE p.Tags LIKE CONCAT('%', tt.TagName, '%'))
ORDER BY 
    tt.PostCount DESC;
