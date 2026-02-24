
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments 
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        U.DisplayName AS OwnerDisplayName, 
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON C.PostId = P.Id
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, U.DisplayName
    ORDER BY COUNT(C.Id) DESC 
    LIMIT 10
)
SELECT 
    TU.DisplayName AS TopUser, 
    TU.Reputation AS UserReputation, 
    PP.Title AS PopularPostTitle, 
    PP.ViewCount AS PostViewCount, 
    PP.CommentCount AS PostCommentCount
FROM TopUsers TU
CROSS JOIN PopularPosts PP
WHERE TU.Rank <= 10
ORDER BY TU.Reputation DESC, PP.ViewCount DESC;
