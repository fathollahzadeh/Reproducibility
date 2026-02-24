SELECT
    U.DisplayName,
    P.Title,
    COUNT(C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM
    Posts P
JOIN
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN
    Comments C ON P.Id = C.PostId
LEFT JOIN
    Votes V ON P.Id = V.PostId
WHERE
    P.PostTypeId = 1 
GROUP BY
    U.DisplayName, P.Title
ORDER BY
    UpVoteCount DESC
LIMIT 10;