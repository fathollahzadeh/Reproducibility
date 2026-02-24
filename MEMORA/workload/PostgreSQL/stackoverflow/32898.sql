
WITH RecursivePostHierarchy AS (
    
    SELECT 
        p.Id AS QuestionId,
        p.Title AS QuestionTitle,
        p.OwnerUserId,
        a.Id AS AnswerId,
        a.Score AS AnswerScore,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY a.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
), 
UserReputation AS (
    
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
), 
PostInsights AS (
    
    SELECT 
        ph.QuestionId,
        ph.QuestionTitle,
        ph.OwnerUserId,
        COUNT(ph.AnswerId) AS TotalAnswers,
        AVG(ph.AnswerScore) AS AverageAnswerScore,
        ur.Reputation AS UserReputation,
        ur.UpvoteCount,
        ur.DownvoteCount
    FROM 
        RecursivePostHierarchy ph
    JOIN 
        UserReputation ur ON ph.OwnerUserId = ur.UserId
    GROUP BY 
        ph.QuestionId, ph.QuestionTitle, ph.OwnerUserId, ur.Reputation, ur.UpvoteCount, ur.DownvoteCount
)

SELECT 
    pi.QuestionId,
    pi.QuestionTitle,
    pi.TotalAnswers,
    pi.AverageAnswerScore,
    CASE 
        WHEN pi.UserReputation >= 1000 THEN 'Top Contributor'
        WHEN pi.UserReputation BETWEEN 500 AND 999 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorCategory,
    pi.UpvoteCount,
    pi.DownvoteCount,
    CASE 
        WHEN pi.TotalAnswers = 0 THEN 'No Answers'
        WHEN pi.AverageAnswerScore IS NULL THEN 'Answers have no score'
        ELSE 'Answers available'
    END AS AnswerStatus
FROM 
    PostInsights pi
WHERE 
    pi.TotalAnswers > 0 
ORDER BY 
    pi.AverageAnswerScore DESC, pi.TotalAnswers DESC
LIMIT 50;
