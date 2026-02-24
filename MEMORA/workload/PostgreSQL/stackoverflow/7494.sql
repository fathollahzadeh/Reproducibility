
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        CommentCount,
        VoteCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserStats
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
    ORDER BY p.Score DESC
    LIMIT 10
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    q.Title AS TopQuestionTitle,
    q.Score AS QuestionScore,
    q.ViewCount AS QuestionViews,
    q.CommentCount AS QuestionComments,
    q.VoteCount AS QuestionVotes
FROM TopUsers u
JOIN TopQuestions q ON u.UserId = (SELECT OwnerUserId FROM Posts WHERE Title = q.Title LIMIT 1)
WHERE u.UserRank <= 10
ORDER BY u.Reputation DESC;
