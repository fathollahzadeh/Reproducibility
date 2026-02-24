SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    PH.CreationDate AS PostHistoryDate,
    PH.Comment AS EditComment,
    COUNT(C) AS CommentCount,
    SUM(V.BountyAmount) AS TotalBounty,
    AVG(P.Score) AS AverageScore
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    PH.CreationDate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND PH.PostHistoryTypeId IN (4, 5, 6)  
GROUP BY 
    U.DisplayName, P.Title, PH.CreationDate, PH.Comment
ORDER BY 
    U.DisplayName, PH.CreationDate DESC;