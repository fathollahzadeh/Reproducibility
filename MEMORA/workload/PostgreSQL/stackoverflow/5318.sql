
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
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
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
),
UserActivity AS (
    SELECT 
        pu.OwnerUserId AS UserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM Posts pu
    LEFT JOIN Comments c ON pu.Id = c.PostId
    LEFT JOIN PostHistory ph ON pu.Id = ph.PostId
    GROUP BY pu.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.BadgeCount,
    ua.CommentCount,
    ua.HistoryCount
FROM TopUsers tu
JOIN UserActivity ua ON tu.UserId = ua.UserId
WHERE tu.Rank <= 10
ORDER BY tu.Rank;
