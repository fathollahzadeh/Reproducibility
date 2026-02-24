WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE((
            SELECT 
                SUM(v.BountyAmount) 
            FROM 
                Votes v 
            WHERE 
                v.PostId = p.Id 
                AND v.VoteTypeId IN (8, 9) 
        ), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
ClosedPosts AS (
    SELECT 
        p.Id, 
        ph.Comment AS CloseReason,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
), 
PostLinkCounts AS (
    SELECT 
        pl.PostId, 
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.TotalBounty,
    ub.BadgeNames,
    COALESCE(c.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(c.ClosedDate::date, NULL) AS ClosedDate,
    plc.RelatedPostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    ClosedPosts c ON c.Id = rp.PostId
LEFT JOIN 
    PostLinkCounts plc ON plc.PostId = rp.PostId
WHERE 
    rp.PostRank <= 5 
    AND (rp.TotalBounty > 0 OR c.ClosedDate IS NOT NULL)
ORDER BY 
    rp.Score DESC, rp.TotalBounty DESC;