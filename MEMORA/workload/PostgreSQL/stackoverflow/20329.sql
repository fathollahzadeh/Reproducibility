
WITH CTE_PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(MAX(v.CreationDate), p.CreationDate) AS LastVoteDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.LastVoteDate
    FROM 
        CTE_PostStats ps
    WHERE 
        ps.CommentCount > 5
        OR ps.UpVoteCount - ps.DownVoteCount > 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class AS BadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Name, b.Class
)
SELECT 
    u.DisplayName,
    fp.Title,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    ub.BadgeName,
    ub.BadgeClass,
    ub.BadgeCount,
    CASE 
        WHEN fp.LastVoteDate IS NULL THEN 'No votes yet' 
        WHEN fp.LastVoteDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 'Old Vote Activity'
        ELSE 'Recent Vote Activity'
    END AS VoteActivityStatus,
    STRING_AGG(DISTINCT tg.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
    JOIN Users u ON fp.PostId = u.Id
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(p.Tags, ',')) AS TagName
        FROM Posts p
        WHERE p.Id = fp.PostId
    ) tg ON TRUE
GROUP BY 
    u.DisplayName, fp.Title, fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount, ub.BadgeName, ub.BadgeClass, ub.BadgeCount, fp.LastVoteDate
HAVING 
    COUNT(DISTINCT tg.TagName) BETWEEN 1 AND 5
ORDER BY 
    fp.LastVoteDate DESC NULLS LAST, 
    u.DisplayName;
