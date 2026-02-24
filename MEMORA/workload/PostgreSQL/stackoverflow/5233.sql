WITH UserReputation AS (
    SELECT Id, Reputation, LastAccessDate, CreationDate 
    FROM Users 
    WHERE Reputation > 1000
), 
PostStats AS (
    SELECT P.Id AS PostId, 
           P.OwnerUserId,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount, 
           COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
           COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
           COUNT(CASE WHEN PH.Id IS NOT NULL AND PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate > '2022-01-01'
    GROUP BY P.Id, P.OwnerUserId
), 
UserWithPosts AS (
    SELECT U.Id AS UserId,
           U.Reputation,
           U.LastAccessDate,
           U.CreationDate,
           PS.PostId,
           PS.CommentCount,
           PS.UpvoteCount,
           PS.DownvoteCount,
           PS.CloseCount
    FROM UserReputation U
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT U.UserId,
       U.Reputation,
       U.LastAccessDate,
       U.CreationDate,
       SUM(U.CommentCount) AS TotalComments,
       SUM(U.UpvoteCount) AS TotalUpvotes,
       SUM(U.DownvoteCount) AS TotalDownvotes,
       SUM(U.CloseCount) AS TotalClosures
FROM UserWithPosts U
GROUP BY U.UserId, U.Reputation, U.LastAccessDate, U.CreationDate
ORDER BY TotalUpvotes DESC, TotalComments DESC
LIMIT 10;
