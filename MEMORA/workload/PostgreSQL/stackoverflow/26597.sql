
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount,
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
UserPosts AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        UP.TotalPosts,
        UP.QuestionsCount,
        UP.AnswersCount,
        UP.TotalViews,
        UP.TotalScore,
        RANK() OVER (ORDER BY UP.TotalScore DESC) AS ScoreRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        UserPosts UP ON U.Id = UP.OwnerUserId
    WHERE 
        U.Reputation > 0
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.BadgeCount,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    UA.TotalPosts,
    UA.QuestionsCount,
    UA.AnswersCount,
    UA.TotalViews,
    UA.TotalScore,
    UA.ScoreRank,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
     WHERE P.OwnerUserId = UA.UserId AND P.PostTypeId = 1) AS PopularTags
FROM 
    UserActivity UA
WHERE 
    UA.ScoreRank <= 10
ORDER BY 
    UA.TotalScore DESC;
