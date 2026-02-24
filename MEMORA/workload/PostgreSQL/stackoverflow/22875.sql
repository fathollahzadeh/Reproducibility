WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY P.Score DESC) AS RankByLocation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND P.Score IS NOT NULL
), 
AggregatedVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes V
    GROUP BY 
        V.PostId
), 
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerName,
        AV.UpVoteCount,
        AV.DownVoteCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        AggregatedVotes AV ON RP.PostId = AV.PostId
    WHERE 
        RP.RankByLocation <= 5
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.OwnerName,
    COALESCE(PH.Comment, 'No comments') AS LastPostHistoryComment,
    COALESCE(SUM(CASE WHEN PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 days' THEN 1 END), 0) AS RecentChanges
FROM 
    PostDetails PD
LEFT JOIN 
    PostHistory PH ON PD.PostId = PH.PostId
GROUP BY 
    PD.PostId, PD.Title, PD.CreationDate, PD.Score, PD.ViewCount, PD.OwnerName, PH.Comment
HAVING 
    COUNT(PH.Id) > 0
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC, PD.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;