WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.TotalBadges, 0) AS BadgeCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionsCreated,
        COALESCE(PS.AnswerCount, 0) AS AnswersGiven,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViewCount, 0) AS AverageViewCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalScore, 0) DESC) AS RankScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.QuestionsCreated,
    U.AnswersGiven,
    U.TotalScore,
    U.AverageViewCount,
    CASE 
        WHEN U.RankScore <= 10 THEN 'Top Performer'
        ELSE 'Contributor'
    END AS PerformanceCategory
FROM 
    UserPerformance U
WHERE 
    U.QuestionsCreated > 5 OR U.AnswersGiven > 10
ORDER BY 
    U.TotalScore DESC NULLS LAST;
