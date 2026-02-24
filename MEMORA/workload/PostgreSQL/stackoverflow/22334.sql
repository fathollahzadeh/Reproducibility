
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT AVG(v.BountyAmount) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId IN (8, 9)) AS AverageBounty,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.Score > 0 AND
        (p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' OR 
         p.AcceptedAnswerId IS NOT NULL)
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.AverageBounty,
        COALESCE(bg_class.BadgeClass, 0) AS BadgeClass,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            b.UserId,
            MAX(b.Class) AS BadgeClass
        FROM 
            Badges b
        GROUP BY 
            b.UserId
    ) bg_class ON bg_class.UserId = rp.OwnerUserId
),
CombinedData AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pd.AverageBounty,
        pd.BadgeClass,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        PostDetails pd
    LEFT JOIN PostLinks pl ON pl.PostId = pd.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.CreationDate, pd.CommentCount, pd.AverageBounty, pd.BadgeClass
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.CommentCount,
    cd.AverageBounty,
    cd.BadgeClass,
    cd.RelatedPostsCount,
    CASE 
        WHEN cd.CommentCount = 0 THEN 'No Comments'
        WHEN cd.CommentCount BETWEEN 1 AND 5 THEN 'Few Comments'
        WHEN cd.CommentCount BETWEEN 6 AND 20 THEN 'Moderate Comments'
        ELSE 'Many Comments' 
    END AS CommentCategory,
    CASE 
        WHEN cd.AverageBounty IS NULL THEN 'No Bounty'
        WHEN cd.AverageBounty < 50 THEN 'Low Bounty'
        WHEN cd.AverageBounty BETWEEN 51 AND 150 THEN 'Medium Bounty'
        ELSE 'High Bounty'
    END AS BountyCategory
FROM 
    CombinedData cd
WHERE 
    cd.BadgeClass IN (1, 2)
ORDER BY 
    cd.CommentCount DESC,
    cd.Title;
