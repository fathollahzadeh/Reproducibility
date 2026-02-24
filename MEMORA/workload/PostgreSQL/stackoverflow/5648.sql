WITH RankedPosts AS (
    SELECT 
        p.Id as PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName as OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) as Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostID) as CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostID AND v.VoteTypeId = 2) as UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostID AND v.VoteTypeId = 3) as DownVoteCount,
    (SELECT STRING_AGG(DISTINCT pt.Name, ', ') FROM PostTypes pt JOIN Posts p ON p.PostTypeId = pt.Id WHERE p.Id = tp.PostID) as PostType
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;