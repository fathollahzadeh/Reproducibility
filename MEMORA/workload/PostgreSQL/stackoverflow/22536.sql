
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        COALESCE(UPVotes - DownVotes, 0) AS NetVotes
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId, 
        p.PostTypeId, 
        p.CreationDate, 
        p.Title, 
        p.Score, 
        COALESCE(ph.Text, 'No history available') AS PostHistory,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRowNumber
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (1, 4, 10)
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
),
TopUsers AS (
    SELECT 
        OwnerUserId AS UserId,
        COUNT(PostId) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM RecentPosts
    GROUP BY OwnerUserId
    HAVING COUNT(PostId) > 5
),
CombinedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        ur.ReputationRank,
        COALESCE(tu.PostCount, 0) AS TotalPosts,
        COALESCE(tu.QuestionCount, 0) AS TotalQuestions,
        COALESCE(tu.AnswerCount, 0) AS TotalAnswers
    FROM Users u
    LEFT JOIN UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN TopUsers tu ON u.Id = tu.UserId
    WHERE u.Reputation > 1000 
)
SELECT 
    cd.UserId,
    cd.DisplayName,
    cd.Reputation,
    cd.ReputationRank,
    cd.TotalPosts,
    cd.TotalQuestions,
    cd.TotalAnswers,
    CASE 
        WHEN cd.Reputation > 20000 THEN 'Legend'
        WHEN cd.Reputation BETWEEN 10000 AND 20000 THEN 'Expert'
        WHEN cd.Reputation BETWEEN 5000 AND 10000 THEN 'Veteran'
        ELSE 'Newbie'
    END AS UserLevel,
    STRING_AGG(DISTINCT p.Tags, ', ' ORDER BY p.Tags) AS PopularTags
FROM CombinedData cd
LEFT JOIN Posts p ON p.OwnerUserId = cd.UserId
GROUP BY 
    cd.UserId,
    cd.DisplayName,
    cd.Reputation,
    cd.ReputationRank,
    cd.TotalPosts,
    cd.TotalQuestions,
    cd.TotalAnswers
ORDER BY cd.Reputation DESC
LIMIT 100;
