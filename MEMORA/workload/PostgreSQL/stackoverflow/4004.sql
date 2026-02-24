
WITH UserBadges AS (
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
PostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PM.TotalPosts,
        PM.TotalQuestions,
        PM.TotalAnswers,
        PM.AvgScore,
        PM.TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostMetrics PM ON U.Id = PM.OwnerUserId
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        BadgeCount, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        AvgScore, 
        TotalViews
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0 
    ORDER BY 
        TotalPosts DESC, AvgScore DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    COALESCE(TU.BadgeCount, 0) AS BadgeCount,
    COALESCE(TU.TotalPosts, 0) AS TotalPosts,
    COALESCE(TU.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(TU.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(TU.AvgScore, 0) AS AvgScore,
    COALESCE(TU.TotalViews, 0) AS TotalViews,
    PHT.Name AS RecentPostEditType
FROM 
    TopUsers TU
LEFT JOIN 
    PostHistory PH ON PH.UserId = TU.UserId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id 
WHERE 
    PH.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory
        WHERE UserId = TU.UserId
    )
ORDER BY 
    TU.BadgeCount DESC, TU.TotalPosts DESC;
