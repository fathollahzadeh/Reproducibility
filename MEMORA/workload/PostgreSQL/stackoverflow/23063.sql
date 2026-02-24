
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.PostTypeId, p.CreationDate
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId AS CreatorUserId, 
        us.Reputation,
        rp.CommentCount,
        rp.UpVotes - rp.DownVotes AS NetScore
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank = 1 
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Reputation,
    pa.CommentCount,
    pa.NetScore,
    CASE 
        WHEN pa.NetScore > 0 THEN 'Popular'
        WHEN pa.NetScore = 0 THEN 'Neutral'
        ELSE 'Unpopular' 
    END AS Popularity,
    CASE 
        WHEN (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pa.PostId AND v.VoteTypeId = 6) > 0 
        THEN 'Closed' 
        ELSE 'Open' 
    END AS Status
FROM 
    PostActivity pa
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(*) AS LinkCount 
        FROM 
            PostLinks 
        GROUP BY 
            PostId
    ) pl ON pa.PostId = pl.PostId
ORDER BY 
    pa.Reputation DESC, pa.NetScore DESC,
    COALESCE(pl.LinkCount, 0) DESC
LIMIT 100;
