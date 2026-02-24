WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000 AND u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT
    tu.DisplayName,
    tu.Reputation,
    tu.Views,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.BadgeCount,
    COALESCE(ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL), '{}') AS TopTags
FROM TopUsers tu
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        UNNEST(string_to_array(p.Tags, ',')) AS TagName
    FROM Posts p
    WHERE p.Tags IS NOT NULL
) t ON tu.UserId = t.OwnerUserId
WHERE tu.ReputationRank <= 10
GROUP BY tu.UserId, tu.DisplayName, tu.Reputation, tu.Views, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.BadgeCount
ORDER BY tu.Reputation DESC;