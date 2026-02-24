WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PS.PostCount,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.TotalViews,
        PS.TotalScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UPM.UserId,
    UPM.DisplayName,
    COALESCE(UPM.BadgeCount, 0) AS BadgeCount,
    COALESCE(UPM.PostCount, 0) AS PostCount,
    COALESCE(UPM.QuestionCount, 0) AS QuestionCount,
    COALESCE(UPM.AnswerCount, 0) AS AnswerCount,
    COALESCE(UPM.TotalViews, 0) AS TotalViews,
    COALESCE(UPM.TotalScore, 0) AS TotalScore,
    CASE 
        WHEN UPM.BadgeCount >= 10 THEN 'High Achiever'
        WHEN UPM.BadgeCount >= 5 THEN 'Active Contributor'
        ELSE 'New User'
    END AS UserTier
FROM 
    UserPostMetrics UPM
ORDER BY 
    UPM.TotalScore DESC, 
    UPM.BadgeCount DESC;