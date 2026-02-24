
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AnswerCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
    AND rp.TotalBounty > (SELECT AVG(TotalBounty) FROM RankedPosts)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.AnswerCount,
    fp.TotalBounty,
    EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = fp.PostId AND c.UserId IS NOT NULL
    ) AS HasComments,
    (SELECT 
        STRING_AGG(b.Name, ', ') 
     FROM 
        Badges b 
     WHERE 
        b.UserId = (
            SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId
        )
    ) AS UserBadges
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    u.Reputation > 1000
ORDER BY 
    fp.TotalBounty DESC, fp.Score DESC;
