
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
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS PostRank
    FROM 
        Posts P 
    GROUP BY 
        P.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        PS.AvgScore,
        PS.TotalViews,
        PS.TotalQuestions,
        PS.TotalAnswers
    FROM
        (SELECT DISTINCT UserId, DisplayName FROM UserBadges) U
    LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
    LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
),
RankedUsers AS (
    SELECT 
        DisplayName,
        TotalBadges,
        TotalPosts,
        AvgScore,
        TotalViews,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY TotalBadges DESC, TotalPosts DESC) AS BadgePostRank
    FROM 
        UserPostBadgeStats
)
SELECT 
    R.DisplayName,
    R.TotalBadges,
    R.TotalPosts,
    R.AvgScore,
    R.TotalViews,
    (R.TotalAnswers * 1.0 / NULLIF(R.TotalQuestions, 0)) AS AnswerToQuestionRatio,
    R.BadgePostRank
FROM 
    RankedUsers R
WHERE 
    R.TotalPosts > 50
    AND (R.TotalBadges > 3 OR R.AvgScore > 10)
ORDER BY 
    R.BadgePostRank, 
    AnswerToQuestionRatio DESC
LIMIT 10;
