WITH UserBadgeStats AS (
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
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.ViewCount) AS AvgViewsPerPost
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS TotalQuestions,
        COALESCE(PS.Answers, 0) AS TotalAnswers,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeStats UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
),
HighEngagementUsers AS (
    SELECT 
        UE.UserId,
        UE.DisplayName,
        UE.TotalBadges,
        UE.TotalPosts,
        UE.TotalQuestions,
        UE.TotalAnswers,
        UE.TotalScore,
        UE.TotalViews,
        CAST(UE.TotalScore AS FLOAT) / NULLIF(UE.TotalPosts, 0) AS AvgScorePerPost,
        CAST(UE.TotalViews AS FLOAT) / NULLIF(UE.TotalPosts, 0) AS AvgViewsPerPost
    FROM 
        UserEngagement UE
    WHERE 
        UE.TotalPosts > 10
)
SELECT 
    H.UserId,
    H.DisplayName,
    H.TotalBadges,
    H.TotalPosts,
    H.TotalQuestions,
    H.TotalAnswers,
    H.TotalScore,
    H.TotalViews,
    H.AvgScorePerPost,
    H.AvgViewsPerPost
FROM 
    HighEngagementUsers H
ORDER BY 
    H.AvgScorePerPost DESC, H.TotalViews DESC
LIMIT 10;
