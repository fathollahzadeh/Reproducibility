WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
UserRanking AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        CommentCount,
        TotalBadges,
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC, AnswerCount DESC, QuestionCount DESC, CommentCount DESC, TotalBadges DESC) AS Rank
    FROM UserActivity
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        CommentCount,
        TotalBadges,
        AvgReputation
    FROM UserRanking
    WHERE Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.AnswerCount,
    tu.QuestionCount,
    tu.CommentCount,
    tu.TotalBadges,
    tu.AvgReputation,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = tu.UserId) AS TotalVotes
FROM TopUsers tu
ORDER BY tu.PostCount DESC, tu.AnswerCount DESC;
