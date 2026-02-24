WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswersToQuestions
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
RankedUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.TotalPosts,
        UR.TotalQuestions,
        UR.TotalAnswers,
        UR.TotalClosedPosts,
        UR.TotalAnswersToQuestions,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY UR.Reputation DESC) AS Rank
    FROM 
        UserReputation UR
    LEFT JOIN 
        UserBadges UB ON UR.UserId = UB.UserId
)
SELECT 
    Rank,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalClosedPosts,
    TotalAnswersToQuestions,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    RankedUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
