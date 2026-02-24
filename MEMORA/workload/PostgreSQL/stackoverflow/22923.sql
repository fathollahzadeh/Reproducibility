
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score IS NOT NULL
        AND p.Title IS NOT NULL
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        CASE 
            WHEN rp.Rank <= 10 THEN 'Top 10'
            WHEN rp.Rank <= 50 THEN 'Top 50'
            ELSE 'Others'
        END AS RankCategory,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.CreationDate, rp.Rank
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation IS NOT NULL
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.RankCategory,
    tu.UserId,
    tu.Reputation,
    tu.BadgeCount
FROM 
    PostStats ps
FULL OUTER JOIN 
    TopUsers tu ON ps.UpVotes > 0 AND tu.UserRank <= 10
WHERE 
    ps.PostId IS NOT NULL 
    OR (tu.UserId IS NOT NULL AND tu.Reputation >= 100)
ORDER BY 
    ps.ViewCount DESC, 
    tu.Reputation DESC
LIMIT 100
OFFSET 20;
