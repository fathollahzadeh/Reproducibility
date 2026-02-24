WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeAwarded,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserViews AS (
    SELECT 
        U.Id AS UserId,
        SUM(U.Views) AS TotalViews
    FROM 
        Users U
    GROUP BY 
        U.Id
),
ActiveUserBadges AS (
    SELECT 
        M.UserId,
        M.DisplayName,
        M.PostCount,
        M.TotalScore,
        B.BadgeCount,
        B.LastBadgeAwarded,
        B.BadgeNames,
        V.TotalViews
    FROM 
        MostActiveUsers M
    JOIN 
        UserBadges B ON M.UserId = B.UserId
    JOIN 
        UserViews V ON M.UserId = V.UserId
)
SELECT 
    AUB.DisplayName,
    AUB.PostCount,
    AUB.TotalScore,
    AUB.BadgeCount,
    AUB.LastBadgeAwarded,
    AUB.BadgeNames,
    AUB.TotalViews,
    ROW_NUMBER() OVER (ORDER BY AUB.PostCount DESC) AS Rank
FROM 
    ActiveUserBadges AUB
ORDER BY 
    AUB.TotalScore DESC, AUB.BadgeCount DESC, AUB.TotalViews DESC;
