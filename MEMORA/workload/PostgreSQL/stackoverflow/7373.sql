
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN b.Class IS NOT NULL THEN b.Class ELSE 0 END) AS BadgeScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        Upvotes,
        Downvotes,
        BadgeScore,
        RANK() OVER (ORDER BY PostCount DESC, Upvotes DESC) AS UserRank
    FROM UserStats
    WHERE PostCount > 0
)
SELECT 
    ru.UserRank,
    ru.DisplayName,
    ru.PostCount,
    ru.AnswerCount,
    ru.QuestionCount,
    ru.Upvotes,
    ru.Downvotes,
    ru.BadgeScore
FROM RankedUsers ru
WHERE ru.UserRank <= 10
ORDER BY ru.UserRank;
