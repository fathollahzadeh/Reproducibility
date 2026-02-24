
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        Tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        Tag,
        QuestionCount,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagStatistics
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        TotalViews,
        TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        UserEngagement
)
SELECT 
    tt.Tag,
    tt.QuestionCount,
    tt.TotalViews,
    tt.TotalScore,
    tu.DisplayName AS TopUser,
    tu.QuestionsAsked,
    tu.TotalViews AS UserTotalViews,
    tu.TotalAnswers 
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tt.Rank = tu.Rank
WHERE 
    tt.Rank <= 5;
