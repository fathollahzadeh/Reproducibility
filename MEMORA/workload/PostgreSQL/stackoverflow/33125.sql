WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
PostHistoryData AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    PVS.UpVotes,
    PVS.DownVotes,
    PHS.LastEditDate,
    COALESCE(PVS.UpVotes - PVS.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN PVS.TotalVotes IS NULL THEN 'No Votes'
        WHEN PVS.TotalVotes < 10 THEN 'Few Votes'
        ELSE 'Well-Voted'
    END AS VoteFeedback
FROM 
    TopPosts TP
LEFT JOIN 
    PostVoteSummary PVS ON TP.PostId = PVS.PostId
LEFT JOIN 
    PostHistoryData PHS ON TP.PostId = PHS.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;