
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
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
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS Rank
    FROM UserStats
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month')
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    ap.PostId,
    ap.Title,
    ap.CreationDate,
    ap.CommentCount,
    ap.VoteCount
FROM TopUsers tu
JOIN ActivePosts ap ON tu.UserId = ap.OwnerUserId
WHERE tu.Rank <= 10
ORDER BY tu.Rank, ap.VoteCount DESC;
