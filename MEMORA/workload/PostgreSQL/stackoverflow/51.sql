
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        AcceptedAnswers,
        AvgReputation,
        RANK() OVER (ORDER BY AvgReputation DESC) AS ReputationRank
    FROM 
        UserPostStats
), ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.PostCount,
    ru.AnswerCount,
    ru.AcceptedAnswers,
    ru.AvgReputation,
    cp.CloseCount,
    CASE 
        WHEN cp.CloseCount IS NULL THEN 'No closures'
        ELSE CONCAT('Closed ', cp.CloseCount, ' times')
    END AS ClosureInfo
FROM 
    RankedUsers ru
LEFT JOIN 
    ClosedPosts cp ON ru.UserId = cp.OwnerUserId
WHERE 
    ru.ReputationRank <= 10 
    AND (ru.PostCount > 5 OR ru.AvgReputation > 1000)
ORDER BY 
    ru.ReputationRank, ru.DisplayName;
