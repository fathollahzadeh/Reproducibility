
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName, P.CreationDate, P.LastActivityDate, P.Score, P.ViewCount, P.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PHT.Name AS HistoryType,
        PH.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CreationDate AS PostCreationDate,
    RP.LastActivityDate,
    RP.Score,
    RP.ViewCount,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    PHD.HistoryType,
    PHD.HistoryDate,
    CASE 
        WHEN RP.ViewCount > 100 THEN 'High Views'
        WHEN RP.ViewCount BETWEEN 50 AND 100 THEN 'Medium Views'
        ELSE 'Low Views'
    END AS ViewCountCategory,
    RANK() OVER (ORDER BY RP.Score DESC) AS ScoreRank
FROM 
    RecentPosts RP
LEFT JOIN 
    PostHistoryDetails PHD ON RP.PostId = PHD.PostId AND PHD.HistoryRank = 1
WHERE 
    RP.OwnerPostRank <= 3
ORDER BY 
    RP.LastActivityDate DESC
FETCH FIRST 100 ROWS ONLY;
