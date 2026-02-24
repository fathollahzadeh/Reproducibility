
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.ViewCount AS PostViewCount,
    COUNT(V.Id) AS VoteCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    U.Reputation > 1000 
GROUP BY 
    U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes, 
    P.Title, P.CreationDate, P.ViewCount, P.Id, U.Id
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
