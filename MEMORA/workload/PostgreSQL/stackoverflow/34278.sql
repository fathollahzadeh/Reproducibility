
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason,
        COUNT(ph.Id) AS CloseCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    GROUP BY 
        p.Id, ph.Comment
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS TotalLinks,
        STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypes
    FROM 
        PostLinks pl 
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalBounty,
    ua.TotalPosts,
    ua.TotalBadges,
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Tags,
    rp.CommentCount,
    cpr.CloseReason,
    cpr.CloseCount,
    pls.TotalLinks,
    pls.LinkTypes
FROM 
    UserActivity ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPostReasons cpr ON rp.Id = cpr.PostId
LEFT JOIN 
    PostLinksSummary pls ON rp.Id = pls.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    ua.TotalBounty DESC, 
    rp.Score DESC;
