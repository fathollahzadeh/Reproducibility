
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges,
        rp.PostRank,
        rp.Title,
        rp.Score,
        rp.CommentCount
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 1000
),
FinalResults AS (
    SELECT 
        tu.DisplayName,
        tu.Reputation,
        tu.BadgeCount,
        tu.GoldBadges,
        COALESCE(tu.Title, 'No Posts') AS Title,
        COALESCE(tu.Score, 0) AS Score,
        COALESCE(tu.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY tu.Reputation DESC) AS UserRank
    FROM 
        TopUsers tu
)
SELECT 
    FR.DisplayName,
    FR.Reputation,
    FR.BadgeCount,
    FR.GoldBadges,
    FR.Title,
    FR.Score,
    FR.CommentCount,
    FR.UserRank,
    CASE 
        WHEN FR.Score > 0 THEN 'Active Contributor'
        ELSE 'Lurker'
    END AS ContributorStatus
FROM 
    FinalResults FR
WHERE 
    FR.UserRank <= 10
ORDER BY 
    FR.Reputation DESC;
