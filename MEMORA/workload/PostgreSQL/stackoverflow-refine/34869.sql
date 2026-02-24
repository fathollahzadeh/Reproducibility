
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 

AnsweredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.AcceptedAnswerId
), 

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(ap.AnswerCount, 0) AS TotalAnswers,
    COALESCE(aph.UserDisplayName, 'None') AS LastEditedBy,
    COALESCE(aph.HistoryDate, rp.CreationDate) AS LastEditDate,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Score'
        WHEN rp.ScoreRank <= 5 THEN 'Top 5'
        ELSE 'Below Top 5'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    AnsweredPosts ap ON rp.PostId = ap.PostId
LEFT JOIN 
    RecentPostHistory aph ON rp.PostId = aph.PostId AND aph.HistoryRank = 1
WHERE 
    rp.PostTypeId = 1
    AND rp.ViewCount > 10
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
