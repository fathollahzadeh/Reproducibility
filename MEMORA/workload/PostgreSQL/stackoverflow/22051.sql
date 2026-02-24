
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(CHAR_LENGTH(c.Text)) AS AvgCommentLength,
        MAX(ps.CreationDate) AS LastPostUpdate
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    JOIN 
        (SELECT 
            PostId,
            MAX(CreationDate) AS CreationDate
         FROM 
            PostHistory
         WHERE 
            PostHistoryTypeId IN (10, 11, 12, 13)
         GROUP BY 
            PostId) ps ON p.Id = ps.PostId
    WHERE
        p.CreationDate > DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        hp.CreationDate AS ClosedDate,
        CASE 
            WHEN hp.Comment IS NULL THEN 'Closed Without Reason'
            ELSE hp.Comment
        END AS CloseReason
    FROM 
        Posts p
    INNER JOIN 
        PostHistory hp ON p.Id = hp.PostId
    WHERE 
        hp.PostHistoryTypeId = 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.AvgCommentLength,
    ps.LastPostUpdate,
    cp.ClosedDate,
    cp.CloseReason,
    ub.UserId,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN ps.VoteCount > 100 THEN 'Popular Post'
        WHEN ps.VoteCount BETWEEN 50 AND 100 THEN 'Moderately Popular Post'
        ELSE 'Less Popular Post'
    END AS PopularityCategory
FROM 
    PostStats ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
LEFT JOIN 
    UserBadges ub ON ps.PostId IN (SELECT UserId FROM Posts WHERE OwnerUserId = ub.UserId)
ORDER BY 
    ps.LastPostUpdate DESC, ps.VoteCount DESC
LIMIT 100;
