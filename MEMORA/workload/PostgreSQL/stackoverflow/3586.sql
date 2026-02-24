
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalBounties,
        Rank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 5
),
FinalResults AS (
    SELECT 
        TU.DisplayName,
        TU.Reputation,
        TU.TotalPosts,
        TU.TotalComments,
        TU.TotalBounties,
        COALESCE(PHT.Name, 'No Close Reason') AS LastCloseReason,
        TU.Rank
    FROM 
        TopUsers TU
    LEFT JOIN 
        PostHistory PH ON TU.UserId = PH.UserId
    LEFT JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    ORDER BY 
        TU.Rank
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalComments,
    TotalBounties,
    LastCloseReason
FROM 
    FinalResults
WHERE 
    Reputation > 100
UNION ALL
SELECT 
    'Total' AS DisplayName,
    SUM(Reputation) AS Reputation,
    SUM(TotalPosts) AS TotalPosts,
    SUM(TotalComments) AS TotalComments,
    SUM(TotalBounties) AS TotalBounties,
    NULL AS LastCloseReason
FROM 
    FinalResults
ORDER BY 
    Reputation DESC;
