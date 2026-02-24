WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS CloseComments,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.*, 
        us.Reputation, 
        us.TotalPosts, 
        us.TotalBadges,
        COALESCE(cph.CloseCount, 0) AS CloseEvents
    FROM 
        RankedPosts rp
    JOIN 
        UserScores us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        ClosedPostHistory cph ON rp.PostId = cph.PostId
    WHERE 
        rp.PostRank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Reputation,
    tp.TotalPosts,
    tp.TotalBadges,
    tp.CloseEvents,
    CASE 
        WHEN tp.CloseEvents > 0 THEN 'Post has been closed'
        ELSE 'Active post'
    END AS PostStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 20;