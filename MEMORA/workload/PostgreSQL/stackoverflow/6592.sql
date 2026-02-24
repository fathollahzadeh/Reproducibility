
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        UpVotes,
        DownVotes
    FROM 
        UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.CommentCount,
    TU.TotalBounties,
    TU.UpVotes,
    TU.DownVotes
FROM 
    TopUsers TU
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC;
