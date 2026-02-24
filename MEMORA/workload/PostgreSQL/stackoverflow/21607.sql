WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1              
        AND p.Score > 0               
),
PostVotes AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes 
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        PH.PostId
),
SuspiciousPosts AS (
    SELECT 
        p.Id,
        p.Title,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id AND c.Score < 0) AS NegativeComments
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
        AND p.Score < 0
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.OwnerDisplayName,
    COALESCE(PV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PV.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PHD.HistoryTypes, 'No history') AS HistoryDetails,
    COALESCE(PHD.RevisionCount, 0) AS TotalRevisions,
    SP.NegativeComments AS TotalNegativeComments
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVotes PV ON RP.PostId = PV.PostId
LEFT JOIN 
    PostHistoryDetails PHD ON RP.PostId = PHD.PostId
LEFT JOIN 
    SuspiciousPosts SP ON RP.PostId = SP.Id
WHERE 
    RP.rn = 1 
    AND RP.OwnerUserId IS NOT NULL
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;