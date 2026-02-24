
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        AVG(COALESCE(b.Class, 3)) AS AverageBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.TotalBounty,
        us.Upvotes - us.Downvotes AS VoteBalance,
        RANK() OVER (ORDER BY us.PostCount DESC, us.Upvotes - us.Downvotes DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.PostCount > 0
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.PostCount,
    tp.TotalBounty,
    tp.VoteBalance,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    cp.FirstCloseDate
FROM 
    TopUsers tp
LEFT JOIN 
    RankedPosts rp ON tp.PostCount = rp.Rank
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    tp.UserRank <= 10  
ORDER BY 
    tp.VoteBalance DESC, tp.PostCount DESC;
