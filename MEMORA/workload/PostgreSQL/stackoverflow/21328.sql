WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        r.ReputationLevel,
        r.Reputation
    FROM 
        Users u
    JOIN 
        UserReputation r ON u.Id = r.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 week'
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        a.UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(ph.CloseCount, 0)) AS TotalClosedPosts,
        SUM(COALESCE(ph.ReopenCount, 0)) AS TotalReopenedPosts,
        SUM(COALESCE(ph.DeleteCount, 0)) AS TotalDeletedPosts,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes
    FROM 
        ActiveUsers a
    LEFT JOIN 
        Posts p ON a.UserId = p.OwnerUserId
    LEFT JOIN 
        PostHistoryAggregates ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT 
            v.PostId,
            COUNT(v.Id) AS VoteCount
        FROM 
            Votes v
        GROUP BY 
            v.PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        a.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.ReputationLevel,
    u.Reputation,
    COALESCE(t.PostCount, 0) AS TotalPosts,
    COALESCE(t.TotalClosedPosts, 0) AS TotalClosed,
    COALESCE(t.TotalReopenedPosts, 0) AS TotalReopened,
    COALESCE(t.TotalDeletedPosts, 0) AS TotalDeleted,
    (COALESCE(t.TotalClosedPosts, 0) * 1.0 / NULLIF(COALESCE(t.PostCount, 0), 0)) * 100 AS CloseRate,
    (COALESCE(t.TotalReopenedPosts, 0) * 1.0 / NULLIF(COALESCE(t.PostCount, 0), 0)) * 100 AS ReopenRate,
    (COALESCE(t.TotalDeletedPosts, 0) * 1.0 / NULLIF(COALESCE(t.PostCount, 0), 0)) * 100 AS DeleteRate
FROM 
    ActiveUsers u
LEFT JOIN 
    TopUsers t ON u.UserId = t.UserId
WHERE 
    u.Reputation >= 500
ORDER BY 
    CloseRate DESC, ReopenRate DESC, DeleteRate DESC;