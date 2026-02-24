
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RecentActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
ClosedPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        PostLinks pl
    JOIN 
        Posts p ON p.Id = pl.PostId
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        pl.PostId
),
FinalPostSummary AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.ViewCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ps.TotalBadgeClass,
        COALESCE(cpl.RelatedPostsCount, 0) AS ClosedRelatedPostCount,
        CASE 
            WHEN ps.RecentActivityRank = 1 THEN 'Recent Activity'
            ELSE 'No Recent Activity' 
        END AS ActivityStatus
    FROM 
        PostSummary ps
    LEFT JOIN 
        ClosedPostLinks cpl ON ps.PostId = cpl.PostId
)
SELECT 
    *,
    CASE 
        WHEN ClosedRelatedPostCount > 0 THEN 'Has Closed Links'
        ELSE 'No Closed Links' 
    END AS LinkStatus
FROM 
    FinalPostSummary
WHERE 
    TotalBadgeClass > 5
ORDER BY 
    ViewCount DESC, CreationDate ASC
LIMIT 10;
