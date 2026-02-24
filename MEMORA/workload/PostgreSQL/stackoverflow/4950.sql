
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(COUNT(b.Id), 0) AS BadgeCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalCloseVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS TotalReopenVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopQuestions AS (
    SELECT 
        rp.Title,
        rp.CreationDate,
        us.DisplayName,
        us.TotalBounties,
        us.BadgeCount,
        us.TotalCloseVotes,
        us.TotalReopenVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.Rank = 1
    ORDER BY 
        rp.Score DESC
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.DisplayName,
    tq.TotalBounties,
    tq.BadgeCount,
    tq.TotalCloseVotes,
    tq.TotalReopenVotes
FROM 
    TopQuestions tq
WHERE 
    tq.TotalBounties > 0 
UNION ALL 
SELECT 
    'No Bounties' AS Title, 
    TIMESTAMP '2024-10-01 12:34:56' AS CreationDate, 
    us.DisplayName, 
    0 AS TotalBounties, 
    us.BadgeCount, 
    us.TotalCloseVotes, 
    us.TotalReopenVotes
FROM 
    UserStats us
WHERE 
    us.TotalBounties = 0
ORDER BY 
    TotalBounties DESC, BadgeCount DESC;
