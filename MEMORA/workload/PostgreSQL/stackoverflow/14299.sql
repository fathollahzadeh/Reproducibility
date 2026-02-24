WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PH.EditCount, 0) AS EditCount,
        COALESCE(C.Count, 0) AS CommentCount,
        COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(V.DownVoteCount, 0) AS DownVoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY 
            PostId
    ) PH ON PH.PostId = P.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Count
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON C.PostId = P.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON V.PostId = P.Id
)
SELECT 
    *
FROM 
    PostMetrics
ORDER BY 
    CreationDate DESC
LIMIT 100;