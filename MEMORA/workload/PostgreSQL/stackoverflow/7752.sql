WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
), 
PostVoteDetails AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rv.UpVotes,
        rv.DownVotes,
        rv.TotalVotes,
        RANK() OVER (ORDER BY rp.Score DESC, rv.UpVotes DESC) AS PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteDetails rv ON rp.PostID = rv.PostId
)
SELECT 
    tp.PostID,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.TotalVotes,
    tp.PostRank,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(b.BadgeCount, 0) AS TotalBadges
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON tp.PostID = c.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) b ON tp.PostID = b.UserId
WHERE 
    tp.PostRank <= 10
ORDER BY 
    tp.Score DESC, tp.UpVotes DESC;