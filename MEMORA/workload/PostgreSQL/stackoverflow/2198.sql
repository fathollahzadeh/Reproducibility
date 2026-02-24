
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostAggregate AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment
    FROM 
        RankedPosts rp
        JOIN UserStatistics us ON rp.PostRank = 1 AND rp.OwnerName = us.DisplayName
)
SELECT 
    pa.Title,
    pa.OwnerName,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges,
    pa.PostSentiment
FROM 
    PostAggregate pa
WHERE 
    (pa.CommentCount > 5 AND pa.UpVoteCount > 10) 
    OR (pa.DownVoteCount < 3 AND pa.GoldBadges > 0)
ORDER BY 
    pa.PostSentiment DESC, pa.UpVoteCount DESC;
