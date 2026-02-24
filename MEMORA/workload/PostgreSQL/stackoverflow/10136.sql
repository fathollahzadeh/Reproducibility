SELECT 
    PH.PostId,
    COUNT(PH.Id) AS RevisionCount,
    MAX(PH.CreationDate) AS LastRevisionDate,
    MIN(PH.CreationDate) AS FirstRevisionDate,
    U.DisplayName AS LastEditor,
    P.Title,
    P.Score,
    P.ViewCount
FROM 
    PostHistory PH
JOIN 
    Posts P ON PH.PostId = P.Id
LEFT JOIN 
    Users U ON PH.UserId = U.Id
GROUP BY 
    PH.PostId, U.DisplayName, P.Title, P.Score, P.ViewCount
ORDER BY 
    RevisionCount DESC, LastRevisionDate DESC;
