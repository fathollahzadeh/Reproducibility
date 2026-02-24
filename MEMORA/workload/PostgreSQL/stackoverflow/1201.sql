
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.ReputationRank,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    COALESCE(PL.LinkedPosts, 0) AS TotalLinks
FROM 
    TopUsers U
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) B ON U.UserId = B.UserId
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT PL.RelatedPostId) AS LinkedPosts
    FROM 
        PostLinks PL
    JOIN 
        Posts P ON PL.PostId = P.Id
    GROUP BY 
        P.OwnerUserId
) PL ON U.UserId = PL.OwnerUserId
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
