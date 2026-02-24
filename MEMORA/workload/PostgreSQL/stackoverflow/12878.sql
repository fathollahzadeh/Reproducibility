WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    rp.ViewRank,
    rp.ScoreRank,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryCreationDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory PH ON rp.PostId = PH.PostId
WHERE 
    rp.ViewRank <= 10 OR rp.ScoreRank <= 10
ORDER BY 
    rp.ViewRank, rp.ScoreRank;