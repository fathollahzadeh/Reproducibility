
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS RN,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS CreationRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, U.DisplayName
), 
PostStats AS (
    SELECT 
        RP.PostId,
        RP.Title,
        COALESCE(UP.Upvotes, 0) AS Upvotes,
        COALESCE(DP.Downvotes, 0) AS Downvotes,
        (COALESCE(UP.Upvotes, 0) - COALESCE(DP.Downvotes, 0)) AS NetVotes,
        CASE 
            WHEN RP.CreationRank <= 10 THEN 'Top 10'
            WHEN RP.RN <= 20 THEN 'Top 20'
            ELSE 'Other'
        END AS RankCategory
    FROM 
        RankedPosts RP
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Upvotes FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) UP ON RP.PostId = UP.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Downvotes FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId) DP ON RP.PostId = DP.PostId
),
PostHistoryData AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PHT.Name AS HistoryType,
        PH.CreationDate AS HistoryDate,
        PH.UserDisplayName,
        PH.Comment
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.NetVotes,
    PS.RankCategory,
    PHD.HistoryType,
    PHD.HistoryDate,
    PHD.UserDisplayName,
    PHD.Comment,
    CASE 
        WHEN PS.NetVotes IS NULL OR PS.NetVotes = 0 THEN 'No Votes' 
        WHEN PS.NetVotes > 0 THEN 'Positive'
        WHEN PS.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryData PHD ON PS.PostId = PHD.PostId
WHERE 
    PS.NetVotes IS NOT NULL
ORDER BY 
    PS.RankCategory, PS.NetVotes DESC, PHD.HistoryDate DESC NULLS LAST;
