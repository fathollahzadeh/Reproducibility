WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.CommentCount,
        ub.BadgeCount,
        ub.GoldCount,
        ub.SilverCount,
        ub.BronzeCount,
        CASE 
            WHEN ur.Reputation > 1000 THEN 'High Reputation'
            WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS OverallRank
    FROM UserReputation ur
    LEFT JOIN UserBadges ub ON ur.UserId = ub.UserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.ReputationCategory,
    tu.PostCount,
    tu.CommentCount,
    COALESCE(tu.BadgeCount, 0) AS BadgeCount,
    COALESCE(tu.GoldCount, 0) AS GoldCount,
    COALESCE(tu.SilverCount, 0) AS SilverCount,
    COALESCE(tu.BronzeCount, 0) AS BronzeCount,
    CASE WHEN tu.PostCount > 10 THEN 'Active User'
         ELSE 'Less Active User' END AS ActivityStatus
FROM TopUsers tu
WHERE tu.OverallRank <= 100
ORDER BY tu.Reputation DESC, tu.BadgeCount DESC;
