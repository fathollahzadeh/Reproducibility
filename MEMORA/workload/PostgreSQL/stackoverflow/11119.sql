SELECT
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS PostCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT C.Id) AS TotalComments,
    AVG(P.Score) AS AveragePostScore,
    SUM(P.ViewCount) AS TotalViews
FROM
    Users U
JOIN
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN
    Votes V ON P.Id = V.PostId
LEFT JOIN
    Comments C ON P.Id = C.PostId
WHERE
    P.CreationDate >= '2023-01-01' 
GROUP BY
    U.Id, U.DisplayName
ORDER BY
    PostCount DESC, TotalUpVotes DESC;