
WITH PostEdits AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS EditDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate) AS EditNumber,
        LEAD(PH.CreationDate) OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate) AS NextEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
),
EditDurations AS (
    SELECT 
        PostId,
        EXTRACT(EPOCH FROM (NextEditDate - EditDate)) AS EditDurationSeconds
    FROM 
        PostEdits
    WHERE 
        NextEditDate IS NOT NULL
)
SELECT 
    AVG(EditDurationSeconds) AS AverageEditDurationSeconds,
    COUNT(*) AS TotalEdits
FROM 
    EditDurations
GROUP BY 
    PostId;
