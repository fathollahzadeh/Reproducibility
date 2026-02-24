WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        PostType
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        COALESCE(uc.BadgeCount, 0) AS UserBadgeCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Posts p ON tp.PostId = p.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UsersWithBadges uc ON p.OwnerUserId = uc.UserId
    GROUP BY 
        tp.PostId, tp.Title, uc.BadgeCount
)
SELECT 
    ps.Title,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    (CASE 
        WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'More Upvotes than Downvotes'
        WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'More Downvotes than Upvotes'
        ELSE 'Equal Upvotes and Downvotes' 
    END) AS VoteBalance,
    (SELECT COUNT(*) FROM Posts pt WHERE pt.OwnerUserId = p.OwnerUserId) AS UserPostCount,
    (SELECT STRING_AGG(CONCAT(t.TagName, ' (' , t.Count, ')'), ', ') FROM Tags t WHERE p.Tags LIKE '%' || t.TagName || '%') AS AssociatedTags
FROM 
    PostStatistics ps
JOIN 
    Posts p ON ps.PostId = p.Id
ORDER BY 
    ps.UpVoteCount DESC, ps.CommentCount DESC;
