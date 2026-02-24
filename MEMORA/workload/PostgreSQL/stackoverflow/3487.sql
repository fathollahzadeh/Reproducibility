
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(DISTINCT p2.Id) 
         FROM Posts p2 
         WHERE p2.ParentId = p.Id) AS RelatedAnswers
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Badges b
    GROUP BY b.UserId
),
HighScorePosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        u.Reputation,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        PostStats ps
    JOIN Users u ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE 
        ps.UpVotes - ps.DownVotes > 5
        AND ps.CommentCount > 2
)
SELECT 
    PostId,
    Title,
    CommentCount,
    UpVotes,
    DownVotes,
    Reputation,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    HighScorePosts
ORDER BY 
    UpVotes DESC,
    Reputation DESC
LIMIT 10;
