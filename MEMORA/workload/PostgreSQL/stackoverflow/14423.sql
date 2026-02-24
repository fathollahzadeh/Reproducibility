WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        p2.Title AS AcceptedAnswerTitle
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts p2 ON p.AcceptedAnswerId = p2.Id
    WHERE 
        p.PostTypeId = 1 
)

SELECT 
    COUNT(*) AS TotalQuestions,
    AVG(Score) AS AvgScore,
    AVG(ViewCount) AS AvgViewCount,
    AVG(AnswerCount) AS AvgAnswerCount,
    AVG(CommentCount) AS AvgCommentCount,
    MAX(OwnerReputation) AS MaxOwnerReputation,
    MIN(OwnerReputation) AS MinOwnerReputation
FROM 
    BenchmarkData;