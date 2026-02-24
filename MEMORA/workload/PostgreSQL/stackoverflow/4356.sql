
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(v.Id, 0)) AS TotalVotes,
        RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalScore,
        ub.BadgeNames,
        ua.UserRank
    FROM 
        UserActivity ua
    LEFT JOIN 
        UserBadges ub ON ua.UserId = ub.UserId
    WHERE 
        ua.UserRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    COALESCE(tu.BadgeNames, 'No badges') AS BadgeNames,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.OwnerUserId = tu.UserId AND p2.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days') AS RecentPosts,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = tu.UserId) AS TotalComments
FROM 
    TopUsers tu
ORDER BY 
    tu.TotalScore DESC;
