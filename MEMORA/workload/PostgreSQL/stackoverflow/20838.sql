WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.ID) AS CommentCount,
        COALESCE(SUM(V.UserId), 0) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) 
    GROUP BY P.Id, P.OwnerUserId
),
ActivePostOwners AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(PA.CommentCount) AS TotalComments,
        SUM(PA.VoteCount) AS TotalVotes
    FROM Posts P
    JOIN PostActivity PA ON P.Id = PA.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        UR.ReputationRank,
        A.PostCount,
        A.TotalComments,
        A.TotalVotes
    FROM ActivePostOwners A
    JOIN UserReputation UR ON A.OwnerUserId = UR.UserId
    JOIN Users U ON A.OwnerUserId = U.Id
    WHERE UR.ReputationRank <= 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(A.PostCount, 0) AS ActivePosts,
    COALESCE(A.TotalComments, 0) AS TotalComments,
    COALESCE(A.TotalVotes, 0) AS TotalVotes,
    CONCAT(U.DisplayName, ': ', CASE 
        WHEN U.Reputation > 1000 THEN 'Expert' 
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate' 
        ELSE 'Beginner' 
    END) AS ReputationCategory
FROM Users U
LEFT JOIN ActivePostOwners A ON U.Id = A.OwnerUserId
WHERE U.LastAccessDate IS NOT NULL
ORDER BY U.Reputation DESC;