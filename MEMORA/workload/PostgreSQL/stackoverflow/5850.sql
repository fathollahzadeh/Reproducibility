
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    AND 
        p.ViewCount > 100
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.ViewCount > 500 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        ua.UserId, 
        ua.BadgeCount, 
        ua.HighViewCountPosts, 
        ua.VoteCount,
        RANK() OVER (ORDER BY ua.VoteCount DESC, ua.BadgeCount DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.HighViewCountPosts > 0
)
SELECT 
    rp.Title,
    rp.CreationDate AS PostCreatedDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    u.DisplayName AS AuthorDisplayName,
    ua.BadgeCount AS AuthorBadges,
    ua.HighViewCountPosts AS AuthorHighViewPosts,
    ua.VoteCount AS AuthorVoteCount,
    au.UserRank AS AuthorRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
JOIN 
    ActiveUsers au ON au.UserId = u.Id
JOIN 
    UserActivity ua ON ua.UserId = u.Id
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
