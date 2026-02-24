WITH QuestionData AS (
    SELECT 
        p.Id AS QuestionId,
        p.CreationDate,
        p.AcceptedAnswerId,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
        COALESCE(p.LastActivityDate, p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
ResponseTime AS (
    SELECT 
        q.QuestionId,
        EXTRACT(EPOCH FROM (a.CreationDate - q.CreationDate)) AS ResponseTimeInSeconds
    FROM 
        QuestionData q
    LEFT JOIN 
        Posts a ON q.AcceptedAnswerId = a.Id
)

SELECT 
    AVG(ResponseTimeInSeconds) AS AvgResponseTime,
    AVG(AnswerCount) AS AvgAnswersPerQuestion,
    AVG(VoteCount) AS AvgVotesPerQuestion
FROM 
    QuestionData q
JOIN 
    ResponseTime r ON q.QuestionId = r.QuestionId;