WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopAnsweredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
        AND rp.AnswerCount > 0
),
TopPostsWithComments AS (
    SELECT 
        tap.PostId,
        tap.Title,
        tap.CreationDate,
        tap.Score,
        tap.ViewCount,
        tap.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopAnsweredPosts tap
    LEFT JOIN 
        Comments c ON tap.PostId = c.PostId
    GROUP BY 
        tap.PostId, tap.Title, tap.CreationDate, tap.Score, tap.ViewCount, tap.OwnerDisplayName
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.CreationDate
FROM 
    TopPostsWithComments t
ORDER BY 
    t.Score DESC, t.ViewCount DESC, t.CommentCount DESC
LIMIT 20;