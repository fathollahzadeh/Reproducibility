WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.Cnt, 0)) AS VoteCount,
        SUM(COALESCE(b.BadgeCount, 0)) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS Cnt 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount 
        FROM Badges 
        GROUP BY UserId
    ) b ON u.Id = b.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        VoteCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, VoteCount DESC) AS Rank
    FROM UserStats
)
SELECT 
    t.DisplayName AS TopUser,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.VoteCount,
    t.BadgeCount
FROM TopUsers t
WHERE t.Rank <= 10
ORDER BY t.Rank;
