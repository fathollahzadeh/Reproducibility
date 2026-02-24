
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        Rank, 
        CommentCount, 
        Upvotes, 
        Downvotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass  
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    COALESCE(SUM(phd.EditCount), 0) AS TotalEdits,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetails phd ON tp.PostId = phd.PostId
LEFT JOIN 
    Users u ON u.Id IS NULL OR (u.Id = tp.PostId AND tp.PostId NOT IN (SELECT DISTINCT OwnerUserId FROM Posts))
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, 
    tp.Upvotes, tp.Downvotes, ub.BadgeCount, ub.HighestBadgeClass
ORDER BY 
    tp.CreationDate DESC;
