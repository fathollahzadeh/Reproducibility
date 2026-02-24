
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
    AVG(P.ViewCount) AS AverageViewCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags,
    COUNT(B.Id) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
LEFT JOIN 
    Tags T ON PL.RelatedPostId = T.Id
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    TotalPosts DESC;
