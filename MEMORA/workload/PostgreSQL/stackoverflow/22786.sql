
WITH RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS rn
    FROM 
        Badges b
    WHERE 
        b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostScoreData AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days') 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN ps.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        AVG(ps.Score) AS AvgScore,
        MAX(ps.LastCommentDate) AS LastPostCommentDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostScoreData ps ON p.Id = ps.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        rb.UserId,
        STRING_AGG(rb.BadgeName, ', ') AS Badges
    FROM 
        RecentBadges rb
    WHERE 
        rb.rn <= 3
    GROUP BY 
        rb.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ups.PostCount,
    COALESCE(ubs.Badges, 'No Badges') AS Badges,
    COALESCE(ups.AvgScore, 0) AS AvgPostScore,
    ups.PositivePostCount,
    ups.LastPostCommentDate,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
LEFT JOIN 
    UserBadges ubs ON u.Id = ubs.UserId
LEFT JOIN 
    PostScoreData ps ON u.Id = ps.OwnerUserId
WHERE 
    (ups.PostCount > 5 OR u.Reputation > 5000)
    AND (ps.UpVotes IS NULL OR ps.UpVotes > 5)
ORDER BY 
    u.Reputation DESC,
    ups.PostCount DESC,
    COALESCE(ups.AvgScore, 0) DESC
LIMIT 50;
