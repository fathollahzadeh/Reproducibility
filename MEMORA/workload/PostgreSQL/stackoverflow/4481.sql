
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostWithUserInteractions AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.CommentCount,
        COALESCE(ui.UpVotes, 0) AS TotalUpVotes,
        COALESCE(ui.DownVotes, 0) AS TotalDownVotes,
        COALESCE(ui.BadgeCount, 0) AS TotalBadges
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserInteractions ui ON tp.PostId = ui.UserId
)
SELECT 
    pwi.PostId,
    pwi.Title,
    pwi.CreationDate,
    pwi.ViewCount,
    pwi.Score,
    pwi.CommentCount,
    pwi.TotalUpVotes,
    pwi.TotalDownVotes,
    pwi.TotalBadges
FROM 
    PostWithUserInteractions pwi
ORDER BY 
    pwi.Score DESC, pwi.ViewCount DESC
LIMIT 
    20;
