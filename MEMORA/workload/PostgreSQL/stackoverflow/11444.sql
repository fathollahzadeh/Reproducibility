WITH Benchmark AS (
    SELECT 
        PH.Id AS PostHistoryId,
        PT.Name AS PostType,
        P.Title AS PostTitle,
        P.CreationDate AS PostCreationDate,
        U.DisplayName AS UserDisplayName,
        PH.CreationDate AS HistoryCreationDate,
        PH.Comment AS HistoryComment,
        PH.Text AS HistoryText
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    PostType,
    COUNT(*) AS TotalHistoryEntries,
    MIN(HistoryCreationDate) AS FirstEntryDate,
    MAX(HistoryCreationDate) AS LastEntryDate,
    AVG(EXTRACT(EPOCH FROM HistoryCreationDate - PostCreationDate)) AS AvgTimeToHistoryEntry
FROM 
    Benchmark
GROUP BY 
    PostType
ORDER BY 
    TotalHistoryEntries DESC;