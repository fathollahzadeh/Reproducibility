WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(P.Score) AS AverageScore,
        MIN(P.CreationDate) AS AccountStartDate,
        MAX(P.LastActivityDate) AS LastActiveDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeStatistics AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostHistoryCounts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleBodyTagEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenActions
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.PopularPosts,
    U.AverageScore,
    B.TotalBadges,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    PH.TotalEdits,
    PH.TitleBodyTagEdits,
    PH.CloseReopenActions,
    U.AccountStartDate,
    U.LastActiveDate
FROM 
    UserStatistics U
LEFT JOIN 
    BadgeStatistics B ON U.UserId = B.UserId
LEFT JOIN 
    PostHistoryCounts PH ON U.UserId = PH.UserId
WHERE 
    U.TotalPosts > 10
ORDER BY 
    U.PopularPosts DESC, U.AverageScore DESC;
