
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),

BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS MostRecentBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    GROUP BY 
        b.UserId
),

CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),

ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  
)

SELECT 
    rp.Title AS PostTitle,
    rp.ViewCount AS TotalViews,
    rp.CreationDate AS PostCreationDate,
    COALESCE(bs.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    cp.ClosedBy AS ClosedBy,
    cp.ClosedDate AS ClosedDate,
    cp.CloseReason AS ClosureReason
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgeStats bs ON rp.Id = (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.AcceptedAnswerId)
LEFT JOIN 
    CommentStats cs ON rp.Id = cs.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
WHERE 
    rp.rank <= 10  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;
