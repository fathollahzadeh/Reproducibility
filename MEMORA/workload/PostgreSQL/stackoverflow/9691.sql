
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS ScoreRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges bh ON p.OwnerUserId = bh.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.UpVotes, 
        rp.DownVotes, 
        rp.CommentCount, 
        rp.BadgeCount,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.UpVotes, 
    tp.DownVotes, 
    tp.CommentCount, 
    tp.BadgeCount, 
    u.DisplayName AS OwnerDisplayName
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.UpVotes DESC, tp.CreationDate DESC;
