
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS QuestionCount, 
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        QuestionCount, 
        AnswerCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
            ), 0) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    tu.UserId, 
    tu.DisplayName, 
    tu.Reputation, 
    tu.QuestionCount, 
    tu.AnswerCount, 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.CommentCount,
    COALESCE(tu.UpVotes, 0) AS UpVotesTotal,
    COALESCE(tu.DownVotes, 0) AS DownVotesTotal
FROM TopUsers tu
LEFT JOIN RecentPosts rp ON tu.DisplayName = rp.OwnerDisplayName
WHERE tu.ReputationRank <= 10
ORDER BY tu.Reputation DESC, rp.CreationDate DESC
LIMIT 100;
