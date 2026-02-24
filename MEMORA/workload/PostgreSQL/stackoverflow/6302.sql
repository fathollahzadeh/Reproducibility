
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        (SELECT COUNT(DISTINCT ph.PostHistoryTypeId) 
         FROM PostHistory ph 
         WHERE ph.PostId = p.Id AND ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year') AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.HistoryCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    ub.BadgeCount
FROM 
    TopPosts tp
JOIN 
    UserBadges ub ON tp.PostId = ub.BadgeCount
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
