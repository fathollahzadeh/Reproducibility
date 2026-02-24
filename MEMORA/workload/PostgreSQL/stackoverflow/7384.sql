
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
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
        TotalAnswers,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM UserStatistics
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalAnswers,
        UpVotes,
        DownVotes
    FROM TopUsers
    WHERE Rank <= 10
)
SELECT 
    mau.DisplayName,
    mau.Reputation,
    mau.PostCount,
    mau.QuestionCount,
    mau.AnswerCount,
    mau.TotalAnswers,
    (mau.UpVotes - mau.DownVotes) AS NetVoteScore
FROM MostActiveUsers mau
ORDER BY NetVoteScore DESC;
