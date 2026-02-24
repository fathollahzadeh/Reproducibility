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
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.TotalBadges,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.TotalViews,
        PS.TotalScore
    FROM 
        Users U
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.TotalBadges,
    UP.TotalPosts,
    UP.Questions,
    UP.Answers,
    UP.TotalViews,
    UP.TotalScore,
    RANK() OVER (ORDER BY UP.TotalScore DESC) AS ScoreRank
FROM 
    UserPerformance UP
WHERE 
    UP.TotalPosts > 0
ORDER BY 
    UP.TotalScore DESC
LIMIT 10;
