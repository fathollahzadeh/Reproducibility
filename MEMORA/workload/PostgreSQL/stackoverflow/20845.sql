WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS RankByViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
), 

ClosedPosts AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS ClosureCount, 
        STRING_AGG(DISTINCT C.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        PH.PostId
), 

ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(COALESCE(U.UpVotes, 0) - COALESCE(U.DownVotes, 0)) AS ReputationChange
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.OwnerName,
    RP.RankByViewCount,
    CP.ClosureCount,
    COALESCE(CP.CloseReasons, 'No close reason recorded') AS CloseReasons,
    AU.UserId,
    AU.DisplayName AS ActiveUser,
    AU.PostsCount,
    AU.ReputationChange
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    ActiveUsers AU ON RP.OwnerName = AU.DisplayName
WHERE 
    (RP.RankByViewCount <= 5 OR CP.ClosureCount > 0)
ORDER BY 
    RP.ViewCount DESC, 
    RP.Score DESC;