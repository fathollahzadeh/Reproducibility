WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND (p.Score > 0 OR p.ViewCount > 10)
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ChangeDate,
        STRING_AGG(ph.Comment, '; ') AS Comments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate BETWEEN cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months' AND cast('2024-10-01 12:34:56' as timestamp)
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(UPV.Score), 0) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        (SELECT p.OwnerUserId, SUM(p.Score) AS Score 
         FROM Posts p 
         GROUP BY p.OwnerUserId) AS UPV ON u.Id = UPV.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.DisplayName,
    up.TotalBounties,
    up.TotalUpvotes,
    r.Title AS LatestPostTitle,
    r.CreationDate AS LatestPostDate,
    b.BadgeList,
    COALESCE(c.CloseReason, 'Not Closed') AS ClosureInfo,
    CASE 
        WHEN COUNT(DISTINCT r.PostId) > 0 THEN 'Active Poster'
        ELSE 'Lurker'
    END AS UserStatus
FROM 
    UserStats up
LEFT JOIN 
    RankedPosts r ON up.UserId = r.OwnerUserId AND r.rn = 1
LEFT JOIN 
    UserBadges b ON up.UserId = b.UserId
LEFT JOIN 
    ClosedPosts c ON r.PostId = c.ClosedPostId
GROUP BY 
    up.DisplayName, up.TotalBounties, up.TotalUpvotes, r.Title, r.CreationDate, b.BadgeList, c.CloseReason
ORDER BY 
    up.TotalBounties DESC, up.TotalUpvotes DESC;