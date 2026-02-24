
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        PostCount,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        PostCount > 5
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ph.UserDisplayName, 'System') AS LastModifiedBy,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS LastActivityRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = p.Id
        )
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
FinalOutput AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        COUNT(DISTINCT pi.PostId) AS RecentPosts,
        SUM(pi.ViewCount) AS TotalViews,
        AVG(tu.Reputation) AS AvgReputation
    FROM 
        TopUsers tu
    LEFT JOIN 
        PostInfo pi ON tu.UserId = pi.OwnerUserId
    GROUP BY 
        tu.UserId, tu.DisplayName
)
SELECT 
    fo.DisplayName,
    fo.RecentPosts,
    fo.TotalViews,
    fo.AvgReputation
FROM 
    FinalOutput fo
WHERE 
    fo.RecentPosts > 2
ORDER BY 
    fo.AvgReputation DESC
LIMIT 10;
