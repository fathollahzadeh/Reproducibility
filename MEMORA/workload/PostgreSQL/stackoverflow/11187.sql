SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(AVG(vote_count), 0) AS AvgVotes,
    COALESCE(AVG(comment_count), 0) AS AvgComments,
    COALESCE(AVG(answer_count), 0) AS AvgAnswers
FROM
    PostTypes pt
LEFT JOIN
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN (
    SELECT PostId, COUNT(*) AS vote_count
    FROM Votes
    GROUP BY PostId
) v ON v.PostId = p.Id
LEFT JOIN (
    SELECT PostId, COUNT(*) AS comment_count
    FROM Comments
    GROUP BY PostId
) c ON c.PostId = p.Id
LEFT JOIN (
    SELECT ParentId AS PostId, COUNT(*) AS answer_count
    FROM Posts
    WHERE PostTypeId = 2  
    GROUP BY ParentId
) a ON a.PostId = p.Id
GROUP BY
    pt.Name
ORDER BY
    pt.Name;