WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
)
SELECT 
    U.DisplayName,
    P.PostId,
    P.Title,
    P.TotalComments,
    P.TotalUpvotes,
    P.TotalDownvotes,
    U.Reputation,
    UR.ReputationRank,
    CASE 
        WHEN P.TotalUpvotes - P.TotalDownvotes > 10 THEN 'Highly Favorable'
        WHEN P.TotalUpvotes - P.TotalDownvotes BETWEEN 1 AND 10 THEN 'Favorable'
        WHEN P.TotalDownvotes - P.TotalUpvotes BETWEEN 1 AND 10 THEN 'Unfavorable'
        ELSE 'Highly Unfavorable'
    END AS PostSentiment
FROM 
    PostStats P
JOIN 
    Users U ON P.PostId = U.Id
JOIN 
    UserRankings UR ON U.Id = UR.UserId
WHERE 
    P.PostRank <= 5
ORDER BY 
    UR.ReputationRank, P.TotalUpvotes DESC
LIMIT 100;