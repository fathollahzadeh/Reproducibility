
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years' AND p.Score >= 0
),

PostWithMostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
    HAVING 
        COUNT(c.Id) >= 5
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL OR u.Reputation = 0 THEN 'No Reputation'
            WHEN u.Reputation < 100 THEN 'Novice'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Experienced'
        END AS ReputationLevel
    FROM 
        Users u
),

PostHistoryData AS (
    SELECT 
        ph.PostId, 
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        PHT.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate BETWEEN DATE '2023-01-01' AND CURRENT_DATE
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(pwc.CommentCount, 0) AS CommentCount,
        COALESCE(phd.Comment, '') AS LastEditComment,
        phd.CreationDate AS LastEditDate,
        ur.ReputationLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostWithMostComments pwc ON rp.PostId = pwc.PostId
    LEFT JOIN 
        PostHistoryData phd ON rp.PostId = phd.PostId 
        AND phd.CreationDate = (
            SELECT MAX(phd2.CreationDate) 
            FROM PostHistoryData phd2 
            WHERE phd2.PostId = rp.PostId
        )
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.LastEditComment,
    fp.LastEditDate,
    fp.ReputationLevel
FROM 
    FilteredPosts fp
WHERE 
    (fp.CommentCount > 0 AND fp.LastEditComment IS NOT NULL)
    OR (fp.ReputationLevel = 'Experienced' AND fp.CommentCount = 0)
ORDER BY 
    fp.ReputationLevel DESC, 
    fp.CreationDate ASC;
