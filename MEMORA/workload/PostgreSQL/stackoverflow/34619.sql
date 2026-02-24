WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPostsWithBadges AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        Badges b ON r.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
    WHERE 
        r.PostRank <= 3 
    GROUP BY 
        r.PostId, r.Title, r.OwnerDisplayName, r.CreationDate, r.Score, r.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        t.PostId,
        t.Title,
        t.OwnerDisplayName,
        t.Score,
        t.ViewCount,
        COALESCE(c.CloseCount, 0) AS ClosedCount,
        t.BadgeCount,
        CASE 
            WHEN t.BadgeCount > 1 THEN 'Multiple Badges'
            WHEN t.BadgeCount = 1 THEN 'Single Badge'
            ELSE 'No Badges'
        END AS BadgeStatus
    FROM 
        TopPostsWithBadges t
    LEFT JOIN 
        ClosedPosts c ON t.PostId = c.PostId
)
SELECT 
    *,
    (CASE 
        WHEN ClosedCount > 5 THEN 'Very Inactive'
        WHEN ClosedCount BETWEEN 1 AND 5 THEN 'Somewhat Inactive'
        ELSE 'Active'
     END) AS ActivityLevel
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC;