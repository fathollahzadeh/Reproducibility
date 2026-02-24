
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 2) AS SilverBadges,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 3) AS BronzeBadges
    FROM
        Users u
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        (rp.UpVotes - rp.DownVotes) AS NetVotes,
        ur.Reputation,
        COALESCE(ur.GoldBadges, 0) AS GoldBadges,
        COALESCE(ur.SilverBadges, 0) AS SilverBadges,
        COALESCE(ur.BronzeBadges, 0) AS BronzeBadges,
        CASE 
            WHEN ur.Reputation > 1000 THEN 'Veteran User'
            WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Experienced User'
            ELSE 'New User'
        END AS UserCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
),
FinalResults AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.NetVotes DESC, pd.CreationDate DESC) AS VoteRank
    FROM 
        PostDetails pd
    WHERE 
        pd.CommentCount > 0
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    UpVotes,
    DownVotes,
    NetVotes,
    Reputation,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    UserCategory,
    VoteRank
FROM 
    FinalResults
WHERE 
    VoteRank <= 10 
ORDER BY 
    UserCategory, NetVotes DESC, CreationDate ASC;
