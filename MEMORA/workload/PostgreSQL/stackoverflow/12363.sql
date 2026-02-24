WITH PostActivities AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS TotalChanges,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteVotes,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(pa.TotalChanges, 0) AS TotalChanges,
        COALESCE(pa.CloseVotes, 0) AS CloseVotes,
        COALESCE(pa.ReopenVotes, 0) AS ReopenVotes,
        COALESCE(pa.DeleteUndeleteVotes, 0) AS DeleteUndeleteVotes,
        pa.LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        PostActivities pa ON p.Id = pa.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    TotalChanges,
    CloseVotes,
    ReopenVotes,
    DeleteUndeleteVotes,
    LastActivityDate
FROM 
    PostStatistics
ORDER BY 
    Score DESC, 
    TotalChanges DESC;