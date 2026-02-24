
WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
Analytics AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        TagStats ts
    JOIN 
        Posts p ON p.Tags LIKE '%' || ts.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        ts.TagName, ts.PostCount
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AcceptedAnswers,
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        Analytics
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AcceptedAnswers,
    AvgReputation
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
