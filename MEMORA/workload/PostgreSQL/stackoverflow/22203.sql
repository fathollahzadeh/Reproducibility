WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RecentPostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 END) AS RecentActivityCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivitySummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AverageViews, 0) AS AverageViews,
        COALESCE(RPA.RecentActivityCount, 0) AS RecentActivityCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        RecentPostActivity RPA ON U.Id = RPA.OwnerUserId
)
SELECT 
    UAS.UserId,
    UAS.DisplayName,
    UAS.BadgeCount,
    UAS.PostCount,
    UAS.QuestionCount,
    UAS.AnswerCount,
    UAS.TotalScore,
    UAS.AverageViews,
    UAS.RecentActivityCount
FROM 
    UserActivitySummary UAS
WHERE 
    UAS.BadgeCount > 0 
    AND (UAS.TotalScore >= (SELECT AVG(TotalScore) FROM PostStatistics WHERE TotalScore IS NOT NULL) OR UAS.RecentActivityCount > 5)
ORDER BY 
    UAS.TotalScore DESC, UAS.QuestionCount DESC
LIMIT 10;