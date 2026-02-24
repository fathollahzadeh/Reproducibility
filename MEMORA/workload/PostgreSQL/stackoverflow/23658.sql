
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViewCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAnswered
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

BadgesSummary AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.RankViewCount,
    Bs.BadgeCount,
    Bs.HighestBadgeClass,
    phs.HistoryTypes,
    phs.LastChangeDate,
    rp.CommentCount,
    rp.IsAnswered,
    CASE 
        WHEN rp.CommentCount > 5 THEN 'Highly Discussed'
        WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Discussed'
        ELSE 'No Comments'
    END AS DiscussionLevel,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views Recorded'
        ELSE CONCAT('Views: ', rp.ViewCount)
    END AS ViewInfo
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgesSummary Bs ON Bs.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = rp.PostId
WHERE 
    rp.RankViewCount <= 10
ORDER BY 
    rp.RankViewCount, rp.ViewCount DESC;
