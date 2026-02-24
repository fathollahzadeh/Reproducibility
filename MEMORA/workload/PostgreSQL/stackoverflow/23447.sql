
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        AVG(b.Class) AS AvgBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.TagsArray,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.AvgBadgeClass,
        COALESCE(v.TotalVotes, 0) AS TotalVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON v.PostId = rp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.TagsArray,
    ps.BadgeCount,
    CASE 
        WHEN ps.GoldBadges > 0 THEN 'Gold Badge Holder'
        WHEN ps.BadgeCount > 5 THEN 'Experienced User'
        ELSE 'New User'
    END AS UserStatus,
    ps.TotalVotes,
    CASE 
        WHEN ps.TotalVotes > 10 THEN 'Highly Voted'
        ELSE 'Less Voted'
    END AS VoteStatus,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT SUM(COALESCE(pv.BountyAmount, 0)) FROM Votes pv WHERE pv.PostId = ps.PostId AND pv.VoteTypeId = 8) AS TotalBounty
FROM 
    PostStatistics ps
WHERE 
    ps.Score > 0 
    AND (ps.BadgeCount IS NULL OR ps.BadgeCount > 2)
ORDER BY 
    ps.Score DESC,
    ps.CreationDate DESC
LIMIT 5 OFFSET 2;
