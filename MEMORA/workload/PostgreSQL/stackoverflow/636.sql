WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
    WHERE QuestionCount > 5
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        COALESCE(PL.RelatedPostId, 0) AS RelatedPostId,
        LT.Name AS LinkTypeName
    FROM Posts P
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN LinkTypes LT ON PL.LinkTypeId = LT.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
      AND P.ViewCount > 1000
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    PP.PostId,
    PP.Title,
    PP.ViewCount,
    PP.AnswerCount,
    PP.Score,
    PP.LinkTypeName
FROM TopUsers TU
LEFT JOIN PopularPosts PP ON TU.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PP.PostId)
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC, PP.ViewCount DESC;