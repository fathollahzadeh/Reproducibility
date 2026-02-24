
WITH UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           AVG(u.Reputation) AS AvgReputation,
           MAX(p.CreationDate) AS LastActiveDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TopTags AS (
    SELECT unnest(string_to_array(Tags, '><')) AS TagName,
           COUNT(*) AS TagCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 10
),
TopUsers AS (
    SELECT u.DisplayName,
           SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.DisplayName
    ORDER BY TotalScore DESC
    LIMIT 5
)
SELECT us.DisplayName AS UserName,
       ts.TagName,
       ts.TagCount,
       tu.TotalScore AS UserTotalScore,
       us.TotalPosts,
       us.TotalQuestions,
       us.TotalAnswers,
       us.AvgReputation,
       us.LastActiveDate
FROM UserStats us
JOIN TopTags ts ON us.TotalPosts > 5
JOIN TopUsers tu ON us.DisplayName = tu.DisplayName
ORDER BY us.AvgReputation DESC, ts.TagCount DESC;
