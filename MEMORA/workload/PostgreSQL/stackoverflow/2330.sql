WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation > 1000
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
), PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
), UserDetails AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        ru.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore
    FROM RankedUsers ru
    LEFT JOIN UserBadges ub ON ru.UserId = ub.UserId
    LEFT JOIN PostStats ps ON ru.UserId = ps.OwnerUserId
)
SELECT 
    ud.DisplayName,
    ud.Reputation,
    ud.BadgeCount,
    ud.BadgeNames,
    ud.QuestionCount,
    ud.AnswerCount,
    ud.TotalScore,
    CASE 
        WHEN ud.Reputation > 5000 THEN 'High Reputation'
        WHEN ud.Reputation BETWEEN 2000 AND 5000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserDetails ud
WHERE ud.QuestionCount > 5
ORDER BY ud.TotalScore DESC
LIMIT 10;