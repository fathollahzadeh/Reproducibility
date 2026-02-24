
WITH RECURSIVE UserHierarchy AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Location,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 5000  
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Location,
        UH.Level + 1
    FROM 
        Users U
    JOIN 
        UserHierarchy UH ON U.Id = UH.Id + 1  
    WHERE 
        U.Reputation > UH.Reputation  
),
PostVoteDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes   
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days')  
    GROUP BY 
        P.Id, P.Title
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        PV.VoteCount,
        PV.UpVotes,
        PV.DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostVoteDetails PV ON P.Id = PV.PostId
    WHERE 
        P.PostTypeId = 1  
),

TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation >= (
            SELECT 
                AVG(Reputation) 
            FROM 
                Users 
            WHERE 
                LastAccessDate > (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year')  
        )
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
)

SELECT 
    RP.Title, 
    RP.CreationDate, 
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    TU.DisplayName AS TopUser,
    TU.Reputation AS TopUserReputation,
    COALESCE(RP.VoteCount, 0) AS TotalVotes,
    COALESCE(RP.UpVotes, 0) AS TotalUpVotes,
    COALESCE(RP.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN RP.OwnerUserId IS NULL THEN 'Unknown'
        ELSE 'Known User'
    END AS UserStatus
FROM 
    RecentPosts RP
LEFT JOIN 
    TopUsers TU ON RP.OwnerUserId = TU.Id
ORDER BY 
    RP.Score DESC,  
    RP.ViewCount DESC;
