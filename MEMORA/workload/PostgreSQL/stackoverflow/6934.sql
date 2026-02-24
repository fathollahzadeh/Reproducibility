
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswersAccepted,
        SUM(CASE WHEN P.CommentCount > 0 THEN 1 ELSE 0 END) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostEngagement AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT C.Id) AS TotalCommentsOnPosts,
        SUM(V.BountyAmount) AS TotalBountyConsumed
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) 
    GROUP BY P.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.Questions,
    UA.Answers,
    UA.TotalAnswersAccepted,
    UA.TotalComments,
    COALESCE(BS.TotalBadges, 0) AS TotalBadges,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PE.TotalCommentsOnPosts, 0) AS TotalCommentsOnPosts,
    COALESCE(PE.TotalBountyConsumed, 0) AS TotalBountyConsumed
FROM UserActivity UA
LEFT JOIN BadgeSummary BS ON UA.UserId = BS.UserId
LEFT JOIN PostEngagement PE ON UA.UserId = PE.OwnerUserId
ORDER BY UA.TotalPosts DESC, UA.DisplayName ASC;
