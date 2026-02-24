SELECT 
    PH.PostId,
    COUNT(*) AS RevisionCount,
    MIN(PH.CreationDate) AS FirstRevisionDate,
    MAX(PH.CreationDate) AS LastRevisionDate,
    MAX(PH.UserDisplayName) AS LastEditedBy
FROM 
    PostHistory PH
GROUP BY 
    PH.PostId
ORDER BY 
    RevisionCount DESC
LIMIT 10;
