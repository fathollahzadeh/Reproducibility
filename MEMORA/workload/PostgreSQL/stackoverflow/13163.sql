WITH BenchmarkData AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        u.CreationDate AS OwnerCreationDate,
        p.LastActivityDate
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
)
SELECT
    PostTypeId,
    COUNT(PostId) AS TotalPosts,
    AVG(ViewCount) AS AvgViews,
    AVG(Score) AS AvgScore,
    AVG(AnswerCount) AS AvgAnswers,
    AVG(CommentCount) AS AvgComments,
    AVG(OwnerReputation) AS AvgOwnerReputation,
    MAX(LastActivityDate) AS LastActivity
FROM
    BenchmarkData
GROUP BY
    PostTypeId
ORDER BY
    PostTypeId;