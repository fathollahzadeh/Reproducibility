
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.CommentCount,
    tu.UpVoteCount,
    tu.DownVoteCount,
    COALESCE(b.Name, 'No Badges') AS BadgeName
FROM TopUsers tu
LEFT JOIN Badges b ON tu.UserId = b.UserId
WHERE tu.UserRank <= 10
ORDER BY tu.UserRank, b.Date DESC;
