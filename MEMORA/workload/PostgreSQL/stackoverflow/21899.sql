WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND (p.Title LIKE '%SQL%' OR p.Body LIKE '%JOIN%') 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId
),

PostLinksWithTypes AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkTypeName,
        pl.CreationDate AS LinkCreationDate,
        ROW_NUMBER() OVER (PARTITION BY pl.PostId ORDER BY pl.CreationDate DESC) AS LinkRN
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
),

ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        p.Id
),

CombinedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        COALESCE(lp.LinkTypeName, 'No Links') AS LinkType,
        cp.LastClosedDate,
        CASE 
            WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        (rp.UpVotes - rp.DownVotes) AS ScoreDifference
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostLinksWithTypes lp ON rp.PostId = lp.PostId AND lp.LinkRN = 1
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    Title,
    CreationDate,
    CommentCount,
    LinkType,
    PostStatus,
    ScoreDifference,
    CASE 
        WHEN ScoreDifference > 0 THEN 'Positive'
        WHEN ScoreDifference < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreNature,
    CONCAT('This post is ', CASE WHEN PostStatus = 'Closed' THEN 'not useful' ELSE 'useful' END, ' for further discussions.') AS PostUtility
FROM 
    CombinedPosts
WHERE 
    (ScoreDifference > 0 OR CommentCount > 5)
    AND PostStatus = 'Open'
ORDER BY 
    CommentCount DESC, 
    CreationDate DESC
LIMIT 50;