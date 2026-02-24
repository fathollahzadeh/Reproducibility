
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <'))
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS QuestionCount,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        OwnerUserId
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
TagDetails AS (
    SELECT 
        ta.Tag,
        tc.PostCount,
        mu.OwnerUserId,
        mu.QuestionCount,
        mu.TotalViews,
        mu.TotalAnswers
    FROM 
        TagCounts tc
    JOIN 
        (SELECT 
            DISTINCT unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <')) AS Tag,
            OwnerUserId
         FROM 
            Posts
         WHERE 
            PostTypeId = 1) ta ON ta.Tag = tc.Tag
    JOIN 
        MostActiveUsers mu ON ta.OwnerUserId = mu.OwnerUserId
)
SELECT 
    td.Tag,
    td.PostCount,
    m.DisplayName,
    m.Reputation,
    td.QuestionCount,
    td.TotalViews,
    td.TotalAnswers
FROM 
    TagDetails td
JOIN 
    Users m ON td.OwnerUserId = m.Id
ORDER BY 
    td.PostCount DESC, td.TotalViews DESC;
