WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
DetailedTopPosts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CreationDate,
        tp.ViewCount,
        tp.AnswerCount,
        tp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(pb.BadgeCount, 0) AS TotalBadges
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
    dtp.PostId,
    dtp.Title,
    dtp.Score,
    dtp.CreationDate,
    dtp.ViewCount,
    dtp.AnswerCount,
    dtp.OwnerDisplayName,
    dtp.TotalComments,
    dtp.TotalBadges
FROM 
    DetailedTopPosts dtp
ORDER BY 
    dtp.Score DESC, dtp.ViewCount DESC;