WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(c.CommentCount) AS TotalComments,
        SUM(v.VoteCount) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalComments,
        TotalVotes,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rnk
    FROM UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalComments,
    tu.TotalVotes,
    u.Reputation,
    u.CreationDate AS AccountCreationDate,
    u.LastAccessDate
FROM TopUsers tu
JOIN Users u ON tu.UserId = u.Id
WHERE tu.Rnk <= 10
ORDER BY tu.PostCount DESC, tu.QuestionCount DESC;
