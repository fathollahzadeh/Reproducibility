
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyReceived
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) /* Bounty start and close */
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalBountyReceived,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM UserReputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
UserStats AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.Reputation,
        t.PostCount,
        t.TotalBountyReceived,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
        t.ReputationRank,
        t.PostCountRank
    FROM TopUsers t
    LEFT JOIN UserBadges ub ON t.UserId = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    TotalBountyReceived,
    BadgeCount,
    BadgeNames,
    ReputationRank,
    PostCountRank
FROM UserStats
WHERE ReputationRank <= 10 OR PostCountRank <= 10
ORDER BY Reputation DESC, PostCount DESC;
