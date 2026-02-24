
WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.TotalBounty,
        us.TotalUpVotes,
        us.TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.Reputation > 0
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    us.Reputation,
    us.BadgeCount,
    us.TotalBounty,
    ph.LastEditDate,
    ph.EditCount,
    ph.CloseOpenCount
FROM 
    RecursivePostStats p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
JOIN 
    PostHistoryAggregates ph ON p.PostId = ph.PostId
WHERE 
    us.Reputation > 100 
    AND p.RowNum = 1 
ORDER BY 
    us.Reputation DESC, p.CreationDate ASC
LIMIT 50 OFFSET 0;
