
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVoteCount,
        DownVoteCount,
        LastPostDate,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.UpVoteCount,
    u.DownVoteCount,
    u.LastPostDate,
    CASE 
        WHEN u.UserRank <= 10 THEN 'Top Contributor'
        WHEN u.UserRank BETWEEN 11 AND 50 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS UserCategory
FROM TopUsers u
WHERE u.UserRank <= 50
ORDER BY u.PostCount DESC, u.LastPostDate DESC;
