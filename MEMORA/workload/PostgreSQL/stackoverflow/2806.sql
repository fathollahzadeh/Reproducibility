
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgPostScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AvgPostScore,
        CommentCount,
        (GoldBadges + SilverBadges + BronzeBadges) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY AvgPostScore DESC, PostCount DESC) AS Rank
    FROM UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.AvgPostScore,
    tu.CommentCount,
    tu.TotalBadges,
    COALESCE((SELECT STRING_AGG(t.TagName, ', ') 
               FROM Tags t 
               JOIN Posts p ON t.ExcerptPostId = p.Id
               WHERE p.OwnerUserId = tu.UserId), 'No Tags') AS PopulatedTags
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.AvgPostScore DESC;
