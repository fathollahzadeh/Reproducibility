
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
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
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(AVG(P.Score), 0) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.TotalBadges, 0) AS BadgeCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AvgScore, 0) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
),
HighestPerformingUsers AS (
    SELECT 
        UserId,
        DisplayName,
        AVG(TotalViews) + SUM(BadgeCount) AS PerformanceScore
    FROM 
        UserPerformance
    GROUP BY 
        UserId, DisplayName
    ORDER BY 
        PerformanceScore DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.BadgeCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalViews,
    U.AvgScore,
    HP.PerformanceScore
FROM 
    UserPerformance U
JOIN 
    HighestPerformingUsers HP ON U.UserId = HP.UserId
WHERE 
    U.QuestionCount > 10
    AND (U.AnswerCount > 5 OR U.BadgeCount > 5)
ORDER BY 
    U.AvgScore DESC, U.TotalViews DESC;
