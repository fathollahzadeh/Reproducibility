
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
    SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges,
    MAX(P.CreationDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation > 0
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;
