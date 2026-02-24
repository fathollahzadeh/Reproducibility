WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopContributors AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        pc.PostCount,
        pc.QuestionCount,
        pc.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY pc.PostCount DESC) AS ContributorRank
    FROM 
        UserReputation ur
    JOIN 
        PostCounts pc ON ur.UserId = pc.OwnerUserId
    WHERE 
        ur.Reputation > 5000 
)
SELECT 
    tc.DisplayName,
    tc.Reputation,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.UserId = tc.UserId AND v.VoteTypeId = 2) AS TotalUpvotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.UserId = tc.UserId AND v.VoteTypeId = 3) AS TotalDownvotes,
    CASE 
        WHEN tc.QuestionCount > 0 THEN 
            (SELECT AVG(Score) 
             FROM Posts p 
             WHERE p.OwnerUserId = tc.UserId AND p.PostTypeId = 1) 
        ELSE NULL 
    END AS AvgQuestionScore
FROM 
    TopContributors tc
WHERE 
    tc.ContributorRank <= 10 
ORDER BY 
    tc.ContributorRank;