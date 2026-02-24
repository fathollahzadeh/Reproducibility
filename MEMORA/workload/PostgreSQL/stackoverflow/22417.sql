WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostVoteDetails AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Votes V
    JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS EditTypes,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    PVD.UpVotes,
    PVD.DownVotes,
    PVD.TotalVotes,
    COALESCE(PHS.EditTypes, 'No Edits') AS EditTypes,
    PHS.EditCount AS EditCount,
    PHS.LastEditDate,
    CASE 
        WHEN RP.AcceptedAnswerId IS NOT NULL THEN 
            (SELECT COUNT(*) FROM Posts WHERE Id = RP.AcceptedAnswerId AND PostTypeId = 2)
        ELSE 
            0 
    END AS AcceptedAnswersCount
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVoteDetails PVD ON RP.PostId = PVD.PostId
LEFT JOIN 
    PostHistorySummary PHS ON RP.PostId = PHS.PostId
WHERE 
    RP.PostRank <= 10
ORDER BY 
    RP.CreationDate DESC;