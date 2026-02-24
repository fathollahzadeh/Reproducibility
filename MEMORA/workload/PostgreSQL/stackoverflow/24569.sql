WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), 
PostReputationAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId AS CloserUserId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
        AND ph.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerStatus
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '6 months')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
), 
TopUsersWithClosedPosts AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(cp.PostId) AS ClosedPostCount
    FROM 
        Users u
        JOIN ClosedPosts cp ON u.Id = cp.CloserUserId
    GROUP BY 
        u.DisplayName, u.Reputation
    HAVING 
        COUNT(cp.PostId) > 0
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    pda.PostCount,
    pda.TotalScore,
    pda.AvgViewCount,
    pd.Title,
    pd.CommentCount,
    pd.CreationDate AS PostCreationDate,
    pd.AcceptedAnswerStatus,
    ucp.ClosedPostCount,
    CASE 
        WHEN pd.AcceptedAnswerStatus = -1 THEN 'Not Accepted'
        ELSE 'Accepted'
    END AS AnswerStatus
FROM 
    UserReputation ur
    JOIN PostReputationAggregates pda ON ur.UserId = pda.OwnerUserId
    JOIN PostDetails pd ON pd.PostId IN (
        SELECT PostId FROM Posts 
        WHERE OwnerUserId = ur.UserId AND Score > 0
    )
    LEFT JOIN TopUsersWithClosedPosts ucp ON ur.DisplayName = ucp.DisplayName
WHERE 
    ur.Reputation > 500 
    AND pd.CreationDate > '2023-01-01'
ORDER BY 
    ur.Reputation DESC, 
    pd.Score DESC 
LIMIT 100;