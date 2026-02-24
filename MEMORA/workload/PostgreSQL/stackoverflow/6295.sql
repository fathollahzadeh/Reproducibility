WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(c.CommentCount) AS TotalComments,
        SUM(v.VoteCount) AS TotalVotes,
        MAX(p.CreationDate) AS LastActiveDate
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
        LastActiveDate,
        RANK() OVER (ORDER BY PostCount DESC, TotalVotes DESC) AS Rank
    FROM UserActivity
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.TotalComments,
    t.TotalVotes,
    t.LastActiveDate
FROM TopUsers t
WHERE t.Rank <= 10
ORDER BY t.Rank;
