WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.CreationDate,
        tp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(pb.BadgeCount, 0) AS OwnerBadges
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
    LEFT JOIN 
        Users u ON tp.OwnerDisplayName = u.DisplayName
    LEFT JOIN 
        PostBadges pb ON u.Id = pb.UserId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.ViewCount,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.TotalComments,
    fr.OwnerBadges
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;