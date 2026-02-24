
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostInteractions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(DISTINCT PL.RelatedPostId) AS TotalRelatedPosts
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id, P.Title
),
CombinedStats AS (
    SELECT 
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.QuestionsCount,
        US.AnswersCount,
        US.WikiCount,
        US.Upvotes,
        US.Downvotes,
        US.TotalBadges,
        PI.Title AS PostTitle,
        PI.TotalComments,
        PI.TotalRelatedPosts
    FROM UserStats US
    JOIN PostInteractions PI ON PI.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = US.UserId)
)
SELECT 
    DisplayName, 
    Reputation, 
    TotalPosts, 
    QuestionsCount, 
    AnswersCount, 
    WikiCount,
    Upvotes, 
    Downvotes, 
    TotalBadges,
    PostTitle,
    TotalComments,
    TotalRelatedPosts
FROM CombinedStats
ORDER BY Reputation DESC, TotalPosts DESC
LIMIT 10;
