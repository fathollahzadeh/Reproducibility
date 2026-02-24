WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositivePosts,
        NegativePosts,
        AvgReputation,
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserStats
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
FinalReport AS (
    SELECT 
        tu.DisplayName,
        tu.PostCount,
        tu.PositivePosts,
        tu.NegativePosts,
        uA.CommentCount,
        uA.VoteCount,
        tu.AvgReputation,
        tu.BadgeCount,
        CASE 
            WHEN tu.AvgReputation IS NULL THEN 'No Reputation'
            WHEN tu.AvgReputation < 1000 THEN 'Novice'
            WHEN tu.AvgReputation < 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM TopUsers tu
    JOIN UserActivity uA ON tu.UserId = uA.UserId
)
SELECT 
    *,
    (PostCount + CommentCount + VoteCount) AS TotalEngagement
FROM FinalReport
WHERE BadgeCount > 0
ORDER BY TotalEngagement DESC
LIMIT 10
;
