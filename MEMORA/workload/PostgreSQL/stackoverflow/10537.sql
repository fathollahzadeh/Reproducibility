WITH PostCount AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUsers,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM 
        Posts
),
VoteCount AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
),
AvgResponseTime AS (
    SELECT 
        AVG(EXTRACT(EPOCH FROM (FirstAnswer.CreationDate - Q.CreationDate))) AS AvgTimeToFirstAnswer
    FROM 
        Posts Q
    LEFT JOIN 
        Posts FirstAnswer ON Q.Id = FirstAnswer.ParentId
    WHERE 
        Q.PostTypeId = 1
)

SELECT 
    PC.TotalPosts,
    PC.TotalUsers,
    PC.TotalQuestions,
    PC.TotalAnswers,
    VC.TotalVotes,
    VC.TotalUpVotes,
    VC.TotalDownVotes,
    ART.AvgTimeToFirstAnswer
FROM 
    PostCount PC,
    VoteCount VC,
    AvgResponseTime ART;