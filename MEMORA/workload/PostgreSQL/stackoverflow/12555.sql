WITH PostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        PC.TotalPosts,
        PC.TotalQuestions,
        PC.TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        PostCounts PC ON U.Id = PC.OwnerUserId
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    US.UserId,
    US.Reputation,
    US.Views,
    COALESCE(BC.TotalBadges, 0) AS TotalBadges,
    COALESCE(BC.GoldBadges, 0) AS GoldBadges,
    COALESCE(BC.SilverBadges, 0) AS SilverBadges,
    COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers
FROM 
    UserStats US
LEFT JOIN 
    BadgeCounts BC ON US.UserId = BC.UserId
ORDER BY 
    US.Reputation DESC, US.Views DESC;