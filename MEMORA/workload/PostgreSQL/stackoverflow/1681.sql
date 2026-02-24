WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerPostRank,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY P.Id) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY P.Id), 0) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
ClosedPostOptions AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseHistoryCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.TotalUpVotes,
        RP.TotalDownVotes,
        COALESCE(CPO.CloseHistoryCount, 0) AS NumberOfClosures
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPostOptions CPO ON RP.PostId = CPO.PostId
)
SELECT 
    PS.*,
    CASE 
        WHEN PS.NumberOfClosures > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    (CASE 
        WHEN PS.TotalUpVotes - PS.TotalDownVotes < 0 THEN 'Negative Impact'
        ELSE 'Positive Impact'
    END) AS UserImpact
FROM 
    PostStatistics PS
WHERE 
    PS.TotalUpVotes > PS.TotalDownVotes * 1.5
ORDER BY 
    PS.Score DESC, PS.CreationDate ASC
LIMIT 100;