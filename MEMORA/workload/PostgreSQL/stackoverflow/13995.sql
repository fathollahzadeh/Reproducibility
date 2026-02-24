
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsClosed,
        P.OwnerUserId
    FROM Posts P
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalComments,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    COUNT(DISTINCT PS.PostId) AS EngagedPosts,
    AVG(PS.ViewCount) AS AvgViewCount,
    AVG(PS.Score) AS AvgScore,
    SUM(PS.IsClosed) AS ClosedPosts
FROM UserStats U
LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
GROUP BY U.UserId, U.DisplayName, U.Reputation, U.TotalPosts, U.TotalQuestions, U.TotalAnswers, U.TotalComments, U.GoldBadges, U.SilverBadges, U.BronzeBadges
ORDER BY U.Reputation DESC;
