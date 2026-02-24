
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8  
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        us.DisplayName AS OwnerName,
        us.Reputation AS OwnerReputation,
        us.TotalBounties,
        us.BadgeCount,
        COALESCE(ch.CloseReason, 'Not Closed') AS CloseStatus,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top' 
            ELSE 'Others' 
        END AS PostRankCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        ClosedPostHistory ch ON rp.PostId = ch.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.CreationDate,
    pm.OwnerName,
    pm.OwnerReputation,
    pm.TotalBounties,
    pm.BadgeCount,
    pm.CloseStatus,
    pm.PostRankCategory
FROM 
    PostMetrics pm
WHERE 
    pm.Score > 0
    AND pm.OwnerReputation > 100  
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
