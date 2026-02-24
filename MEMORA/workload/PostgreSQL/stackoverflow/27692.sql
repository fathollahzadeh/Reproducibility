
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(P.Score) AS AvgPostScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.PostId IS NOT NULL
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        AvgPostScore,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserStats
),
VoteStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(DISTINCT V.UserId) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title
),
TopVotedPosts AS (
    SELECT 
        PostId,
        Title,
        VoteCount,
        UpvoteCount,
        DownvoteCount,
        RANK() OVER (ORDER BY VoteCount DESC) AS PostRank
    FROM VoteStats
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.UpVotes,
    U.DownVotes,
    U.AvgPostScore,
    P.Title AS PostTitle,
    P.VoteCount,
    P.UpvoteCount,
    P.DownvoteCount,
    U.UserRank,
    P.PostRank
FROM TopUsers U
JOIN TopVotedPosts P ON U.UserId IN (
    SELECT DISTINCT V.UserId 
    FROM Votes V 
    WHERE V.PostId = P.PostId
)
WHERE U.UserRank <= 10 AND P.PostRank <= 10
ORDER BY U.UserRank, P.PostRank;
