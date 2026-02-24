
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND u.Reputation > 100 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        COALESCE(LENGTH(rp.Title), 0) AS TitleLength,
        CASE WHEN rp.CommentCount > 5 THEN 'Highly Discussed'
             WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Discussed'
             ELSE 'Not Discussed' END AS DiscussionLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND rp.PostRank <= 10
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.TitleLength,
    fp.DiscussionLevel,
    COALESCE(phc.HistoryCount, 0) AS PostHistoryCount,
    COALESCE(phc.HistoryTypes, 'None') AS PostHistoryTypes,
    (SELECT COUNT(DISTINCT v.Id) 
     FROM Votes v 
     WHERE v.PostId = fp.Id AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(DISTINCT v.Id) 
     FROM Votes v 
     WHERE v.PostId = fp.Id AND v.VoteTypeId = 3) AS DownVotes
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryCounts phc ON fp.Id = phc.PostId
WHERE 
    fp.CommentCount IS NOT NULL
    AND (fp.TitleLength > 50 OR fp.DiscussionLevel = 'Highly Discussed')
ORDER BY 
    fp.CreationDate DESC
LIMIT 50 OFFSET 10;
