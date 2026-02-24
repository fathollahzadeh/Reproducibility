WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalPositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS TotalNegativePosts,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Body' THEN 1 ELSE 0 END) AS TotalBodyEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Title' THEN 1 ELSE 0 END) AS TotalTitleEdits
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId
),
BadgesSummary AS (
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
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalPositivePosts,
    UPS.TotalNegativePosts,
    UPS.AverageScore,
    UPS.LastPostDate,
    PHC.TotalEdits,
    PHC.TotalBodyEdits,
    PHC.TotalTitleEdits,
    BS.TotalBadges,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistoryCounts PHC ON UPS.UserId = PHC.UserId
LEFT JOIN 
    BadgesSummary BS ON UPS.UserId = BS.UserId
ORDER BY 
    UPS.TotalPosts DESC, UPS.AverageScore DESC;
