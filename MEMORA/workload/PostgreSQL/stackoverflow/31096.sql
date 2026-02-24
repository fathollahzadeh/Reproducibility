WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankInCategory
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
CommentsCTE AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
BadgesCTE AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
OverallStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        COALESCE(cc.CommentCount, 0) AS CommentCount,
        COALESCE(cc.LastCommentDate, NULL) AS LastCommentDate,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(bc.LatestBadgeDate, NULL) AS LatestBadgeDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentsCTE cc ON rp.PostId = cc.PostId
    LEFT JOIN 
        BadgesCTE bc ON rp.Author = (SELECT DisplayName FROM Users WHERE Id = bc.UserId)
    WHERE
        rp.RankInCategory <= 5
)
SELECT 
    os.PostId,
    os.Title,
    os.Author,
    os.CreationDate,
    os.Score,
    os.CommentCount,
    os.LastCommentDate,
    os.BadgeCount,
    os.LatestBadgeDate,
    CASE 
        WHEN os.CommentCount = 0 THEN 'No Comments Yet'
        ELSE 'Has Comments'
    END AS CommentStatus,
    CASE 
        WHEN os.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    OverallStats os
ORDER BY 
    os.Score DESC;