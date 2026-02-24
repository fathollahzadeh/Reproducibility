
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CommentStats AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS TotalComments
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
FinalStats AS (
    SELECT 
        B.UserId,
        B.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.Questions, 0) AS TotalQuestions,
        COALESCE(P.Answers, 0) AS TotalAnswers,
        COALESCE(C.TotalComments, 0) AS TotalComments,
        B.BadgeCount,
        B.GoldBadges,
        B.SilverBadges,
        B.BronzeBadges,
        P.AvgScore
    FROM 
        UserBadges B
    LEFT JOIN 
        PostStats P ON B.UserId = P.OwnerUserId
    LEFT JOIN 
        CommentStats C ON B.UserId = C.UserId
)
SELECT 
    F.DisplayName,
    F.TotalPosts,
    F.TotalQuestions, 
    F.TotalAnswers,
    F.TotalComments,
    F.BadgeCount,
    F.GoldBadges,
    F.SilverBadges,
    F.BronzeBadges,
    ROUND(F.AvgScore, 2) AS AvgScore,
    CASE 
        WHEN F.BadgeCount > 5 THEN 'Experienced User'
        WHEN F.TotalPosts > 100 THEN 'Active Contributor'
        ELSE 'Newbie'
    END AS UserLevel
FROM 
    FinalStats F 
ORDER BY 
    F.TotalPosts DESC, F.BadgeCount DESC
LIMIT 10;
