
WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'BountyStart' THEN v.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
), 
PostsInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) - SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS Score,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ui.UserId,
    u.DisplayName,
    ui.UpVotes,
    ui.DownVotes,
    ui.TotalBounty,
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.CommentCount,
    pi.Score,
    ub.BadgeCount
FROM 
    UserVotes ui
JOIN 
    Users u ON ui.UserId = u.Id
JOIN 
    PostsInfo pi ON pi.Score > 0
JOIN 
    UserBadges ub ON ub.UserId = ui.UserId
ORDER BY 
    ui.UpVotes DESC, 
    pi.CommentCount DESC, 
    ub.BadgeCount DESC
LIMIT 100;
