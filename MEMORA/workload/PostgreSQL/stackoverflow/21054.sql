
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
        AND P.Score IS NOT NULL
        AND (P.ViewCount > 0 OR P.AcceptedAnswerId IS NOT NULL)
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName, P.PostTypeId, P.CreationDate
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.TotalComments
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5
),
PostVoteCounts AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes V
    INNER JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        V.PostId
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.OwnerDisplayName,
    TP.TotalComments,
    COALESCE(PVC.UpVoteCount, 0) AS UpVotes,
    COALESCE(PVC.DownVoteCount, 0) AS DownVotes,
    CASE 
        WHEN TP.Score > 0 THEN 'Positive'
        WHEN TP.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    CASE 
        WHEN TP.TotalComments > 10 THEN 'Highly Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TopPosts TP
LEFT JOIN 
    PostVoteCounts PVC ON TP.PostId = PVC.PostId
ORDER BY 
    TP.Score DESC,
    TP.TotalComments DESC
FETCH FIRST 10 ROWS ONLY;
