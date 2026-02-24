
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(b.Class) AS TotalClass 
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
PostScore AS (
    SELECT 
        p.OwnerUserId, 
        SUM(p.Score) AS TotalPostScore, 
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount 
    FROM 
        Posts p 
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        COALESCE(ub.BadgeCount, 0) AS BadgeCount, 
        COALESCE(ps.TotalPostScore, 0) AS TotalPostScore, 
        COALESCE(ps.AnswerCount, 0) AS AnswerCount, 
        u.DisplayName
    FROM 
        Users u 
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId 
    LEFT JOIN 
        PostScore ps ON u.Id = ps.OwnerUserId 
)
SELECT 
    ua.UserId, 
    ua.DisplayName, 
    ua.BadgeCount, 
    ua.TotalPostScore, 
    ua.AnswerCount 
FROM 
    UserActivity ua 
WHERE 
    ua.BadgeCount > 0 
    OR ua.TotalPostScore > 0 
    OR ua.AnswerCount > 0 
ORDER BY 
    ua.TotalPostScore DESC, 
    ua.BadgeCount DESC, 
    ua.AnswerCount DESC 
LIMIT 10;
