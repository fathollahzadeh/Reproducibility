
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryWithReason AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        cht.Name AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cht ON CAST(ph.Comment AS INTEGER) = cht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.DisplayName AS PostOwner,
        us.BadgeCount,
        us.TotalBounties,
        phwr.UserDisplayName AS HistoryUser,
        phwr.CloseReason
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        PostHistoryWithReason phwr ON rp.PostId = phwr.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.PostOwner,
    tp.BadgeCount,
    tp.TotalBounties,
    tp.HistoryUser,
    COALESCE(tp.CloseReason, 'No Close Reason') AS CloseReason
FROM 
    TopPosts tp
ORDER BY 
    tp.TotalBounties DESC, 
    tp.BadgeCount DESC;
