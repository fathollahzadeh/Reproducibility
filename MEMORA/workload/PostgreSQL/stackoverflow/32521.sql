
WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation + 100 AS Reputation,
        U.CreationDate,
        UR.Level + 1
    FROM 
        Users U
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
    WHERE 
        UR.Level < 5
),
VoteDetails AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MIN(PH.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),
PostStatistics AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        PD.TotalUpvotes,
        PD.TotalDownvotes,
        PD.TotalVotes,
        COALESCE(CS.CloseCount, 0) AS CloseCount,
        COALESCE(CS.FirstCloseDate, DATE '1970-01-01') AS FirstCloseDate
    FROM 
        Posts P
    LEFT JOIN 
        VoteDetails PD ON P.Id = PD.PostId
    LEFT JOIN 
        ClosedPosts CS ON P.Id = CS.PostId
)
SELECT 
    PS.Title,
    PS.CreationDate,
    PS.TotalUpvotes,
    PS.TotalDownvotes,
    PS.TotalVotes,
    PS.CloseCount,
    ROUND(CAST(PS.TotalUpvotes AS decimal) / NULLIF(PS.TotalVotes, 0), 2) AS UpvoteRatio,
    U.DisplayName AS TopUser,
    R.Reputation AS UserReputation,
    R.CreationDate AS UserCreationDate
FROM 
    PostStatistics PS
JOIN 
    Users U ON PS.Id = U.Id 
JOIN 
    UserReputation R ON U.Id = R.UserId
WHERE 
    PS.TotalVotes > 0
ORDER BY 
    UpvoteRatio DESC
LIMIT 10;
