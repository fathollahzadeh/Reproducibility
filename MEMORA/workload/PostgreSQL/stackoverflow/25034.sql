WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END), 0) AS WikiCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
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
    ORDER BY 
        PostCount DESC
    LIMIT 10
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
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.QuestionCount,
    US.AnswerCount,
    US.WikiCount,
    US.AcceptedAnswerCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PT.TagName AS PopularTag
FROM 
    UserStats US
LEFT JOIN 
    UserBadges UB ON US.UserId = UB.UserId
CROSS JOIN 
    PopularTags PT
WHERE 
    US.Reputation > 1000 
ORDER BY 
    US.Reputation DESC,
    US.QuestionCount DESC,
    PT.PostCount DESC;