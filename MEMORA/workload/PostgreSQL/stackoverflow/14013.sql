
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS PostCount,
    SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT C.Id) AS CommentCount,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    AVG(P.Score) AS AveragePostScore,
    MAX(P.LastActivityDate) AS LastActivePostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.DisplayName, U.Reputation, U.Id
ORDER BY 
    TotalViews DESC, PostCount DESC
LIMIT 100;
