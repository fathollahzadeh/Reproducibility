
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        PostCount,
        CommentCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(U.Upvotes - U.Downvotes, 0) AS NetVotes,
    U.PostCount,
    U.CommentCount,
    U.BadgeCount,
    CASE 
        WHEN U.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM TopUsers U
WHERE U.Reputation > (
    SELECT AVG(Reputation) FROM Users
) 
OR EXISTS (
    SELECT 1 
    FROM Posts P 
    WHERE P.OwnerUserId = U.UserId 
    AND P.AcceptedAnswerId IS NOT NULL
)
ORDER BY U.Reputation DESC
LIMIT 100 OFFSET 0;
