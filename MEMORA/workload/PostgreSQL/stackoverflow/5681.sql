WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(b.Class) AS TotalBadges,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        Us.UserId,
        Us.DisplayName,
        Us.Reputation,
        Us.PostCount,
        Us.QuestionCount,
        Us.AnswerCount,
        Us.TotalBadges,
        Us.AccountCreationDate,
        DENSE_RANK() OVER (ORDER BY Us.Reputation DESC) AS Rank
    FROM UserStats Us
)
SELECT 
    Tu.Rank,
    Tu.DisplayName,
    Tu.Reputation,
    Tu.PostCount,
    Tu.QuestionCount,
    Tu.AnswerCount,
    Tu.TotalBadges,
    Tu.AccountCreationDate,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM TopUsers Tu
LEFT JOIN Comments c ON Tu.UserId = c.UserId
WHERE Tu.Rank <= 10
GROUP BY Tu.Rank, Tu.DisplayName, Tu.Reputation, Tu.PostCount, Tu.QuestionCount, Tu.AnswerCount, Tu.TotalBadges, Tu.AccountCreationDate
ORDER BY Tu.Rank;
