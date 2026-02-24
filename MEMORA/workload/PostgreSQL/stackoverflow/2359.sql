
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.Score, 
        COALESCE(COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END), 0) AS CommentCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS ViewRank,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year')
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.PostTypeId
),
PostVotes AS (
    SELECT 
        V.PostId, 
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteNet
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
FinalReport AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.CommentCount,
        COALESCE(PV.VoteNet, 0) AS VoteNet,
        COALESCE(PHS.ClosureCount, 0) AS ClosureCount,
        COALESCE(PHS.DeletionCount, 0) AS DeletionCount,
        RP.ViewRank,
        RP.ScoreRank,
        CASE 
            WHEN RP.ViewRank <= 10 THEN 'Top View'
            WHEN RP.ScoreRank <= 10 THEN 'Top Score'
            ELSE 'Regular' 
        END AS RankCategory
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostVotes PV ON RP.PostId = PV.PostId
    LEFT JOIN 
        PostHistoryStats PHS ON RP.PostId = PHS.PostId
)
SELECT 
    Title, 
    ViewCount, 
    CommentCount, 
    VoteNet, 
    ClosureCount, 
    DeletionCount, 
    RankCategory
FROM 
    FinalReport
WHERE 
    VoteNet > 0 OR ClosureCount > 0
ORDER BY 
    ViewCount DESC, 
    ScoreRank ASC;
