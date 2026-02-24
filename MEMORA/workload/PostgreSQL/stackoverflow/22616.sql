WITH PostScores AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        (COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0)) AS NetScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0)) DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.CreationDate
),
BadgeTypes AS (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
RecentPosts AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS rn
    FROM PostHistory
    WHERE PostHistoryTypeId IN (10, 11, 12)  
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.NetScore,
    ps.CommentCount,
    ps.BadgeCount,
    bt.GoldBadges,
    bt.SilverBadges,
    bt.BronzeBadges,
    rp.CreationDate AS LastActionDate,
    CASE 
        WHEN rp.PostHistoryTypeId = 10 THEN 'Closed' 
        WHEN rp.PostHistoryTypeId = 11 THEN 'Reopened' 
        WHEN rp.PostHistoryTypeId = 12 THEN 'Deleted' 
        ELSE 'No Action' 
    END AS LastAction,
    CASE 
        WHEN ps.NetScore > 0 THEN '> 0' 
        WHEN ps.NetScore < 0 THEN '< 0' 
        ELSE '= 0' 
    END AS ScoreStatus
FROM 
    PostScores ps
LEFT JOIN 
    BadgeTypes bt ON ps.PostId = bt.UserId
LEFT JOIN 
    RecentPosts rp ON ps.PostId = rp.PostId AND rp.rn = 1
WHERE 
    ps.Rank <= 10
ORDER BY 
    ps.NetScore DESC, ps.CommentCount DESC;