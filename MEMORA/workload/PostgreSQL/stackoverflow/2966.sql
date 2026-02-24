
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
AcceptedAnswers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(pa.Id) AS AcceptedCount
    FROM 
        Posts p
    JOIN 
        Posts pa ON p.AcceptedAnswerId = pa.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.AvgViewCount,
        COALESCE(aa.AcceptedCount, 0) AS AcceptedAnswers,
        COALESCE(ub.BadgeCount, 0) AS GoldBadges,
        COALESCE(ub.BadgeNames, 'None') AS GoldBadgeNames
    FROM 
        UserPostStats ups
    LEFT JOIN 
        AcceptedAnswers aa ON ups.UserId = aa.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON ups.UserId = ub.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount,
    TotalScore,
    AvgViewCount,
    AcceptedAnswers,
    GoldBadges,
    GoldBadgeNames
FROM 
    FinalStats
WHERE 
    TotalScore > 1000
ORDER BY 
    TotalScore DESC,
    PostCount DESC
FETCH FIRST 10 ROWS ONLY;
