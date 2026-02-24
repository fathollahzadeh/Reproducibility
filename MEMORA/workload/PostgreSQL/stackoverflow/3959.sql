
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ur.Reputation,
        ur.UpVotes,
        ur.DownVotes,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS post_rank,
        rp.ViewCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.Reputation,
    pp.UpVotes,
    pp.DownVotes,
    CASE 
        WHEN pp.Score IS NULL OR pp.Score < 0 THEN 'Score is negative or NULL'
        WHEN pp.UpVotes > pp.DownVotes THEN 'More Upvotes than Downvotes'
        ELSE 'Mixed votes'
    END AS VoteSummary,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pp.Id) AS CommentCount
FROM 
    PopularPosts pp
WHERE 
    pp.post_rank <= 10
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
