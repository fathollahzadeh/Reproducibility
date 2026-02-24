
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        NTILE(3) OVER (ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        FIRST_VALUE(p.Body) OVER (PARTITION BY p.Id ORDER BY p.CreationDate) AS FirstBody
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), 
RecentActivity AS (
    SELECT 
        p.Id,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostLinkDetails AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS TotalLinks,
        STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypeNames
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.ScoreRank,
    ra.HistoryCount,
    ra.VoteCount,
    ra.LastActivityDate,
    pl.TotalLinks,
    pl.LinkTypeNames,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN rp.FirstBody LIKE '%error%' THEN 'Contains Error'
        ELSE 'No Error'
    END AS BodyErrorCheck
FROM 
    RankedPosts rp
JOIN 
    RecentActivity ra ON rp.PostID = ra.Id
LEFT JOIN 
    PostLinkDetails pl ON rp.PostID = pl.PostId
WHERE 
    (rp.ScoreRank = 1 OR ra.VoteCount > 5)
    AND (ra.LastActivityDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' OR rp.ViewCount > 100)
ORDER BY 
    rp.Score DESC, pl.TotalLinks DESC
LIMIT 50;
