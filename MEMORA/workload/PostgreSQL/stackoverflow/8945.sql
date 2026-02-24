
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankOrder,
        p.PostTypeId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.CreationDate < '2024-01-01'
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        pt.Name AS PostTypeName
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.RankOrder <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostWithUserStats AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        us.UserID,
        us.DisplayName,
        us.UpVotes,
        us.DownVotes,
        us.BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Posts p ON tp.PostID = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserStats us ON u.Id = us.UserID
)
SELECT 
    pwus.PostID,
    pwus.Title,
    pwus.Score,
    pwus.ViewCount,
    pwus.AnswerCount,
    pwus.CommentCount,
    pwus.DisplayName,
    pwus.UpVotes,
    pwus.DownVotes,
    pwus.BadgeCount,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    PostWithUserStats pwus
LEFT JOIN 
    Comments c ON pwus.PostID = c.PostId
GROUP BY 
    pwus.PostID, pwus.Title, pwus.Score, pwus.ViewCount, pwus.AnswerCount, 
    pwus.CommentCount, pwus.DisplayName, pwus.UpVotes, pwus.DownVotes, pwus.BadgeCount
ORDER BY 
    pwus.Score DESC, pwus.ViewCount DESC;
