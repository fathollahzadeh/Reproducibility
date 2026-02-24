
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COALESCE(A.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.AcceptedAnswerId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, A.AcceptedAnswerId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    UPS.TotalPosts,
    UPS.TotalScore,
    UPS.TotalViews,
    COUNT(DISTINCT PD.PostId) AS TotalQuestions,
    SUM(PD.CommentCount) AS TotalComments
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
LEFT JOIN 
    PostDetails PD ON U.Id = PD.OwnerUserId
WHERE 
    UPS.TotalPosts > 10 
GROUP BY 
    U.DisplayName, 
    UB.GoldBadges, 
    UB.SilverBadges, 
    UB.BronzeBadges, 
    UPS.TotalPosts, 
    UPS.TotalScore, 
    UPS.TotalViews
ORDER BY 
    UPS.TotalScore DESC,
    UPS.TotalViews DESC;
