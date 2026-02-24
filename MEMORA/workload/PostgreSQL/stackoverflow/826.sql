
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        V.PostId
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
),
FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        COALESCE(RV.VoteCount, 0) AS TotalVotes,
        COALESCE(RV.UpVotes, 0) AS UpVotes,
        COALESCE(RV.DownVotes, 0) AS DownVotes,
        COALESCE(PHC.EditCount, 0) AS EditCount,
        RP.PostRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        RecentVotes RV ON RP.PostId = RV.PostId
    LEFT JOIN 
        PostHistoryCounts PHC ON RP.PostId = PHC.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    TotalVotes,
    UpVotes,
    DownVotes,
    EditCount
FROM 
    FinalResults
WHERE 
    PostRank <= 5
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 10 OFFSET 0;
