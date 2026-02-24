
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        u.Reputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC, Reputation DESC) AS Rank
    FROM UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.BadgeCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(ph.Id) AS HistoryCount
FROM TopUsers tu
LEFT JOIN Comments c ON c.UserId = tu.UserId
LEFT JOIN PostHistory ph ON ph.UserId = tu.UserId
WHERE tu.Rank <= 10
GROUP BY tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.UpVotes, tu.DownVotes, tu.BadgeCount, tu.Rank
ORDER BY tu.Rank;
