
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPostsByUser
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopPostsWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        ra.CommentCount,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON ra.UserId = rp.OwnerUserId
    WHERE 
        rp.RankByScore <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    COALESCE(ra.DisplayName, 'Anonymous') AS OwnerDisplayName,
    tp.CommentCount,
    CASE 
        WHEN tp.Score > 10 THEN 'High Score'
        WHEN tp.Score BETWEEN 5 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPostsWithComments tp
LEFT OUTER JOIN 
    RecentActivity ra ON tp.OwnerUserId = ra.UserId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
