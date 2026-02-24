
WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentPostDetails AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(PS.QuestionCount, 0) AS QuestionCount,
    COALESCE(PS.AnswerCount, 0) AS AnswerCount,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    RP.Title AS LatestPostTitle,
    RP.CreationDate AS LatestPostDate,
    RP.Score AS LatestPostScore
FROM Users u
LEFT JOIN UserBadgeCounts UB ON u.Id = UB.UserId
LEFT JOIN PostStats PS ON u.Id = PS.OwnerUserId
LEFT JOIN RecentPostDetails RP ON u.Id = RP.OwnerUserId AND RP.rn = 1
WHERE 
    u.Reputation > 1000
    AND (UB.BadgeCount IS NULL OR UB.BadgeCount > 5)
ORDER BY 
    COALESCE(PS.TotalScore, 0) DESC,
    COALESCE(RP.CreationDate, '1970-01-01') DESC;
