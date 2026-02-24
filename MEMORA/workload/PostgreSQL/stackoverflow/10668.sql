
SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN COALESCE(p.AnswerCount, 0) ELSE NULL END) AS AvgAnswersPerQuestion,
    SUM(CASE WHEN v.VoteTypeId = 2 OR v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalVotes  
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;
