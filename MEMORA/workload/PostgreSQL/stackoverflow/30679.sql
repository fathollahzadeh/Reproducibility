WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        U.Id AS UserId,
        U.Reputation,
        UR.Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserReputation UR ON U.Id = UR.UserId
    WHERE 
        UR.Level < 3  
), 

TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Ranking
    FROM 
        Users U
), 

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        MAX(PH.CreationDate) AS LastEditDate,
        PT.Name AS PostType
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    INNER JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, PT.Name
), 

AggregateVoteCounts AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END) AS Deletions
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.LastEditDate,
    PS.PostType,
    COALESCE(AVC.UpVotes, 0) AS TotalUpVotes,
    COALESCE(AVC.DownVotes, 0) AS TotalDownVotes,
    COALESCE(AVC.Deletions, 0) AS TotalDeletions
FROM 
    TopUsers TU
JOIN 
    Posts P ON P.OwnerUserId = TU.UserId
JOIN 
    PostStatistics PS ON PS.PostId = P.Id
LEFT JOIN 
    AggregateVoteCounts AVC ON AVC.PostId = P.Id
WHERE 
    TU.Ranking <= 10
ORDER BY 
    TU.Reputation DESC, 
    PS.Score DESC;