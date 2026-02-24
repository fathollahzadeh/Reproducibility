
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.Views,
    ru.PostCount,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.UpVotes,
    ru.DownVotes,
    CASE 
        WHEN ru.QuestionCount = 0 THEN 0 
        ELSE CAST(ru.AnswerCount AS FLOAT) / ru.QuestionCount 
    END AS AnswerToQuestionRatio,
    COALESCE(b.Class, 0) AS BadgeClass
FROM RankedUsers ru
LEFT JOIN Badges b ON ru.UserId = b.UserId AND b.Class = 1
WHERE ru.Rank <= 100
ORDER BY ru.Rank;
