WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS QuestionsScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS AnswersScore,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
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
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 END) AS EditCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UR.QuestionsScore,
    UR.AnswersScore,
    UR.PostCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PA.CommentCount,
    PA.EditCount,
    PA.TotalViews
FROM 
    Users U
LEFT JOIN 
    UserReputation UR ON U.Id = UR.UserId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostActivity PA ON U.Id = PA.OwnerUserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    UR.PostCount DESC;
