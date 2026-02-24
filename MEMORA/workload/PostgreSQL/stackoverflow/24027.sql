
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                 WHEN v.VoteTypeId = 3 THEN -1 
                 ELSE 0 END) AS NetScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months'
),
RelatedPosts AS (
    SELECT 
        pl.PostId,
        COALESCE((SELECT STRING_AGG(p.Title, ', ')
                   FROM Posts p
                   JOIN PostLinks pl2 ON pl2.RelatedPostId = p.Id
                   WHERE pl2.PostId = pl.PostId), 'No Related Posts') AS RelatedPostTitles
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerName,
    r.CommentCount,
    r.NetScore,
    a.ReputationRank,
    a.DisplayName AS ActiveUserName,
    rp.RelatedPostTitles
FROM 
    RankedPosts r
JOIN 
    ActiveUsers a ON r.OwnerPostRank <= 3
LEFT JOIN 
    RelatedPosts rp ON r.PostId = rp.PostId
WHERE 
    r.CommentCount > 5 
    AND r.NetScore IS NOT NULL 
    AND a.UserId IS NOT NULL
ORDER BY 
    r.NetScore DESC, r.CommentCount DESC
LIMIT 20;
