
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ReputationRank,
        PostCount
    FROM UserReputation
    WHERE ReputationRank <= 10
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id, P.OwnerUserId
),
OverallPostStats AS (
    SELECT 
        PS.OwnerUserId,
        COUNT(PS.PostId) AS TotalPosts,
        SUM(PS.UpVotes - PS.DownVotes) AS NetScore,
        SUM(PS.CommentCount) AS TotalComments,
        SUM(PS.RelatedPostCount) AS TotalRelatedPosts
    FROM PostStats PS
    GROUP BY PS.OwnerUserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(OPS.TotalPosts, 0) AS TotalPosts,
    COALESCE(OPS.NetScore, 0) AS NetScore,
    COALESCE(OPS.TotalComments, 0) AS TotalComments,
    COALESCE(OPS.TotalRelatedPosts, 0) AS TotalRelatedPosts
FROM TopUsers U
LEFT JOIN OverallPostStats OPS ON U.UserId = OPS.OwnerUserId
ORDER BY U.Reputation DESC;
