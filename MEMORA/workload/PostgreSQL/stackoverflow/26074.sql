WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), UserMostActivePosts AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
), TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ub.BadgeNames,
        uma.PostCount,
        uma.QuestionCount,
        uma.AnswerCount,
        uma.WikiCount
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    JOIN 
        UserMostActivePosts uma ON u.Id = uma.OwnerUserId
    ORDER BY 
        ub.BadgeCount DESC, uma.PostCount DESC
    LIMIT 
        10
)
SELECT 
    tu.DisplayName, 
    tu.BadgeCount, 
    tu.BadgeNames, 
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.WikiCount
FROM 
    TopUsers tu
JOIN 
    Votes v ON tu.UserId = v.UserId
GROUP BY 
    tu.DisplayName, 
    tu.BadgeCount, 
    tu.BadgeNames, 
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.WikiCount
ORDER BY 
    COUNT(v.Id) DESC
LIMIT 
    5;