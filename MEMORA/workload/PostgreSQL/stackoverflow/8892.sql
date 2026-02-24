WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(c.Id) AS CommentCount,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
HighReputation AS (
    SELECT * 
    FROM UserActivity
    WHERE Reputation > 1000
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        p.Score DESC
    LIMIT 10
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.CommentCount,
    u.TotalBadges,
    tq.PostId,
    tq.Title AS TopQuestionTitle,
    tq.ViewCount AS TopQuestionViews,
    tq.Score AS TopQuestionScore,
    tq.Tags AS TopQuestionTags,
    tq.CreationDate AS TopQuestionDate
FROM 
    HighReputation u
LEFT JOIN 
    TopQuestions tq ON u.PostCount > 5 
ORDER BY 
    u.Reputation DESC, tq.Score DESC;