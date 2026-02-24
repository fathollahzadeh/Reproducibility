WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS OwnerRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts P 
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, P.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PHT.Name AS HistoryType,
        PH.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 MONTH'
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RP.OwnerRank,
    RP.UpVoteCount,
    RP.DownVoteCount,
    RPH.HistoryType,
    RPH.HistoryDate
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentPostHistory RPH ON RP.PostId = RPH.PostId AND RPH.ChangeRank = 1
WHERE 
    RP.OwnerRank <= 3 
ORDER BY 
    RP.OwnerDisplayName, RP.Score DESC;