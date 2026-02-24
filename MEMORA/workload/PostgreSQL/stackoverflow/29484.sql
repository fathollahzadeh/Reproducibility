WITH TagStatistics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.Id, t.TagName
),
MostActiveTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgUserReputation,
        TopUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
),
UserPostingActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsPosted,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionsPosted,
        AnswersPosted,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostingActivity
)
SELECT 
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.AvgUserReputation,
    t.TopUsers,
    u.DisplayName AS ActiveUser,
    u.TotalPosts,
    u.QuestionsPosted,
    u.AnswersPosted,
    u.Rank AS UserRank,
    t.Rank AS TagRank
FROM 
    MostActiveTags t
JOIN 
    TopUsers u ON t.TopUsers LIKE '%' || u.DisplayName || '%'
WHERE 
    t.Rank <= 10 AND u.Rank <= 10
ORDER BY 
    t.Rank, u.Rank;
