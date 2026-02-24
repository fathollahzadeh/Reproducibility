WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedQuestionCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        t.TagName
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS ContributedPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        ClosedQuestionCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        ContributedPosts,
        QuestionsAsked,
        AnswersGiven,
        BadgesReceived,
        ROW_NUMBER() OVER (ORDER BY ContributedPosts DESC) AS UserRank
    FROM 
        ActiveUsers
)
SELECT 
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.ClosedQuestionCount,
    u.DisplayName AS TopContributor,
    u.ContributedPosts,
    u.QuestionsAsked,
    u.AnswersGiven,
    u.BadgesReceived
FROM 
    TopTags t
JOIN 
    TopUsers u ON t.QuestionCount > 0 AND u.QuestionsAsked = (
        SELECT MAX(QuestionsAsked) FROM ActiveUsers WHERE QuestionsAsked > 0
    )
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.PostCount DESC;
