
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        Views,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    *,
    (GoldBadges * 3 + SilverBadges * 2 + BronzeBadges * 1) AS BadgeScore
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    BadgeScore DESC, Reputation DESC;
