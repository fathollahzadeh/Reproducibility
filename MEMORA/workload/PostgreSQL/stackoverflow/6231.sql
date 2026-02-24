
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeleteVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.CommentCount, 
        ps.UpVoteCount, 
        ps.DownVoteCount, 
        ua.DisplayName,
        ua.TotalPosts
    FROM 
        PostStats ps
    JOIN 
        UserActivity ua ON ps.UpVoteCount >= 10 AND ua.TotalPosts > 0
    ORDER BY 
        ps.UpVoteCount DESC, ps.CommentCount DESC
    LIMIT 10
)
SELECT 
    p.Title,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    u.DisplayName,
    u.TotalPosts
FROM 
    TopPosts p
JOIN 
    UserActivity u ON p.DisplayName = u.DisplayName
ORDER BY 
    p.UpVoteCount DESC;
