
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserId AS LastEditorId,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
),
RecentClosedPosts AS (
    SELECT 
        cp.*, 
        us.DisplayName AS LastEditorName,
        us.Reputation AS LastEditorReputation
    FROM 
        ClosedPosts cp
    JOIN 
        Users us ON us.Id = cp.LastEditorId
    WHERE 
        cp.LastEditDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        UserId,
        SUM(CASE WHEN PostCount > 0 THEN 1 ELSE 0 END) AS ActivePostsCount,
        MAX(Reputation) AS MaxReputation
    FROM 
        UserStats
    GROUP BY 
        UserId
    HAVING 
        COUNT(*) > 1
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.TotalBounties,
        rcp.Title AS RecentClosedPost,
        rcp.LastEditorName,
        rcp.LastEditorReputation
    FROM 
        UserStats us
    LEFT JOIN 
        RecentClosedPosts rcp ON us.UserId = rcp.LastEditorId
    JOIN 
        TopUsers t ON us.UserId = t.UserId
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.Reputation,
    fs.PostCount,
    fs.TotalBounties,
    fs.RecentClosedPost,
    COALESCE(fs.LastEditorName, 'N/A') AS LastEditorName,
    COALESCE(fs.LastEditorReputation, 0) AS LastEditorReputation
FROM 
    FinalStats fs
ORDER BY 
    fs.Reputation DESC, 
    fs.PostCount DESC
FETCH FIRST 10 ROWS ONLY;
