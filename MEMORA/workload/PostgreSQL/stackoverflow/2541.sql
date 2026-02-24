WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        Rank
    FROM 
        UserStats
    WHERE 
        Reputation IS NOT NULL
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
FinalResult AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        U.QuestionCount,
        U.AnswerCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        T.TagName
    FROM 
        TopUsers U
    LEFT JOIN 
        PopularTags T ON U.QuestionCount > 10
    ORDER BY 
        U.Rank
)
SELECT 
    COALESCE(F.DisplayName, 'Unknown') AS UserAlias,
    COALESCE(F.Reputation, 0) AS UserReputation,
    COALESCE(F.PostCount, 0) AS TotalPosts,
    COALESCE(F.QuestionCount, 0) AS TotalQuestions,
    COALESCE(F.AnswerCount, 0) AS TotalAnswers,
    COALESCE(F.GoldBadges, 0) AS GoldBadgeCount,
    COALESCE(F.SilverBadges, 0) AS SilverBadgeCount,
    COALESCE(F.BronzeBadges, 0) AS BronzeBadgeCount,
    UA.UserAlias AS TopUserAlias
FROM 
    FinalResult F
LEFT JOIN 
    (SELECT DISTINCT U.DisplayName AS UserAlias FROM Users U WHERE U.Reputation > (SELECT AVG(Reputation) FROM Users)) UA ON UA.UserAlias = F.DisplayName
WHERE 
    F.TagName IS NOT NULL OR F.TagName IS NOT NULL
ORDER BY 
    UserReputation DESC;
