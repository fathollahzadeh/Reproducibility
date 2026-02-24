WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND 
        P.Score > 0 
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        PV.UpVotes,
        PV.DownVotes
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostVotes PV ON RP.PostId = PV.PostId
    WHERE 
        RP.PostRank <= 5
)
SELECT 
    TP.PostId, 
    TP.Title, 
    TP.CreationDate, 
    TP.Score, 
    COALESCE(TP.UpVotes, 0) - COALESCE(TP.DownVotes, 0) AS NetVotes, 
    TP.OwnerDisplayName
FROM 
    TopPosts TP
ORDER BY 
    NetVotes DESC, 
    TP.Score DESC;