WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.BountyAmount) AS TotalBounties,
        AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounties,
        AvgReputation,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankPosts,
        RANK() OVER (ORDER BY TotalQuestions DESC) AS RankQuestions,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS RankAnswers
    FROM UserStats
),
ActiveTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankPostCount,
        RANK() OVER (ORDER BY QuestionCount DESC) AS RankQuestionCount
    FROM ActiveTags
)
SELECT 
    u.DisplayName AS TopUser,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalBounties,
    u.AvgReputation,
    t.TagName AS MostActiveTag,
    t.PostCount AS TagPostCount,
    t.QuestionCount AS TagQuestionCount,
    t.AnswerCount AS TagAnswerCount
FROM TopUsers u
JOIN TopTags t ON u.RankPosts = 1
WHERE u.RankPosts <= 10 
ORDER BY u.TotalPosts DESC, t.PostCount DESC;