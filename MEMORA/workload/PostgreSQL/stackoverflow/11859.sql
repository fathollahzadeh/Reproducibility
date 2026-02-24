WITH LatestPostHistory AS (
    SELECT 
        Ph.PostId,
        Ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS rn
    FROM 
        PostHistory Ph
)

SELECT 
    P.Id AS PostId,
    P.Title,
    P.Body,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS AuthorDisplayName,
    U.Reputation AS AuthorReputation,
    LP.HistoryCreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, CreationDate AS HistoryCreationDate FROM LatestPostHistory WHERE rn = 1) LP 
    ON P.Id = LP.PostId
WHERE 
    P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
ORDER BY 
    P.CreationDate DESC;