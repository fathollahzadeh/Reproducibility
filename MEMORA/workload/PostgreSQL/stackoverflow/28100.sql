WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
), TagStats AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT pt.PostId) AS QuestionCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        pt.Tag
), RankedTags AS (
    SELECT 
        ts.Tag,
        ts.QuestionCount,
        ts.UniqueUsers,
        ts.TotalAnswers,
        ts.TotalViews,
        ts.AverageScore,
        ROW_NUMBER() OVER (ORDER BY ts.QuestionCount DESC, ts.TotalViews DESC) AS Rank
    FROM 
        TagStats ts
)
SELECT 
    rt.Tag,
    rt.QuestionCount,
    rt.UniqueUsers,
    rt.TotalAnswers,
    rt.TotalViews,
    rt.AverageScore
FROM 
    RankedTags rt
WHERE 
    rt.Rank <= 10;