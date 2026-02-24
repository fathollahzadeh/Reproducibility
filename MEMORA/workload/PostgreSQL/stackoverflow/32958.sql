
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.CreationDate,
        RP.OwnerName
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 3
),
PostVoteCounts AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostDetails AS (
    SELECT 
        T.Title,
        T.Score,
        T.CreationDate,
        T.OwnerName,
        COALESCE(PV.UpVotes, 0) AS UpVotes,
        COALESCE(PV.DownVotes, 0) AS DownVotes,
        (COALESCE(PV.UpVotes, 0) - COALESCE(PV.DownVotes, 0)) AS NetVotes,
        T.CreationDate AS LastActivityDate  -- Assuming LastActivityDate was meant to reference CreationDate
    FROM 
        TopRankedPosts T
    LEFT JOIN 
        PostVoteCounts PV ON T.PostId = PV.PostId
),
FinalResults AS (
    SELECT
        PD.Title,
        PD.Score,
        PD.OwnerName,
        PD.UpVotes,
        PD.DownVotes,
        PD.NetVotes,
        PD.CreationDate,
        PD.LastActivityDate,
        RANK() OVER (PARTITION BY PD.OwnerName ORDER BY PD.NetVotes DESC) AS OwnerRank
    FROM 
        PostDetails PD
    WHERE 
        PD.NetVotes > 0 OR PD.OwnerName IS NOT NULL  
)
SELECT 
    FR.Title,
    FR.Score,
    FR.OwnerName,
    FR.UpVotes,
    FR.DownVotes,
    FR.NetVotes,
    FR.OwnerRank
FROM 
    FinalResults FR
WHERE 
    FR.OwnerRank <= 2
ORDER BY 
    FR.OwnerName, FR.NetVotes DESC;
