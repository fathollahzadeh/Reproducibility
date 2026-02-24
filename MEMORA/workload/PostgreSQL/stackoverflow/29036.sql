WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS UsageCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionUsageCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerUsageCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalViews,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
TopTags AS (
    SELECT 
        TagName,
        UsageCount,
        QuestionUsageCount,
        AnswerUsageCount,
        RANK() OVER (ORDER BY UsageCount DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        UsageCount > 0
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.QuestionCount,
    u.AnswerCount,
    u.TotalScore,
    u.TotalViews,
    t.TagName,
    t.UsageCount,
    t.QuestionUsageCount,
    t.AnswerUsageCount
FROM 
    TopUsers u
JOIN 
    TopTags t ON u.QuestionCount > 10 AND t.UsageCount > 10
WHERE 
    u.ScoreRank <= 10 AND t.TagRank <= 10
ORDER BY 
    u.TotalScore DESC, t.UsageCount DESC;
