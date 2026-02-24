
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
),

PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON rp.OwnerUserId = b.UserId
    JOIN Users u ON u.Id = rp.OwnerUserId
),

CommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveCommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '60 days'
    GROUP BY 
        p.Id
),

Final AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.CreationDate,
        pwb.OwnerDisplayName,
        pwb.BadgeCount,
        cs.CommentCount,
        cs.PositiveCommentCount,
        CASE 
            WHEN cs.CommentCount IS NULL THEN 'No Comments'
            WHEN cs.PositiveCommentCount * 1.0 / cs.CommentCount < 0.5 THEN 'Mostly Negative'
            ELSE 'Mixed or Positive'
        END AS CommentSentiment,
        COALESCE(SUBSTRING(pw.Body FROM 1 FOR 200), 'No body content available.') AS ShortBody
    FROM 
        PostWithBadges pwb
    LEFT JOIN 
        CommentStats cs ON pwb.PostId = cs.PostId
    LEFT JOIN 
        Posts pw ON pw.Id = pwb.PostId
    WHERE 
        pwb.BadgeCount > 0 AND
        pw.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    ORDER BY 
        pwb.BadgeCount DESC,
        pwb.CreationDate ASC
)

SELECT 
    *,
    CASE 
        WHEN OwnerDisplayName IS NULL THEN 'Anonymous'
        ELSE OwnerDisplayName 
    END AS DisplayName
FROM 
    Final
WHERE 
    CommentSentiment NOT IN ('No Comments')
ORDER BY 
    CommentCount DESC, CreationDate ASC;
