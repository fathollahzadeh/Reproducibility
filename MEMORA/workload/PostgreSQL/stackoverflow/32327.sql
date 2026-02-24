
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
), 
ClosePostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    COALESCE(cpr.CloseReasons, 'No Reasons') AS CloseReasons,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount >= 5 THEN 'Gold'
        WHEN ub.BadgeCount >= 3 THEN 'Silver'
        ELSE 'Bronze'
    END AS BadgeCategory
FROM 
    TopPosts tp
LEFT JOIN 
    ClosePostReasons cpr ON tp.PostId = cpr.PostId
LEFT JOIN 
    UserBadges ub ON (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId) = ub.UserId
ORDER BY 
    tp.CommentCount DESC, tp.CreationDate DESC;
