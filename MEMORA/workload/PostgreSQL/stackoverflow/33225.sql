WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.Score > 0
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.UserDisplayName,
        PH.CreationDate,
        COALESCE(PH.Comment, 'No Comment') AS Comment
    FROM 
        PostHistory PH
    LEFT JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Name IN ('Post Closed', 'Post Reopened', 'Edit Body') 
        AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
RecursiveVotes AS (
    SELECT 
        P.Id AS PostId,
        V.VoteTypeId,
        V.UserId,
        COUNT(*) AS VoteCount
    FROM 
        Posts P
    INNER JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, V.VoteTypeId, V.UserId
    HAVING 
        COUNT(*) > 2
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RP.CreationDate,
    RP.UpVoteCount,
    RP.DownVoteCount,
    COALESCE(PHD.Comment, 'No Activity') AS RecentActivity,
    CASE 
        WHEN RV.VoteCount IS NOT NULL 
        THEN 'High Voting Activity'
        ELSE 'Normal Activity' 
    END AS ActivityStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistoryDetails PHD ON RP.PostId = PHD.PostId
LEFT JOIN 
    RecursiveVotes RV ON RP.PostId = RV.PostId
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;