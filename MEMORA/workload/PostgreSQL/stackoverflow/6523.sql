
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount,
        QuestionCount,
        AnswerCount,
        WikiCount,
        TotalUpvotes,
        TotalDownvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
    WHERE Reputation > 1000
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
    HAVING COUNT(c.Id) > 5 AND COUNT(DISTINCT v.UserId) > 10
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.QuestionCount,
    pu.Title AS PopularQuestion,
    pu.Score,
    pu.ViewCount,
    pu.CommentCount,
    pu.VoteCount
FROM TopUsers tu
JOIN PopularQuestions pu ON tu.QuestionCount > 0
ORDER BY tu.ReputationRank, pu.Score DESC
LIMIT 10;
