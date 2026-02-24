
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.Reputation AS OwnerReputation,
    U.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    UNNEST(string_to_array(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '> <')) AS T(TagName) ON T.TagName IS NOT NULL
WHERE 
    P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, U.DisplayName, T.TagName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
