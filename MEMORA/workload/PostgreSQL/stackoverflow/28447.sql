
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
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
        TotalScore,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserStats
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    tu.UpVotes,
    tu.DownVotes,
    STRING_AGG(t.TagName, ', ') AS Tags,
    MAX(ph.CreationDate) AS LastActiveDate
FROM TopUsers tu
LEFT JOIN Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
WHERE tu.ScoreRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation,
    tu.PostCount, tu.QuestionCount, tu.AnswerCount, 
    tu.TotalScore, tu.UpVotes, tu.DownVotes
ORDER BY tu.TotalScore DESC;
