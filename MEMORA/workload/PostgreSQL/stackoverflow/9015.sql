
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.OwnerReputation,
        rp.CommentCount,
        rp.BadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostHistoryStats AS (
    SELECT 
        pp.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        TopPosts pp
    LEFT JOIN 
        PostHistory ph ON pp.PostId = ph.PostId
    GROUP BY 
        pp.PostId
)
SELECT 
    tp.Title,
    tp.Score,
    tp.OwnerReputation,
    tp.CommentCount,
    tp.BadgeCount,
    phs.EditCount,
    phs.LastEditDate
FROM 
    TopPosts tp
JOIN 
    PostHistoryStats phs ON tp.PostId = phs.PostId
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
