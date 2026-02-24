WITH RecursivePostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS AnswerCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 
    GROUP BY 
        p.OwnerUserId
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(rc.AnswerCount, 0) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        RecursivePostCounts rc ON u.Id = rc.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.AnswerCount,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        RANK() OVER (ORDER BY ur.Reputation DESC, ur.AnswerCount DESC) AS Rank
    FROM 
        UserReputation ur
    LEFT JOIN 
        UserBadges ub ON ur.UserId = ub.UserId
    WHERE 
        ur.Reputation > 1000 
)
SELECT 
    tu.UserId,
    tu.Reputation,
    tu.AnswerCount,
    COALESCE(tu.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN tu.HighestBadgeClass = 1 THEN 'Gold'
        WHEN tu.HighestBadgeClass = 2 THEN 'Silver'
        WHEN tu.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None'
    END AS HighestBadge,
    tu.Rank
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10 
ORDER BY 
    tu.Rank;