
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(u.UpVotes, 0) - COALESCE(u.DownVotes, 0) AS NetVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.UserId
),
UserWithClosedPosts AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.Questions,
        us.Answers,
        us.AvgScore,
        COALESCE(cp.ClosedCount, 0) AS ClosedPostCount,
        us.ReputationRank,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM 
        UserStats us
    LEFT JOIN 
        ClosedPosts cp ON us.UserId = cp.UserId
)
SELECT 
    uwcp.DisplayName,
    uwcp.Reputation,
    uwcp.TotalPosts,
    uwcp.Questions,
    uwcp.Answers,
    uwcp.AvgScore,
    uwcp.ClosedPostCount,
    CASE 
        WHEN uwcp.ClosedPostCount > 10 THEN 'Active Closer'
        WHEN uwcp.ClosedPostCount BETWEEN 1 AND 10 THEN 'Occasional Closer'
        ELSE 'No Closes'
    END AS ClosingStatus
FROM 
    UserWithClosedPosts uwcp
WHERE 
    uwcp.TotalPosts > 5
ORDER BY 
    uwcp.Reputation DESC, 
    uwcp.ClosedPostCount DESC
LIMIT 20;
