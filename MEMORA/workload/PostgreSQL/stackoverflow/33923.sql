
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
RelatedPosts AS (
    SELECT 
        pl.PostId,
        p2.Title AS RelatedPostTitle,
        p2.Score AS RelatedPostScore,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    JOIN 
        Posts p1 ON pl.PostId = p1.Id
    JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE 
        p1.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(ph.PostHistoryTypeId::text || ': ' || ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerName,
    phd.LastEditDate,
    phd.EditComments,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    rp.RelatedPostTitle,
    rp.RelatedPostScore,
    rp.LinkType
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    PostHistoryDetails phd ON tp.PostId = phd.PostId
LEFT JOIN 
    RelatedPosts rp ON tp.PostId = rp.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
