WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), PopularQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        PT.Name AS PostType,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE PT.Name = 'Question'
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate, PT.Name
    ORDER BY P.ViewCount DESC
    LIMIT 10
), UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        CASE WHEN PH.PostId IS NOT NULL THEN 'Edited' ELSE 'Original' END AS PostVersion
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE U.Reputation > 1000
), UserEngagement AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM UserVoteStats U
    LEFT JOIN Comments C ON U.UserId = C.UserId
    LEFT JOIN Votes V ON U.UserId = V.UserId
    GROUP BY U.UserId, U.DisplayName, U.Reputation
)
SELECT 
    UED.DisplayName,
    UED.Reputation,
    UED.PostId,
    UED.Title AS PostTitle,
    UED.ViewCount AS PostViews,
    PQ.CommentCount AS QuestionComments,
    UED.PostVersion,
    UE.CommentsMade,
    UE.UpvotesReceived,
    UE.DownvotesReceived
FROM UserEngagement UE
JOIN UserPostDetails UED ON UE.UserId = UED.UserId
LEFT JOIN PopularQuestions PQ ON UED.PostId = PQ.PostId
ORDER BY UED.Reputation DESC, UED.ViewCount DESC;
