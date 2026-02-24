WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        COUNT(COALESCE(CM.Id, 0)) AS CommentCount,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    GROUP BY U.Id, U.DisplayName
),

UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.QuestionsAsked,
    UA.AnswersGiven,
    UA.PopularPosts,
    UA.CommentCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    UA.AvgReputation
FROM UserActivity UA
LEFT JOIN UserBadges UB ON UA.UserId = UB.UserId
ORDER BY UA.AvgReputation DESC, UA.QuestionsAsked DESC
LIMIT 10;
