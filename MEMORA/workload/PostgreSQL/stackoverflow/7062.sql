WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND 
        p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Owner
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
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
    WHERE 
        b.Class = 1 OR b.Class = 2
    GROUP BY 
        b.UserId
),
FinalMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        pb.BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
    LEFT JOIN 
        PostBadges pb ON tp.Owner = (SELECT DisplayName FROM Users WHERE Id = pb.UserId)
)
SELECT 
    fm.PostId,
    fm.Title,
    fm.CreationDate,
    fm.Score,
    fm.ViewCount,
    fm.AnswerCount,
    fm.CommentCount,
    fm.BadgeCount
FROM 
    FinalMetrics fm
ORDER BY 
    fm.Score DESC, fm.ViewCount DESC;