
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        p.Score > 0
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ue.DisplayName,
        ue.CommentCount,
        ue.VoteCount,
        ue.BadgeCount,
        CASE 
            WHEN ue.VoteCount > 10 THEN 'Highly Engaged User'
            WHEN ue.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Engaged User'
            ELSE 'Low Engagement User'
        END AS EngagementCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserEngagement ue ON rp.OwnerUserId = ue.UserId
    WHERE 
        rp.RankByScore <= 5
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.DisplayName,
    fp.CommentCount,
    fp.VoteCount,
    fp.BadgeCount,
    fp.EngagementCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.BadgeCount DESC, 
    fp.CommentCount DESC;
