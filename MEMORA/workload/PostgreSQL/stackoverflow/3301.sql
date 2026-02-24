
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReasonName
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.UpvoteCount,
    up.DownvoteCount,
    up.BadgeCount,
    rp.Title AS TopPostTitle,
    rp.CreationDate AS TopPostDate,
    cp.ClosedDate,
    cp.CloseReasonName
FROM 
    UserStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.UserRank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    up.UpvoteCount - up.DownvoteCount > 10
ORDER BY 
    up.BadgeCount DESC, up.DisplayName ASC
LIMIT 50;
