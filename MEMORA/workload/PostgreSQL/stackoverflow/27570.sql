WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostsContributed,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        AVG(COALESCE(p.Score, 0)) AS AveragePostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.AverageScore,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM 
        TagStatistics ts
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostsContributed,
        ur.QuestionsAsked,
        ur.AnswersGiven,
        ur.AveragePostScore,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
) 
SELECT 
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.AverageScore,
    u.UserId,
    u.Reputation,
    u.PostsContributed,
    u.QuestionsAsked,
    u.AnswersGiven,
    u.AveragePostScore
FROM 
    TopTags t
JOIN 
    ActiveUsers u ON u.PostsContributed > 0
WHERE 
    t.TagRank <= 10 AND u.UserRank <= 10
ORDER BY 
    t.PostCount DESC, u.Reputation DESC;
