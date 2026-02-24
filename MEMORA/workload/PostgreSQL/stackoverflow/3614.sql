
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Upvotes,
        Downvotes,
        PostCount,
        RANK() OVER (ORDER BY (Upvotes - Downvotes) DESC) AS UserRank
    FROM UserReputation
)

SELECT 
    TU.DisplayName,
    TU.Upvotes,
    TU.Downvotes,
    TU.PostCount,
    COALESCE((
        SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
        FROM Posts P 
        JOIN Tags T ON T.ExcerptPostId = P.Id 
        WHERE P.OwnerUserId = TU.UserId
    ), 'No Tags') AS TagsUsed,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.UserId = TU.UserId) AS CommentsMade
FROM TopUsers TU
LEFT JOIN Badges B ON TU.UserId = B.UserId AND B.Class = 1
WHERE TU.UserRank <= 10
ORDER BY TU.UserRank;
