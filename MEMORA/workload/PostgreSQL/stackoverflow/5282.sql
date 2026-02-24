WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
QuestionsWithAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        MAX(a.CreationDate) AS LastAnswerDate
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title
),
TopQuestions AS (
    SELECT 
        q.Title,
        q.AnswerCount,
        us.DisplayName,
        us.Reputation,
        ROW_NUMBER() OVER (ORDER BY q.AnswerCount DESC, q.LastAnswerDate DESC) AS Rank
    FROM 
        QuestionsWithAnswers q
    JOIN 
        Users us ON us.Id = (SELECT OwnerUserId FROM Posts WHERE Id = q.QuestionId)
)
SELECT 
    tq.Rank,
    tq.Title,
    tq.AnswerCount,
    us.UserId,
    us.DisplayName,
    us.Reputation
FROM 
    TopQuestions tq
JOIN 
    UserStats us ON tq.DisplayName = us.DisplayName
WHERE 
    tq.Rank <= 10
ORDER BY 
    tq.Rank;
