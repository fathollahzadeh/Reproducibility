WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserID,
        u.Reputation,
        COALESCE(b.Gold, 0) AS GoldBadges,
        COALESCE(b.Silver, 0) AS SilverBadges,
        COALESCE(b.Bronze, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS Gold,
            SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS Silver,
            SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS Bronze
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
        WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserID
WHERE 
    rp.VoteRank = 1
ORDER BY 
    rp.CommentCount DESC, 
    rp.UpVotes - rp.DownVotes DESC
LIMIT 10;