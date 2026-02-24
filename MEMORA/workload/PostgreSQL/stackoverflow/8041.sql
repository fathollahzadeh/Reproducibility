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
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalBadges,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalBadges DESC) AS BadgeRank
    FROM 
        UserBadges
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    T.DisplayName,
    T.TotalBadges,
    T.GoldBadges,
    T.SilverBadges,
    T.BronzeBadges,
    PS.TotalPosts,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.AverageScore,
    PS.TotalViews
FROM 
    TopUsers T
JOIN 
    PostStats PS ON T.UserId = PS.OwnerUserId
WHERE 
    T.BadgeRank <= 10 AND PS.PostRank <= 10
ORDER BY 
    T.BadgeRank, PS.PostRank;