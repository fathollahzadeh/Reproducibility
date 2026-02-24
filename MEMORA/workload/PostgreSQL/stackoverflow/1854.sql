
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(NULLIF(p.LastEditDate, p.CreationDate), p.CreationDate) AS MostRecentEdit
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CommentsSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(LENGTH(c.Text)) AS AverageCommentLength
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.MostRecentEdit,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(cs.CommentCount, 0) AS TotalComments,
        COALESCE(cs.AverageCommentLength, 0) AS AvgCommentLength
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON ub.UserId = u.Id
    LEFT JOIN 
        CommentsSummary cs ON cs.PostId = rp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.UserBadgeCount,
    ps.TotalComments,
    ps.AvgCommentLength,
    CASE 
        WHEN ps.Score >= 10 THEN 'Highly Rated'
        WHEN ps.Score BETWEEN 5 AND 9 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    CASE 
        WHEN ps.MostRecentEdit = ps.CreationDate THEN 'No Edits'
        WHEN ps.MostRecentEdit IS NULL THEN 'Never Edited'
        ELSE 'Edited'
    END AS EditStatus
FROM 
    PostStats ps
WHERE 
    ps.TotalComments > 5
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC;
