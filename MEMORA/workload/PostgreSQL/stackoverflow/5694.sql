
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Upvotes,
        Downvotes,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.Upvotes,
    TU.Downvotes,
    TU.BadgeCount,
    RANK() OVER (ORDER BY TU.Upvotes DESC) AS UpvoteRank,
    RANK() OVER (ORDER BY TU.Downvotes DESC) AS DownvoteRank,
    RANK() OVER (ORDER BY TU.BadgeCount DESC) AS BadgeRank
FROM 
    TopUsers TU
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, TU.PostCount DESC;
