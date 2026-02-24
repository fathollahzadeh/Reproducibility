
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostWithBadge AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Reputation,
        b.Name AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId AND b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    WHERE 
        rp.Rank = 1
),
PostScoreRanked AS (
    SELECT 
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Title
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.Score,
    pwb.Reputation,
    pwb.BadgeName,
    ps.CommentCount,
    ps.NetVotes,
    CASE 
        WHEN pwb.Reputation IS NULL THEN 'No Badge'
        ELSE pwb.BadgeName
    END AS BadgeDescription
FROM 
    PostWithBadge pwb
FULL OUTER JOIN 
    PostScoreRanked ps ON pwb.Title = ps.Title
WHERE 
    (pwb.Reputation > 100 OR ps.CommentCount > 5)
    AND (pwb.BadgeName IS NOT NULL OR ps.CommentCount IS NOT NULL)
ORDER BY 
    COALESCE(pwb.Score, 0) DESC, 
    COALESCE(ps.NetVotes, 0) DESC;
