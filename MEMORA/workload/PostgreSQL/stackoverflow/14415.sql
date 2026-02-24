
WITH Benchmark AS (
    SELECT 
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS ActionCount,
        MIN(PH.CreationDate) AS FirstActionDate,
        MAX(PH.CreationDate) AS LastActionDate,
        EXTRACT(EPOCH FROM (MAX(PH.CreationDate) - MIN(PH.CreationDate))) AS DurationSeconds
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostHistoryTypeId
)

SELECT 
    PHT.Name AS ActionName,
    B.ActionCount,
    B.FirstActionDate,
    B.LastActionDate,
    B.DurationSeconds
FROM 
    Benchmark B
JOIN 
    PostHistoryTypes PHT ON B.PostHistoryTypeId = PHT.Id
ORDER BY 
    B.ActionCount DESC;
