SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    COALESCE(SUM(V.VoteCount), 0) AS TotalVotes,
    COALESCE(SUM(V.UpVotes), 0) AS TotalUpVotes,
    COALESCE(SUM(V.DownVotes), 0) AS TotalDownVotes,
    COALESCE(AVG(P.ViewCount), 0) AS AvgViewCount,
    COALESCE(AVG(P.Score), 0) AS AvgScore,
    COALESCE(AVG(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE NULL END), 0) AS AvgAcceptedAnswers
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS VoteCount, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM 
        Votes 
     GROUP BY 
        PostId) V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC;