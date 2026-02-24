
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
AggregatedPostData AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalQuestions,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.OwnerDisplayName,
    r.AnswerCount,
    a.TotalQuestions,
    a.TotalScore,
    a.TotalViews,
    a.LastPostDate,
    ph.LastClosedDate,
    ph.LastReopenedDate,
    CASE 
        WHEN ph.LastClosedDate IS NOT NULL AND (ph.LastReopenedDate IS NULL OR ph.LastClosedDate > ph.LastReopenedDate) 
        THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RankedPosts r
JOIN 
    AggregatedPostData a ON r.OwnerUserId = a.OwnerUserId
LEFT JOIN 
    PostHistoryData ph ON r.PostId = ph.PostId
WHERE 
    r.Rank = 1 
ORDER BY 
    r.Score DESC, 
    r.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
