
WITH RecentQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserQuestionRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 MONTH'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
TopContributors AS (
    SELECT 
        UserId,
        Reputation,
        DisplayName,
        TotalBounty,
        RANK() OVER (ORDER BY Reputation + TotalBounty DESC) AS ContributorRank
    FROM 
        UserReputation
)
SELECT 
    q.QuestionId,
    q.Title,
    u.DisplayName AS OwnerDisplayName,
    q.CreationDate,
    q.Score,
    RANK() OVER (ORDER BY q.Score DESC) AS QuestionRank,
    COALESCE(ut.ContributorRank, 0) AS ContributorRank
FROM 
    RecentQuestions q
JOIN 
    Users u ON q.OwnerUserId = u.Id
LEFT JOIN 
    TopContributors ut ON q.OwnerUserId = ut.UserId
WHERE 
    q.UserQuestionRank = 1
ORDER BY 
    QuestionRank, ContributorRank
LIMIT 10 OFFSET 0;
