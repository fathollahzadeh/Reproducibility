
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) DESC) AS VoteRank,
        p.OwnerUserId
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
Feedback AS (
    SELECT 
        rp.PostId,
        COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges,
        COALESCE(ub.GoldCount, 0) AS GoldCount,
        COALESCE(ub.SilverCount, 0) AS SilverCount,
        COALESCE(ub.BronzeCount, 0) AS BronzeCount,
        rp.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetVotes,
        rp.VoteRank
    FROM 
        RankedPosts rp
        LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    f.PostId,
    f.UserBadges,
    f.CommentCount,
    f.NetVotes,
    f.VoteRank,
    CASE 
        WHEN f.NetVotes > 10 THEN 'Highly Engaged'
        WHEN f.NetVotes BETWEEN 1 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    Feedback f
WHERE 
    f.VoteRank <= 5
ORDER BY 
    f.VoteRank,
    f.NetVotes DESC
FETCH FIRST 50 ROWS ONLY;
