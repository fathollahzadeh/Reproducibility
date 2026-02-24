WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Owner,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Owner,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        PVC.UpVotes,
        PVC.DownVotes
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostVoteCounts PVC ON RP.PostId = PVC.PostId
    WHERE 
        RP.Rank <= 5
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Owner,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    COALESCE(TP.UpVotes, 0) AS UpVotes,
    COALESCE(TP.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN TP.Score > 100 THEN 'High scorer'
        WHEN TP.Score BETWEEN 50 AND 100 THEN 'Moderate scorer'
        ELSE 'Low scorer'
    END AS ScoreCategory
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC;