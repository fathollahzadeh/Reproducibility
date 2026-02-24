
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT pt.PostId) AS QuestionCount,
        COUNT(DISTINCT u.Id) AS UserCount,
        SUM(ua.TotalViews) AS TotalViews
    FROM 
        PostTags pt
    JOIN 
        Users u ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = pt.PostId)
    JOIN 
        UserActivity ua ON ua.UserId = u.Id
    GROUP BY 
        pt.Tag
)
SELECT 
    ts.Tag,
    ts.QuestionCount,
    ts.UserCount,
    ts.TotalViews,
    CASE 
        WHEN ts.QuestionCount > 0 THEN ROUND(ts.TotalViews / CAST(ts.QuestionCount AS numeric), 2)
        ELSE 0
    END AS AvgViewsPerQuestion,
    CASE 
        WHEN ts.UserCount > 0 THEN ROUND(ts.TotalViews / CAST(ts.UserCount AS numeric), 2)
        ELSE 0
    END AS AvgViewsPerUser
FROM 
    TagStats ts
ORDER BY 
    ts.QuestionCount DESC, ts.TotalViews DESC;
