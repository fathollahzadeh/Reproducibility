
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        Upvotes, 
        Downvotes,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts,
        RANK() OVER (ORDER BY Upvotes DESC) AS RankByUpvotes
    FROM UserActivity
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    PostCount, 
    CommentCount, 
    Upvotes, 
    Downvotes, 
    RankByPosts,
    RankByUpvotes
FROM TopUsers
WHERE RankByPosts <= 10 OR RankByUpvotes <= 10
ORDER BY RankByPosts, RankByUpvotes;
